pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The processor, memory, temperature and the network's rates, for the island's Expanded view. From
// Nihil-Shell's SysStats (MIT: nixos-dotfiles, modules/features/nilo-agent/LICENSE), now ours.
// Read once a second only while a view watches it (watch(true) and watch(false), as Players does):
// unwatched, nothing is read, and the rates start over rather than spread what came in meanwhile.
Singleton {
    id: root

    property int watchers: 0
    function watch(on) { watchers = Math.max(0, watchers + (on ? 1 : -1)) }
    readonly property bool shown: watchers > 0

    property real cpu: 0            // 0..1
    property real mem: 0            // 0..1
    property real memGB: 0          // in use
    property real temp: 0           // °C; 0: no sensor found
    property string iface: ""
    property real rx: 0             // bytes/s
    property real tx: 0

    property var lastCpu: null
    property real lastRx: -1
    property real lastTx: -1
    property string tempPath: ""
    property string tempSkip: ""
    property int tempMisses: 0

    // 1.2 MB/s, 40 kB/s: powers of 1000
    function rate(bytes) {
        const units = ["B", "kB", "MB", "GB"]
        let i = 0
        while (bytes >= 1000 && i < units.length - 1) { bytes /= 1000; i++ }
        return (i === 0 || bytes >= 10 ? Math.round(bytes) : bytes.toFixed(1)) + " " + units[i] + "/s"
    }

    FileView { id: stat; path: "/proc/stat"; blockLoading: true }
    FileView { id: meminfo; path: "/proc/meminfo"; blockLoading: true }
    FileView { id: tempFile; path: root.tempPath; blockLoading: true }
    FileView { id: rxFile; path: root.iface ? `/sys/class/net/${root.iface}/statistics/rx_bytes` : ""; blockLoading: true }
    FileView { id: txFile; path: root.iface ? `/sys/class/net/${root.iface}/statistics/tx_bytes` : ""; blockLoading: true }

    // the way out: the default route's device
    Process {
        id: route
        command: ["ip", "route", "show", "default"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/dev (\S+)/)
                const iface = m ? m[1] : ""
                if (iface !== root.iface) { root.lastRx = -1; root.lastTx = -1 }
                root.iface = iface
            }
        }
    }

    // The processor's own sensor first (AMD, Intel, ARM, ThinkPads), then any that reads sanely;
    // one that stops answering is skipped and another looked for.
    Process {
        id: findTemp
        command: ["sh", "-c",
            "skip=$1; sane() { [ \"$1\" != \"$skip\" ] && v=$(cat \"$1\" 2>/dev/null) && [ \"${v:-0}\" -gt 0 ] 2>/dev/null && [ \"$v\" -lt 150000 ]; }; " +
            "for want in k10temp zenpower coretemp cpu_thermal thinkpad acpitz; do " +
            "for d in /sys/class/hwmon/hwmon*; do [ \"$(cat \"$d/name\" 2>/dev/null)\" = \"$want\" ] || continue; " +
            "for f in \"$d\"/temp*_input; do sane \"$f\" && { echo \"$f\"; exit; }; done; done; done; " +
            "for f in /sys/class/thermal/thermal_zone*/temp /sys/class/hwmon/hwmon*/temp*_input; do sane \"$f\" && { echo \"$f\"; exit; }; done",
            "sh", root.tempSkip]
        stdout: StdioCollector { onStreamFinished: root.tempPath = text.trim() }
    }

    onShownChanged: {
        if (shown) {
            if (!tempPath && !findTemp.running) findTemp.running = true
            return
        }
        lastCpu = null
        lastRx = -1
        lastTx = -1
        rx = 0
        tx = 0
    }

    // the way out can change with the network: read again then, rather than every few seconds
    Connections {
        target: Net
        enabled: root.shown
        function onCurrentChanged() { route.running = true }
        function onEthernetChanged() { route.running = true }
    }

    function tick() {
        if (iface) {
            rxFile.reload()
            txFile.reload()
            const r = parseFloat(rxFile.text()), t = parseFloat(txFile.text())
            if (!isNaN(r) && !isNaN(t)) {
                if (lastRx >= 0) {
                    rx = Math.max(0, r - lastRx)
                    tx = Math.max(0, t - lastTx)
                }
                lastRx = r
                lastTx = t
            }
        } else {
            rx = 0
            tx = 0
        }

        stat.reload()
        const cpuLine = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
        const idle = cpuLine[3] + (cpuLine[4] || 0)
        const total = cpuLine.reduce((a, b) => a + b, 0)
        if (lastCpu && total > lastCpu.total) cpu = 1 - (idle - lastCpu.idle) / (total - lastCpu.total)
        lastCpu = { idle: idle, total: total }

        meminfo.reload()
        const m = {}
        for (const line of meminfo.text().split("\n")) {
            const f = line.match(/^(\w+):\s+(\d+)/)
            if (f) m[f[1]] = parseInt(f[2])
        }
        if (m.MemTotal) {
            const used = m.MemTotal - (m.MemAvailable ?? m.MemFree)
            mem = used / m.MemTotal
            memGB = used / 1048576
        }

        if (tempPath) {
            tempFile.reload()
            const v = parseInt(tempFile.text())
            if (!isNaN(v) && v > 0 && v < 150000) {
                temp = v / 1000
                tempMisses = 0
            } else if (++tempMisses >= 5) {
                tempSkip = tempPath
                tempMisses = 0
                tempPath = ""
                findTemp.running = true
            }
        }
    }

    Timer {
        interval: 1000
        running: root.shown
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }
    Timer {
        interval: 30000
        running: root.shown
        repeat: true
        triggeredOnStart: true
        onTriggered: route.running = true
    }
}
