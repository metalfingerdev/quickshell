pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// sysfs has no change events, so this polls each device's `uevent` file (every value in one read).
// No UPower needed. Each threshold warns once per discharge (check()).
Singleton {
    id: root

    property int lowAt: 15
    property int criticalAt: 5
    property int pollMs: 2000

    property string battery: ""
    property string charger: ""
    readonly property bool present: battery !== ""

    property int percent: -1             // -1 = not read yet
    property string status: ""
    property bool plugged: false
    property real watts: 0               // power draw (or charge rate); 0 = the battery doesn't say
    property real energyWh: 0
    property real fullWh: 0
    property real designWh: 0
    property int cycles: -1

    readonly property bool charging: status === "Charging"
    readonly property bool full: status === "Full" || (plugged && percent >= 100)
    readonly property bool discharging: status === "Discharging" || (!plugged && !charging && present)
    readonly property int health: designWh > 0 ? Math.round(fullWh * 100 / designWh) : -1

    readonly property int minutesLeft: {
        if (watts <= 0) return -1
        if (charging) return Math.round((fullWh - energyWh) / watts * 60)
        if (discharging) return Math.round(energyWh / watts * 60)
        return -1
    }

    readonly property string level: percent <= criticalAt ? "critical" : percent <= lowAt ? "low" : "ok"
    // a Config role, by name: services stay free of the theme. "" = the viewer's own colour
    readonly property string tone: charging || full ? "good" : level === "critical" ? "bad" : level === "low" ? "warn" : ""

    readonly property string glyph: {
        if (!present) return "power"
        if (charging) return "battery_charging_full"
        if (full || percent >= 95) return "battery_full"
        if (level === "critical") return "battery_alert"
        return "battery_" + Math.max(0, Math.min(6, Math.floor(percent / 15))) + "_bar"
    }

    // The charge limit: where the firmware stops charging, `charge_control_end_threshold` (ThinkPads, ASUS,
    // Frameworks and others have it; no file, no toggle). Only root may write it, so it goes through pkexec
    // as Generations' cleanup does. Many firmwares forget it at a reboot, and the island doesn't set it at start.
    property int limit: 100
    property int limitTo: 80                       // what the toggle sets
    property bool limitAvailable: false
    property bool limitBusy: false
    readonly property bool limited: limitAvailable && limit < 100
    readonly property string limitFile: battery === "" ? "" : battery + "/charge_control_end_threshold"

    function setLimit(percent) {
        if (!limitAvailable || limitBusy) return
        limitBusy = true
        // an absolute sh: pkexec gives the command a bare PATH
        limiter.command = ["pkexec", "/run/current-system/sw/bin/sh", "-c", "echo " + Math.max(20, Math.min(100, Math.round(percent))) + " > " + limitFile]
        limiter.running = true
    }
    function toggleLimit() { setLimit(limited ? 100 : limitTo) }
    Process {
        id: limiter
        onExited: { root.limitBusy = false; limitRead.reload() }
    }
    FileView {
        id: limitRead
        path: root.limitFile
        printErrors: false
        onLoaded: { const n = parseInt(text()); root.limitAvailable = !isNaN(n); if (!isNaN(n)) root.limit = n }
        onLoadFailed: root.limitAvailable = false
    }

    signal warn(bool critical)

    function duration(minutes) {
        if (minutes < 0) return ""
        const h = Math.floor(minutes / 60), m = minutes % 60
        return h > 0 ? h + " h " + String(m).padStart(2, "0") + " min" : m + " min"
    }

    Process {
        running: true
        command: ["sh", "-c",
            "for d in /sys/class/power_supply/*; do t=$(cat \"$d/type\" 2>/dev/null); "
          + "case \"$t\" in Battery) [ \"$(cat \"$d/scope\" 2>/dev/null)\" = Device ] || echo \"bat $d\";; "
          + "Mains) echo \"ac $d\";; esac; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const [kind, path] = line.split(" ")
                    if (kind === "bat" && root.battery === "") root.battery = path
                    if (kind === "ac" && root.charger === "")  root.charger = path
                }
            }
        }
    }

    function parse(text) {
        const out = {}
        for (const line of text.split("\n")) {
            const i = line.indexOf("=")
            if (i > 0) out[line.slice(0, i).replace("POWER_SUPPLY_", "")] = line.slice(i + 1)
        }
        return out
    }
    // energy in µWh, or charge in µAh (some batteries only report that) times the voltage
    function wh(u, key) {
        if (u["ENERGY_" + key] !== undefined) return u["ENERGY_" + key] / 1e6
        if (u["CHARGE_" + key] !== undefined && u.VOLTAGE_NOW !== undefined)
            return u["CHARGE_" + key] / 1e6 * u.VOLTAGE_NOW / 1e6
        return 0
    }

    // 0 above the warnings, 1 low, 2 critical. Each band warns once per discharge, also when the
    // session starts already in it; charging only takes back the bands it climbs out of, so
    // plugging in for a minute and out again at the same level doesn't warn twice.
    readonly property int band: percent < 0 ? 0 : percent <= criticalAt ? 2 : percent <= lowAt ? 1 : 0
    property int warned: 0
    // the first reads come in any order: until both files have been read, `plugged` may still be false
    property bool settled: false
    Timer { interval: 3000; running: root.present; onTriggered: { root.settled = true; root.check() } }

    function check() {
        if (!settled) return
        if (!discharging) { warned = Math.min(warned, band); return }
        if (band > warned) { warned = band; warn(band === 2) }
    }

    function update(u) {
        status = u.STATUS ?? ""
        energyWh = wh(u, "NOW")
        fullWh = wh(u, "FULL")
        designWh = wh(u, "FULL_DESIGN")
        cycles = u.CYCLE_COUNT !== undefined ? parseInt(u.CYCLE_COUNT) : -1
        if (u.POWER_NOW !== undefined) watts = Math.abs(u.POWER_NOW) / 1e6
        else if (u.CURRENT_NOW !== undefined && u.VOLTAGE_NOW !== undefined)
            watts = Math.abs(u.CURRENT_NOW) / 1e6 * u.VOLTAGE_NOW / 1e6
        else watts = 0
        if (charger === "") plugged = status === "Charging" || status === "Full"

        percent = u.CAPACITY !== undefined ? parseInt(u.CAPACITY)
                : fullWh > 0 ? Math.round(energyWh * 100 / fullWh) : -1
        check()
    }

    FileView {
        id: batFile
        path: root.battery === "" ? "" : root.battery + "/uevent"
        printErrors: false
        onLoaded: root.update(root.parse(text()))
    }

    FileView {
        id: acFile
        path: root.charger === "" ? "" : root.charger + "/online"
        printErrors: false
        onLoaded: root.plugged = text().trim() === "1"
    }

    Timer {
        interval: root.pollMs
        repeat: true
        running: root.present
        triggeredOnStart: true
        onTriggered: { acFile.reload(); batFile.reload() }
    }
}
