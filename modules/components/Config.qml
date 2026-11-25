pragma Singleton

import QtQuick

// Nothing else hard-codes a colour.
// No view file may share a singleton's name (Config.qml, Wallpaper.qml, ...): views see their own folder
// first, and it would hide that singleton from every view.
// Plain QtQuick (no Quickshell), so modules/tests/tst_keyboard.qml can still load Pill.
QtObject {
    id: root

    // Every palette has the same keys, Material 3 roles. QML reads a property called onX as a signal
    // handler, so onPrimary and onSecondary are primaryInk and secondaryInk below.
    readonly property var palettes: ({
        teal:     { label: "Teal", dark: true, surface: "#0e1514", container: "#1a2120", high: "#252b2a", highest: "#303635",
                    primary: "#80d5c8", onPrimary: "#003731", secondary: "#334b47", onSecondary: "#cce8e2",
                    text: "#dde4e2", dim: "#bec9c6", outline: "#6f7977",
                    good: "#8bd5a0", warn: "#f2c36b", bad: "#ffb4ab" },
        blue:     { label: "Blue", dark: true, surface: "#111318", container: "#1d2024", high: "#282a2f", highest: "#33353a",
                    primary: "#a8c7fa", onPrimary: "#062e6f", secondary: "#3e4759", onSecondary: "#d9e3f8",
                    text: "#e2e2e9", dim: "#c4c6d0", outline: "#72777f",
                    good: "#8fd69c", warn: "#f0c46a", bad: "#ffb4ab" },
        graphite: { label: "Graphite", dark: true, surface: "#121212", container: "#1e1e1e", high: "#2a2a2a", highest: "#363636",
                    primary: "#e8e8e8", onPrimary: "#141414", secondary: "#3a3a3a", onSecondary: "#ececec",
                    text: "#f2f2f2", dim: "#b4b4b4", outline: "#767676",
                    good: "#7ee2a8", warn: "#ffcc66", bad: "#ff6b6b" },
        midnight: { label: "Midnight", dark: true, surface: "#0b0f1a", container: "#151b2b", high: "#202840", highest: "#2a3452",
                    primary: "#7aa2f7", onPrimary: "#0b1530", secondary: "#2a3452", onSecondary: "#d6e0fb",
                    text: "#e8ecf7", dim: "#a9b3cc", outline: "#5a6585",
                    good: "#9ece6a", warn: "#e0af68", bad: "#f7768e" },
        nord:     { label: "Nord", dark: true, surface: "#2e3440", container: "#3b4252", high: "#434c5e", highest: "#4c566a",
                    primary: "#88c0d0", onPrimary: "#22303a", secondary: "#4c566a", onSecondary: "#e5e9f0",
                    text: "#eceff4", dim: "#c3cad6", outline: "#7b879c",
                    good: "#a3be8c", warn: "#ebcb8b", bad: "#bf616a" },
        rose:     { label: "Rosé", dark: true, surface: "#191724", container: "#1f1d2e", high: "#26233a", highest: "#393552",
                    primary: "#ebbcba", onPrimary: "#2a1f2b", secondary: "#393552", onSecondary: "#e0def4",
                    text: "#e0def4", dim: "#aba7c4", outline: "#6e6a86",
                    good: "#9ccfd8", warn: "#f6c177", bad: "#eb6f92" },
        forest:   { label: "Forest", dark: true, surface: "#11150f", container: "#1b2118", high: "#262e22", highest: "#323c2d",
                    primary: "#a7c080", onPrimary: "#1c2a10", secondary: "#323c2d", onSecondary: "#dfe8d2",
                    text: "#e6eadf", dim: "#b4bdab", outline: "#69745f",
                    good: "#83c092", warn: "#dbbc7f", bad: "#e67e80" },
        paper:    { label: "Paper", dark: false, surface: "#f4f4f1", container: "#e8e8e4", high: "#dcdcd7", highest: "#d0d0ca",
                    primary: "#2f6fde", onPrimary: "#ffffff", secondary: "#d6e2fa", onSecondary: "#0f2a5c",
                    text: "#1c1c1e", dim: "#4c4c52", outline: "#8e8e93",
                    good: "#2e9b5f", warn: "#b7791f", bad: "#d64545" }
    })
    readonly property var names: Object.keys(palettes)

    // A wallpaper's own colours are often too dark or too muddy to read as they are, so only the hue of
    // `wallpaperSeed` is used, at `wallpaperSaturation` and `wallpaperTone`.
    property string source: "preset"
    property string name: "teal"
    property color accent: "#4f9d8f"
    property color wallpaperSeed: "#4f9d8f"
    property real wallpaperSaturation: 0.8
    property real wallpaperTone: 0.72              // the primary's lightness in dark mode; light mode mirrors it
    // The surfaces' own tint, apart from the accent: its hue (0..1), and how much of it they take (0 = grey).
    property real surfaceHue: 0.47
    property real tint: 0.5
    property bool darkMode: true
    // The surfaces of a custom accent take its hue, as Android's do, rather than surfaceHue of their own
    // (Theme's Surfaces: Matched; Custom and Neutral leave it off). A wallpaper option sets its own.
    property bool surfaceFollows: false
    // "standard" or "high": every source, presets too, so it's applied after the palette is picked
    property string contrastLevel: "standard"
    readonly property var current: withContrast(source === "preset" ? (palettes[name] ?? palettes.teal) : generated(source))

    // The last accents chosen (the eyedropper, the hex field, or what the map was left on), newest
    // first, for the Colours view's Recent row. A string, so the state file keeps it as written.
    property string recent: ""
    readonly property var recentAccents: recent === "" ? [] : recent.split(",")
    function remember(c) {
        const h = hex(c)
        recent = [h].concat(recentAccents.filter(x => x !== h)).slice(0, 8).join(",")
    }

    // What a wallpaper offers, as Android's wallpaper colours do: a scheme for each of its distinct
    // colourful colours, with the surfaces in the picture's own cast (its overall hue, tinted as much as
    // the picture is coloured), then the first colour two more ways: surfaces matching the accent, and
    // grey. Each is { name, accent, surfaceHue, tint }; Wallpaper.qml keeps the one picked.
    function colourfulness(c) { return c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.5) * 1.6) }
    function chroma(c) { return c.hslSaturation * (1 - Math.abs(2 * c.hslLightness - 1)) }
    function hueGap(a, b) { const d = Math.abs(a - b) % 1; return Math.min(d, 1 - d) }
    function hueName(h) {
        const names = [[0.04, "Red"], [0.1, "Orange"], [0.18, "Yellow"], [0.43, "Green"], [0.53, "Teal"],
                       [0.71, "Blue"], [0.8, "Purple"], [0.94, "Pink"], [1.01, "Red"]]
        return names.find(n => h < n[0])[1]
    }
    function wallpaperOptions(swatches) {
        const all = Array.from(swatches ?? []).filter(c => c.a > 0)
        if (all.length === 0) return []
        // The cast: median cut makes buckets of about as many pixels each, so a sum over the swatches
        // weighs the whole picture, and opposite hues cancel: a picture of every colour has little cast.
        let x = 0, y = 0
        for (const c of all) {
            if (c.hslHue < 0) continue
            const w = chroma(c), a = 2 * Math.PI * c.hslHue
            x += w * Math.cos(a)
            y += w * Math.sin(a)
        }
        const cast = Math.hypot(x, y) / all.length              // 0 grey .. 1 one vivid hue all over
        const castHue = (Math.atan2(y, x) / (2 * Math.PI) + 1) % 1
        const castTint = cast < 0.03 ? 0 : Math.min(0.85, 0.25 + 1.5 * cast)

        // the accents: the most colourful first, each a twelfth of the wheel away from those before
        const ranked = all.slice().sort((a, b) => colourfulness(b) - colourfulness(a))
        const accents = []
        for (const c of ranked) {
            if (accents.length === 4) break
            if (c.hslHue >= 0 && colourfulness(c) > 0.1 && accents.every(a => hueGap(a.hslHue, c.hslHue) > 1 / 12))
                accents.push(c)
        }
        if (accents.length === 0) accents.push(ranked[0])     // a grey picture: its least grey colour, a grey scheme

        const options = accents.map((a, i) => ({ name: i === 0 ? "Auto" : hueName(Math.max(0, a.hslHue)),
                                                 accent: a, surfaceHue: castHue, tint: castTint }))
        const first = accents[0], firstHue = Math.max(0, first.hslHue)
        if (first.hslHue >= 0 && !(castTint > 0.6 && hueGap(castHue, firstHue) < 1 / 24))
            options.push({ name: "Matched", accent: first, surfaceHue: firstHue, tint: 0.85 })
        if (castTint > 0.05)
            options.push({ name: "Neutral", accent: first, surfaceHue: castHue, tint: 0 })
        return options
    }
    // the scheme an option would make, for its circle in views/Colours.qml
    function wallpaperScheme(option) {
        const a = option.accent
        return scheme(Qt.hsla(Math.max(0, a.hslHue), a.hslHue < 0 ? 0 : wallpaperSaturation, wallpaperLightness, 1),
                      option.surfaceHue, option.tint, darkMode)
    }
    // The option whose surfaces were last put in surfaceHue / tint ("image|index"). Another image or
    // option puts its own (`force`: the colours have just started coming from the wallpaper); the
    // Surface row moves them after, and a restart keeps that.
    property string surfaceFrom: ""
    function takeSurface(option, key, force) {
        if (!option || (key === surfaceFrom && !force)) return
        surfaceFrom = key
        surfaceHue = option.surfaceHue
        tint = option.tint
    }

    // the lightness the wallpaper's primary has right now, and setting it: the slider means what it says in either mode
    readonly property real wallpaperLightness: darkMode ? wallpaperTone : 1 - wallpaperTone
    function setWallpaperLightness(v) { wallpaperTone = darkMode ? v : 1 - v }

    function generated(from) {
        const primary = from === "wallpaper"
            ? Qt.hsla(Math.max(0, wallpaperSeed.hslHue), wallpaperSeed.hslHue < 0 ? 0 : wallpaperSaturation, wallpaperLightness, 1)
            : accent
        const hue = from === "accent" && surfaceFollows ? Math.max(0, accent.hslHue) : surfaceHue
        return scheme(primary, hue, tint, darkMode)
    }
    // High contrast: the secondary text and the outlines move toward the text, the text to black or
    // white, and the primary has to reach 7:1 (WCAG AAA) on the surface instead of 4.5:1. A preset's
    // roles are hex strings: Qt.darker(x, 1) is the colour itself, as an object with r, g, b.
    function withContrast(p) {
        if (contrastLevel !== "high") return p
        const c = v => Qt.darker(v, 1)
        const out = Object.assign({}, p)
        out.text = mix(c(p.text), p.dark ? Qt.rgba(1, 1, 1, 1) : Qt.rgba(0, 0, 0, 1), 0.6)
        out.dim = mix(c(p.dim), out.text, 0.55)
        out.outline = mix(c(p.outline), out.text, 0.35)
        out.primary = readable(c(p.primary), c(p.surface), p.dark, 7)
        out.onPrimary = inkOn(out.primary)
        return out
    }
    // WCAG's relative luminance, and the contrast ratio between two colours (1 .. 21)
    function luminance(c) {
        const linear = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4)
        return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b)
    }
    function contrast(a, b) {
        const x = luminance(a), y = luminance(b)
        return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05)
    }
    // near-black or near-white in the colour's hue, whichever reads on it
    function inkOn(c) {
        return Qt.hsla(Math.max(0, c.hslHue), Math.min(0.5, c.hslSaturation), luminance(c) > 0.179 ? 0.08 : 0.97, 1)
    }
    // The primary is drawn on the surface (icons, a slider's fill, focus rings), so it has to read there:
    // the colour as picked when it does, otherwise lighter (dark) or darker (light), only as much as it
    // takes. Pure blue on a dark island or yellow on a light one would all but vanish as they are.
    readonly property real primaryContrast: 4.5          // WCAG AA for text
    function readable(c, surface, dark, ratio) {
        const need = ratio ?? primaryContrast
        if (contrast(c, surface) >= need) return c
        const h = Math.max(0, c.hslHue), s = c.hslSaturation
        let fails = c.hslLightness, passes = dark ? 1 : 0   // white on dark, black on light always do
        for (let i = 0; i < 16; i++) {
            const mid = (fails + passes) / 2
            if (contrast(Qt.hsla(h, s, mid, 1), surface) >= need) passes = mid
            else fails = mid
        }
        return Qt.hsla(h, s, passes, 1)
    }
    // HSL, not Material's HCT, so tones are approximate. Two families that don't touch: the surfaces and
    // the text on them in the surface's hue at `tint` (none of the accent in them), and the accent's own
    // (the primary, and the secondary containers: selected tiles, chips), a greyer accent a greyer secondary.
    function scheme(picked, surfaceHue, tint, dark) {
        const h = Math.max(0, picked.hslHue)
        const n = 0.32 * tint
        const s = 0.4 * Math.min(1, picked.hslSaturation * 4)
        const surf = light => Qt.hsla(surfaceHue, n, light, 1)
        const acc = (sat, light) => Qt.hsla(h, sat, light, 1)
        const primary = readable(picked, surf(dark ? 0.065 : 0.975), dark)
        return dark ? {
            label: "Generated", dark: true,
            surface: surf(0.065), container: surf(0.105), high: surf(0.145), highest: surf(0.185),
            primary: primary, onPrimary: inkOn(primary),
            secondary: acc(s, 0.26), onSecondary: acc(s, 0.88),
            text: surf(0.91), dim: surf(0.75), outline: surf(0.52),
            good: "#8bd5a0", warn: "#f2c36b", bad: "#ffb4ab"
        } : {
            label: "Generated", dark: false,
            surface: surf(0.975), container: surf(0.935), high: surf(0.895), highest: surf(0.855),
            primary: primary, onPrimary: inkOn(primary),
            secondary: acc(s, 0.86), onSecondary: acc(s, 0.16),
            text: surf(0.10), dim: surf(0.32), outline: surf(0.50),
            good: "#2e9b5f", warn: "#b7791f", bad: "#d64545"
        }
    }
    // the "Dark theme" tile: a preset swaps to Paper and back; a generated scheme flips its mode
    function setDark(on) {
        if (source === "preset") name = on ? lastDark : "paper"
        else darkMode = on
    }

    // Bar scales every view by this, so all sizes below are at 100 %. 0.8 .. 1.4.
    property real scale: 1.0

    readonly property color surface:     current.surface
    readonly property color container:   current.container
    readonly property color high:        current.high
    readonly property color highest:     current.highest
    readonly property color primary:     current.primary
    readonly property color primaryInk:  current.onPrimary
    readonly property color secondary:   current.secondary
    readonly property color secondaryInk: current.onSecondary
    readonly property color text:        current.text
    readonly property color dim:         current.dim
    readonly property color outline:     current.outline
    readonly property color good:        current.good
    readonly property color warn:        current.warn
    readonly property color bad:         current.bad
    readonly property bool  dark:        current.dark
    readonly property color divider:     mix(surface, outline, 0.35)
    // the hairline round a panel's cards and resting tiles (Noctalia's box border): there, but quieter
    // than outline; Settings can turn them off
    property bool outlines: true
    readonly property color border:      outlines ? mix(container, outline, 0.4) : "transparent"
    readonly property color primaryDeep: mix(primary, primaryInk, 0.16)

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t)
    }
    // the state layer: `base` under the pointer (8 %) or pressed/focused (12 %), tinted by `ink`
    function state(base, ink, hovered, pressed) {
        return pressed ? mix(base, ink, 0.12) : hovered ? mix(base, ink, 0.08) : base
    }
    // the same state layer on a control with no fill of its own: mixing into a transparent base would shift its colour too
    function layer(hovered, pressed) { return Qt.rgba(text.r, text.g, text.b, pressed ? 0.12 : hovered ? 0.08 : 0) }
    function hex(c) {
        const h = v => Math.round(v * 255).toString(16).padStart(2, "0")
        return "#" + h(c.r) + h(c.g) + h(c.b)
    }

    // the island's largest corner; a shape lower than twice this is a capsule (the compact clock, HUDs).
    // Settings' Roundness scales them all (0.5 .. 1.5).
    property real roundness: 1
    readonly property int radius: Math.round(28 * roundness)
    readonly property int cardRadius: Math.round(24 * roundness)
    readonly property int innerRadius: Math.round(16 * roundness)
    readonly property int smallRadius: Math.round(12 * roundness)

    property string style: "pill"
    property string handle: "strip"
    property bool activateLinux: true

    // Glass is Hyprland's (hypr/modules/look.lua): every window is drawn at decoration.active_opacity over
    // its blur, and layers named glass:* get the same blur. The island is one (Bar), so it takes
    // the windows' opacity, which shell.qml keeps in step with services/Desktops.qml.
    property real windowOpacity: 1
    // The island's own opacity, -1 = the windows'. Down to see-through: never quite 0, as the glass
    // (Hyprland's blur, hyprglass) goes only where the island draws something.
    property real islandOpacity: -1
    readonly property real islandAlpha: Math.max(0.02, Math.min(1, islandOpacity < 0 ? windowOpacity : islandOpacity))
    readonly property color island: Qt.rgba(surface.r, surface.g, surface.b, islandAlpha)
    property bool shadow: true

    // Hyprland's windows animation (its curve, "Glide" in hypr/modules/look.lua, and its speed: 3.5 = 350 ms),
    // read from Hyprland itself (services/Desktops.qml, kept in step by shell.qml), so the shell and the
    // desktop move alike and look.lua is the one place to change it. These are only the fallback for
    // before it answers. Keep the curve from overshooting: a notch revealed from auto-hide should stop
    // flush with the top edge instead of dipping a pixel below it and settling back.
    property var curve: [0.22, 1, 0.36, 1, 1, 1]     // Easing.BezierSpline: x1, y1, x2, y2, end
    property int motionMs: 350
    // Settings' Reduce motion: the island jumps instead of moving (shell.qml), and nothing fades
    property bool reduceMotion: false

    // Spacing, on a 4 px grid: margins, padding and gaps take one of these (modules/tests/lint-views.js
    // flags a literal off the scale). Radii and font sizes have their own tokens above.
    readonly property int spaceHair: 2                    // a hairline gap between tightly packed things
    readonly property int spaceXs: 4
    readonly property int spaceS: 8
    readonly property int spaceM: 12
    readonly property int spaceL: 16
    readonly property int spaceXl: 24

    // Durations for what isn't the island's own morph (that is motionMs): state layers (hover, press, focus)
    // fade in durationFast, a control changing size or position in durationMedium.
    readonly property int durationFast: reduceMotion ? 0 : 120
    readonly property int durationMedium: reduceMotion ? 0 : 200
    readonly property int durationPulse: 700     // one half of a looping pulse (recording dot, working indicator)
    readonly property int durationSweep: 1200    // a looping sweep across a bar

    // the clock everywhere it shows, and the calendar's first day: -1 = the locale's, 0 Sunday, 1 Monday
    property bool clock24: true
    readonly property string timeFormat: clock24 ? "HH:mm" : "h:mm AP"
    property int firstDay: -1
    // the toasts that only echo a key: volume, brightness and the microphone; and the workspace switch
    property bool levelToasts: true
    property bool switcherToasts: true

    // the "Dark theme" tile: the dark palette to come back to from a light one
    property string lastDark: "teal"
    onNameChanged: if (palettes[name]?.dark) lastDark = name

    // Focus rings show only while the keyboard is being used (Material's "focus visible"): Bar sets
    // this when a key moves focus in a view and clears it when the pointer moves over the island.
    // True by default, so components used anywhere else always show them.
    property bool focusVisible: true

    // Words drawn straight on a picture (the lock screen), lifted by a dark shadow: light in either mode.
    readonly property color pictureInk: "#f5f5f7"
    readonly property color pictureDim: "#c7c7cc"

    // privacy dots beside the island (fixed: they mean the same thing in every palette)
    readonly property color microphone: "#ff9f1a"
    readonly property color camera: "#35ff72"
    readonly property color recording: "#ff5449"

    // One glyph per thing, so the same thing looks the same everywhere it appears.
    readonly property var symbol: ({
        back: "arrow_back", open: "arrow_forward", close: "close",
        hub: "apps", dashboard: "tune", launcher: "search", notifications: "notifications",
        overview: "grid_view", calendar: "calendar_month", media: "music_note", theme: "palette", settings: "settings",
        power: "power_settings_new", screenshot: "screenshot_region", record: "screen_record",
        dnd: "do_not_disturb_on", sound: "volume_up", muted: "volume_off", battery: "battery_full",
        mixer: "instant_mix", colours: "format_color_fill", wallpaper: "wallpaper"
    })

    // An icon-only control's accessible name: what its glyph stands for here, else the glyph's own words.
    function spoken(glyph) {
        const thing = Object.keys(symbol).find(k => symbol[k] === glyph)
        const words = (thing ?? String(glyph ?? "")).replace(/_/g, " ")
        return words.charAt(0).toUpperCase() + words.slice(1)
    }

    // Fonts come from modules/features/theme.nix (inter, jetbrains-mono, material-symbols).
    readonly property string font: "Inter"
    readonly property string mono: "JetBrains Mono"
    readonly property string icons: "Material Symbols Rounded"

    // type scale: label, body, title, headline, display (a laptop at arm's length: on the big side)
    readonly property int small: 12
    readonly property int body: 14
    readonly property int large: 17
    readonly property int title: 22
    readonly property int headline: 30
    readonly property int display: 56

    property Store store: Store {
        category: "theme"
        property alias source: root.source
        property alias name: root.name
        property alias accent: root.accent
        property alias recent: root.recent
        property alias surfaceHue: root.surfaceHue
        property alias surfaceFrom: root.surfaceFrom
        property alias tint: root.tint
        property alias wallpaperSaturation: root.wallpaperSaturation
        property alias wallpaperTone: root.wallpaperTone
        property alias darkMode: root.darkMode
        property alias scale: root.scale
        property alias style: root.style
        property alias handle: root.handle
        property alias activateLinux: root.activateLinux
        property alias surfaceFollows: root.surfaceFollows
        property alias contrastLevel: root.contrastLevel
        property alias outlines: root.outlines
        property alias roundness: root.roundness
        property alias islandOpacity: root.islandOpacity
        property alias shadow: root.shadow
        property alias reduceMotion: root.reduceMotion
        property alias clock24: root.clock24
        property alias firstDay: root.firstDay
        property alias levelToasts: root.levelToasts
        property alias switcherToasts: root.switcherToasts
        property alias lastDark: root.lastDark
    }
}
