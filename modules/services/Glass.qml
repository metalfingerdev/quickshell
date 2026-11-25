pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.components

// What the windows and the island are made of: Hyprland's blur and the windows' opacity, and liquid
// glass, the hyprglass plugin, which hypr/modules/plugins.lua loads when nixos-dotfiles built it for this
// Hyprland. Settings sets them at runtime (hyprctl eval). A config reload puts look.lua's and
// plugins.lua's values back, so the choices go back in after one, and at start.
Singleton {
    id: root

    property bool enabled: true
    property string preset: "pomme"
    property string blur: "medium"
    property real windows: -1            // the windows' opacity, 0.5 .. 1; -1 = look.lua's
    property Store store: Store {
        category: "glass"
        property alias enabled: root.enabled
        property alias preset: root.preset
        property alias blur: root.blur
        property alias windows: root.windows
    }

    // the plugin's built-in looks; pomme is its Apple one
    readonly property var presets: [{ key: "pomme", label: "Liquid" }, { key: "glass", label: "Glass" },
                                    { key: "subtle", label: "Subtle" }, { key: "clear", label: "Clear" }]
    readonly property var blurs: [{ key: "off", label: "Off" }, { key: "light", label: "Light" },
                                  { key: "medium", label: "Medium" }, { key: "strong", label: "Strong" }]
    // Each level: Hyprland's blur size and passes (medium is look.lua's own), and the glass's strength and
    // passes. A preset sets its own blur, which beats the plugin's global one, so a level other than
    // medium goes in through a preset of ours that inherits the look; medium leaves the look's own.
    readonly property var levels: ({ off: [0, 1, 0, 1], light: [4, 2, 1, 2], medium: [8, 3, 0, 0], strong: [14, 4, 3.5, 4] })
    // Only a loaded plugin has its options: Hyprland answers anything else with "no such option", not JSON.
    property bool available: false

    function lua() {
        const level = levels[blur] ?? levels.medium
        const decoration = [`blur = { enabled = ${blur !== "off"}, size = ${level[0]}, passes = ${level[1]} }`]
        if (windows > 0) decoration.push(`active_opacity = ${windows}, inactive_opacity = ${windows}`)
        const out = [`hl.config({ decoration = { ${decoration.join(", ")} } })`]
        if (available) {
            const look = presets.some(p => p.key === preset) ? preset : "pomme"
            let use = look
            if (blur !== "medium") {
                out.push(`hl.plugin.hyprglass.preset("island", { inherits = "${look}", blur_strength = ${level[2]}, blur_iterations = ${level[3]} })`)
                use = "island"
            }
            out.push(`hl.plugin.hyprglass.config({ enabled = ${enabled}, default_preset = "${use}", default_theme = "${Config.dark ? "dark" : "light"}" })`)
        }
        return out.join("; ")
    }
    // An eval may count as a reload: the one that follows our own is ours, and isn't answered again.
    property double applied: 0
    function apply() {
        applied = Date.now()
        setter.command = ["hyprctl", "eval", lua()]
        setter.running = true
    }

    onEnabledChanged: apply()
    onPresetChanged: apply()
    onBlurChanged: apply()
    onWindowsChanged: apply()
    Connections { target: Config; function onDarkChanged() { if (root.available) root.apply() } }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event?.name === "configreloaded" && Date.now() - root.applied > 1500) probe.running = true
        }
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
    // the island takes the windows' opacity, so it's read again once Hyprland has the new one
    Process { id: setter; onExited: Desktops.readOpacity() }
}
