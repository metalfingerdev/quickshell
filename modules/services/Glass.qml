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
// Hyprland). Prefs keeps them in settings.json. hyprglass only takes preset() and layer() while the config
// loads (at runtime they are queued and dropped), so everything is also written to ~/.config/island/
// hyprland.lua, which hypr's hyprland.lua runs last, and a change to those lines reloads Hyprland. The
// rest goes in at once with hyprctl eval.
//
// `hg` and `hl` are the free-form part: { shared: {key: value}, dark: {...}, light: {...} }, hyprglass's
// settings and any Hyprland option (the mode's table wins). ISLAND_DRY=1 sends nothing (test instances).
Singleton {
    id: root

    property bool enabled: true
    property string preset: "pomme"
    // The island and the windows apart. Blur is an amount, 0..1, for whichever blur is drawing (-1: as it
    // is: look.lua's, or the liquid-glass look's own); the island's, -1, follows the windows'. Hyprland's own
    // blur is one for everything, so the island's amount only counts under liquid glass.
    property real windowBlur: 0
    property real islandBlur: 1
    property real activeOpacity: 0.9     // -1 = look.lua's
    property real inactiveOpacity: 0.9
    // hyprglass's settings, for the windows and for the island: each { shared, dark, light }
    property var hg: ({ windows: { shared: {}, dark: {}, light: {} }, island: { shared: {}, dark: {}, light: {} } })
    // an older settings.json had one { shared, dark, light } for everything: that was the windows'
    function tables(which) { return hg?.[which] ?? (which === "windows" && hg?.shared ? hg : {}) }
    property var hl: ({ shared: {}, dark: {}, light: {} })

    readonly property var presets: [{ key: "pomme", label: "Liquid" }, { key: "glass", label: "Glass" },
                                    { key: "subtle", label: "Subtle" }, { key: "clear", label: "Clear" }]
    // what a setting shows before it is set: the look's own value, else the plugin's
    function glassValue(which, key) {
        const own = tables(which), mode = Config.dark ? "dark" : "light"
        const set = own[mode]?.[key] ?? own.shared?.[key]
        if (set !== undefined) return set
        if (which === "island") return glassValue("windows", key)
        const look = GlassSchema.looks[preset] ?? {}
        return look[mode]?.[key] ?? look.shared?.[key] ?? GlassSchema.entries.find(e => e.key === key)?.def
    }
    function setGlass(which, key, value) {
        const all = { windows: Object.assign({}, tables("windows")), island: Object.assign({}, tables("island")) }
        const shared = Object.assign({}, all[which].shared ?? {})
        if (value === undefined) delete shared[key]; else shared[key] = value
        all[which].shared = shared
        hg = all
    }
    function resetGlass(which, keys) {
        const all = { windows: Object.assign({}, tables("windows")), island: Object.assign({}, tables("island")) }
        for (const mode of ["shared", "dark", "light"]) {
            const t = Object.assign({}, all[which][mode] ?? {})
            keys.forEach(k => delete t[k])
            all[which][mode] = t
        }
        hg = all
    }
    // Only a loaded plugin has its options: Hyprland answers anything else with "no such option", not JSON.
    property bool available: false
    // Hyprland's options as it lists them: [{ name, description, default, current, min, max, map }]
    property var descriptions: []
    readonly property var defaults: { const d = {}; descriptions.forEach(o => { d[o.name] = o.default }); return d }
    readonly property bool dry: Quickshell.env("ISLAND_DRY") === "1"

    function lua() {
        const dark = Config.dark
        const decoration = []
        if (windowBlur >= 0) {
            const b = HyprLua.blurHyprland(windowBlur)
            decoration.push(`blur = { enabled = ${b.enabled}, size = ${b.size}, passes = ${b.passes} }`)
        }
        if (activeOpacity >= 0) decoration.push(`active_opacity = ${Number(activeOpacity)}`)
        if (inactiveOpacity >= 0) decoration.push(`inactive_opacity = ${Number(inactiveOpacity)}`)
        const out = decoration.length ? [`hl.config({ decoration = { ${decoration.join(", ")} } })`] : []
        if (descriptions.length > 0) { const extra = HyprLua.hyprland(hl, dark, defaults); if (extra !== "") out.push(extra) }
        if (available) {
            const look = GlassSchema.looks[preset] ? preset : "pomme"
            HyprLua.shellGlass({ look: look, enabled: enabled, dark: dark, known: GlassSchema.known,
                                 windows: tables("windows"), island: tables("island"),
                                 windowBlur: windowBlur, islandBlur: islandBlur }).forEach(l => out.push(l))
        }
        return out
    }
    // An eval may count as a reload: the one that follows our own is ours, and isn't answered again.
    property double applied: 0
    readonly property var loadOnly: /^hl\.plugin\.hyprglass\.(preset|layer)\(/
    function glassLines(text) { return text.split("\n").map(l => l.trim()).filter(l => loadOnly.test(l)).join("\n") }
    // a drag sends one change at its end, not a reload per step
    // and nothing before the probe has said whether the plugin is in, or the file loses its glass a moment
    property bool probed: false
    function apply() { if (!dry && probed) settle.restart() }
    Timer { id: settle; interval: 300; onTriggered: root.send() }
    function send() {
        const lines = lua(), now = lines.filter(l => !loadOnly.test(l))
        const glass = lines.filter(l => l.startsWith("hl.plugin.hyprglass"))
        const text = "-- Written by the island's Settings (Glass.qml); edit it there, or delete this file.\n"
            + lines.filter(l => !l.startsWith("hl.plugin.hyprglass")).join("\n")
            + (glass.length ? "\nif hl.plugin.hyprglass then\n    " + glass.join("\n    ") + "\nend" : "") + "\n"
        const old = store.text()
        if (text !== old) store.setText(text)
        applied = Date.now()
        if (glassLines(text) !== glassLines(old)) { setter.command = ["hyprctl", "reload"]; setter.running = true }
        else if (now.length) { setter.command = ["hyprctl", "eval", now.join("; ")]; setter.running = true }
    }
    function readDescriptions() { if (!dry && descriptions.length === 0) describe.running = true }

    onEnabledChanged: apply()
    onPresetChanged: apply()
    onWindowBlurChanged: apply()
    onIslandBlurChanged: apply()
    onActiveOpacityChanged: apply()
    onInactiveOpacityChanged: apply()
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
                root.probed = true
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
    FileView { id: store; path: root.dry ? "" : Quickshell.env("HOME") + "/.config/island/hyprland.lua"; blockLoading: true }
    // the island takes the windows' opacity, so it's read again once Hyprland has the new one
    Process { id: setter; onExited: Desktops.readOpacity() }
}
