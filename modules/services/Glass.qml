pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.components
import "HyprLua.js" as HyprLua
import "GlassSchema.js" as GlassSchema

// What the windows and the island are made of: Hyprland's blur, shadow and the windows' opacity, and liquid
// glass, the hyprglass plugin (hypr/modules/plugins.lua loads it when nixos-dotfiles built it for this
// Hyprland). Settings sets them at runtime (hyprctl eval), and Prefs keeps them in settings.json. A config
// reload puts look.lua's and plugins.lua's values back, so they go back in after one, and at start.
//
// `hg` and `hl` are the free-form part: { shared: {key: value}, dark: {...}, light: {...} }, hyprglass's
// settings and any Hyprland option (the mode's table wins). ISLAND_DRY=1 sends nothing (test instances).
Singleton {
    id: root

    property bool enabled: true
    property string preset: "pomme"
    property string blur: "medium"
    property real windows: -1            // the windows' opacity; -1 = look.lua's
    property var hg: ({ shared: {}, dark: {}, light: {} })
    property var hl: ({ shared: {}, dark: {}, light: {} })

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
    // Hyprland's options as it lists them: [{ name, description, default, current, min, max, map }]
    property var descriptions: []
    readonly property var defaults: { const d = {}; descriptions.forEach(o => { d[o.name] = o.default }); return d }
    readonly property bool dry: Quickshell.env("ISLAND_DRY") === "1"

    function lua() {
        const dark = Config.dark
        const level = levels[blur] ?? levels.medium
        const decoration = [`blur = { enabled = ${blur !== "off"}, size = ${level[0]}, passes = ${level[1]} }`]
        if (windows >= 0) decoration.push(`active_opacity = ${windows}, inactive_opacity = ${windows}`)
        const out = [`hl.config({ decoration = { ${decoration.join(", ")} } })`]
        if (descriptions.length > 0) { const extra = HyprLua.hyprland(hl, dark, defaults); if (extra !== "") out.push(extra) }
        if (available) {
            const look = presets.some(p => p.key === preset) || ["default", "high_contrast"].includes(preset) ? preset : "pomme"
            const own = HyprLua.glass(hg, dark, GlassSchema.known)
            if (blur !== "medium") { own.blur_strength = own.blur_strength ?? level[2]; own.blur_iterations = own.blur_iterations ?? level[3] }
            const fields = Object.keys(own).map(k => `${k} = ${own[k]}`)
            let use = look
            if (fields.length > 0) {
                out.push(`hl.plugin.hyprglass.preset("island", { inherits = "${look}", ${fields.join(", ")} })`)
                use = "island"
            }
            out.push(`hl.plugin.hyprglass.config({ enabled = ${enabled}, default_preset = "${use}", default_theme = "${dark ? "dark" : "light"}" })`)
        }
        return out.join("; ")
    }
    // An eval may count as a reload: the one that follows our own is ours, and isn't answered again.
    property double applied: 0
    function apply() {
        if (dry) return
        applied = Date.now()
        setter.command = ["hyprctl", "eval", lua()]
        setter.running = true
    }
    function readDescriptions() { if (!dry && descriptions.length === 0) describe.running = true }

    onEnabledChanged: apply()
    onPresetChanged: apply()
    onBlurChanged: apply()
    onWindowsChanged: apply()
    onHgChanged: apply()
    onHlChanged: { if (Object.keys(hl.shared).length + Object.keys(hl.dark).length + Object.keys(hl.light).length > 0) readDescriptions(); apply() }
    onDescriptionsChanged: apply()
    Connections { target: Config; function onDarkChanged() { if (root.available) root.apply() } }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event?.name === "configreloaded" && Date.now() - root.applied > 1500) probe.running = true
        }
    }
    Component.onCompleted: if (!dry) probe.running = true

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
    Process {
        id: describe
        command: ["hyprctl", "descriptions", "-j"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.descriptions = JSON.parse(text) } catch (e) {} }
        }
    }
    // the island takes the windows' opacity, so it's read again once Hyprland has the new one
    Process { id: setter; onExited: Desktops.readOpacity() }
}
