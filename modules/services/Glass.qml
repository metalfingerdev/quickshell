pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.components

// Liquid glass: the hyprglass plugin, which hypr/modules/plugins.lua loads when nixos-dotfiles built it
// for this Hyprland. Settings switches it and picks its look. A config reload puts plugins.lua's
// defaults back, so the choice goes back in after one, and at start; its theme follows the palette.
Singleton {
    id: root

    property bool enabled: true
    property string preset: "pomme"
    property Store store: Store {
        category: "glass"
        property alias enabled: root.enabled
        property alias preset: root.preset
    }

    // the plugin's built-in looks; pomme is its Apple one
    readonly property var presets: [{ key: "pomme", label: "Liquid" }, { key: "glass", label: "Glass" },
                                    { key: "subtle", label: "Subtle" }, { key: "clear", label: "Clear" }]
    // Only a loaded plugin has its options: Hyprland answers anything else with "no such option", not JSON.
    property bool available: false

    function apply() {
        if (!available) return
        const look = presets.some(p => p.key === preset) ? preset : "pomme"
        setter.command = ["hyprctl", "eval", `hl.plugin.hyprglass.config({ enabled = ${enabled}, default_preset = "${look}", default_theme = "${Config.dark ? "dark" : "light"}" })`]
        setter.running = true
    }

    onEnabledChanged: apply()
    onPresetChanged: apply()
    Connections { target: Config; function onDarkChanged() { root.apply() } }
    Connections {
        target: Hyprland
        function onRawEvent(event) { if (event?.name === "configreloaded") probe.running = true }
    }
    Component.onCompleted: probe.running = true

    Process {
        id: probe
        command: ["hyprctl", "getoption", "plugin:hyprglass:enabled", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.available = typeof JSON.parse(text) === "object" } catch (e) { root.available = false }
                root.apply()
            }
        }
    }
    Process { id: setter }
}
