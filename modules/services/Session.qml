pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Lock is the shell's own lock screen: run("lock") only asks (lockRequested), and Lock.qml locks.
Singleton {
    id: root

    readonly property var actions: [
        { id: "lock",     label: "Lock",      icon: "lock",               confirm: false, key: "l" },
        { id: "suspend",  label: "Suspend",   icon: "bedtime",            confirm: false, key: "s" },
        { id: "hibernate", label: "Hibernate", icon: "ac_unit",           confirm: false, key: "h" },
        { id: "logout",   label: "Log out",   icon: "logout",             confirm: true,  key: "o" },
        { id: "reboot",   label: "Restart",   icon: "restart_alt",        confirm: true,  key: "r" },
        { id: "poweroff", label: "Shut down", icon: "power_settings_new", confirm: true,  key: "p" }
    ]

    signal lockRequested()
    // The island over the whole screen: as the lock comes (Lock.qml sets it, Bar grows the island) and
    // under it while locked, so unlocking shows the island giving the screen back.
    property bool covering: false

    // logout: Hyprland runs under UWSM (programs.hyprland.withUWSM), so stop that; otherwise end
    // the logind session.
    readonly property var commands: ({
        suspend:  ["systemctl", "suspend"],
        hibernate: ["systemctl", "hibernate"],
        logout:   ["uwsm", "stop"],
        reboot:   ["systemctl", "reboot"],
        poweroff: ["systemctl", "poweroff"],
        windows:  ["systemctl", "reboot", "--boot-loader-entry=auto-windows"],
        firmware: ["systemctl", "reboot", "--firmware-setup"]
    })

    // Restarts into something else, for one boot: what logind's BootLoaderEntries has of these
    // (systemd-boot names Windows auto-windows), read once. Each asks first, as a restart does.
    readonly property var targets: [
        { id: "windows",  label: "Windows",        icon: "desktop_windows", key: "w", entry: "auto-windows" },
        { id: "firmware", label: "Firmware setup", icon: "developer_board", key: "f", entry: "auto-reboot-to-firmware-setup" }
    ]
    property var restarts: []
    Process {
        running: true
        command: ["busctl", "--json=short", "get-property", "org.freedesktop.login1", "/org/freedesktop/login1",
                  "org.freedesktop.login1.Manager", "BootLoaderEntries"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const entries = JSON.parse(text).data
                    root.restarts = root.targets.filter(t => entries.includes(t.entry)).map(t => Object.assign({ confirm: true }, t))
                } catch (e) {}
            }
        }
    }

    function run(id) {
        if (id === "lock") { lockRequested(); return }
        const c = commands[id]
        if (c) Quickshell.execDetached(c)
    }

    property int uptime: -1              // seconds
    function refresh() { uptimeFile.reload() }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        printErrors: false
        onLoaded: root.uptime = Math.floor(parseFloat(text()))
    }

    readonly property string uptimeText: {
        if (uptime < 0) return ""
        const d = Math.floor(uptime / 86400), h = Math.floor(uptime % 86400 / 3600), m = Math.floor(uptime % 3600 / 60)
        return "up " + (d > 0 ? d + " d " : "") + (d > 0 || h > 0 ? h + " h " : "") + m + " min"
    }
}
