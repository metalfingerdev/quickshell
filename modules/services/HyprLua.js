.pragma library

// Builds the Lua that `hyprctl eval` runs from settings, so a setting can never become code: keys are
// checked against what Hyprland (or hyprglass) lists, numbers go through Number, strings are quoted.

function str(s) { return '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n") + '"' }

// "#rrggbbaa" (as the settings keep it) to the 0x number each side wants
function hexParts(h) {
    const m = /^#?([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$/.exec(String(h))
    return m ? { rgb: m[1], a: m[2] ?? "ff" } : null
}
function hyprlandColour(h) { const p = hexParts(h); return p ? "0x" + p.a + p.rgb : null }   // Hyprland: AARRGGBB
function glassColour(h) { const p = hexParts(h); return p ? "0x" + p.rgb + p.a : null }       // hyprglass: RRGGBBAA

// what a Hyprland option holds, from its default: bool, number, colour (8 hex digits), or text.
// Gradients ("ffffffff 0deg") and lists are not handled here: they are tables in Lua.
function kindOf(def) {
    if (typeof def === "boolean") return "bool"
    if (typeof def === "number") return "number"
    if (typeof def === "string") {
        if (/^[0-9a-fA-F]{8}$/.test(def)) return "colour"
        if (/deg|^\[|,/.test(def) || / /.test(def)) return null
        return "text"
    }
    return null
}

function value(v, kind, colour) {
    if (kind === "bool") return v ? "true" : "false"
    if (kind === "number") { const n = Number(v); return isFinite(n) ? String(n) : null }
    if (kind === "colour") return colour(v)
    if (kind === "text") return str(v)
    return null
}

function nest(tree, path, lua) {
    const parts = path.split(/[:.]/)
    let o = tree
    for (let i = 0; i < parts.length - 1; i++) o = o[parts[i]] = (typeof o[parts[i]] === "object" ? o[parts[i]] : {})
    o[parts[parts.length - 1]] = lua
}
function table(t) {
    return "{ " + Object.keys(t).map(k => k + " = " + (typeof t[k] === "object" ? table(t[k]) : t[k])).join(", ") + " }"
}

// tables: { shared: {key: v}, dark: {...}, light: {...} }; the mode's table wins. desc: { key: default },
// the options Hyprland lists (hyprctl descriptions -j). Unknown keys and values of the wrong type are dropped.
function merged(tables, dark) { return Object.assign({}, tables?.shared ?? {}, tables?.[dark ? "dark" : "light"] ?? {}) }

function hyprland(tables, dark, desc) {
    const tree = {}
    const all = merged(tables, dark)
    Object.keys(all).forEach(k => {
        if (!(k in desc)) return
        const kind = kindOf(desc[k])
        const lua = kind ? value(all[k], kind, hyprlandColour) : null
        if (lua !== null) nest(tree, k, lua)
    })
    return Object.keys(tree).length ? "hl.config(" + table(tree) + ")" : ""
}

// hyprglass: `known` is { key: "number" | "colour" | "bool" | "choice:..." } from the schema
function glass(tables, dark, known) {
    const out = {}
    const all = merged(tables, dark)
    Object.keys(all).forEach(k => {
        const kind = known[k]
        if (!kind) return
        const lua = value(all[k], kind.startsWith("choice") ? "text" : kind, glassColour)
        if (lua !== null) out[k] = lua
    })
    return out
}

// A blur amount, 0..1, for both blurs that can be drawing: hyprglass's strength (its 12 px units) and
// passes, and Hyprland's size and passes. 0.5 is Hyprland's 8 x 3 in look.lua and hyprglass's own 2 x 3.
function blurGlass(a) { return { blur_strength: Math.round(a * 4 * 100) / 100, blur_iterations: Math.max(1, Math.round(1 + a * 4)) } }
function blurHyprland(a) { return { enabled: a > 0, size: Math.round(a * 16), passes: Math.max(1, Math.round(1 + a * 3)) } }

function fields(o) { return Object.keys(o).map(k => k + " = " + o[k]).join(", ") }

// Everything the shell's glass needs, as hyprctl eval statements. The windows get a preset of ours on top
// of the chosen look, and the island one on top of the windows', so what the island doesn't set follows
// the windows. s: { look, enabled, dark, windows, island ({shared,dark,light} tables), windowBlur and
// islandBlur (0..1, -1 = the look's own), known (GlassSchema.known) }. Returns [] without the plugin.
function shellGlass(s) {
    const w = glass(s.windows, s.dark, s.known), i = glass(s.island, s.dark, s.known)
    if (s.windowBlur >= 0) { const b = blurGlass(s.windowBlur); w.blur_strength = w.blur_strength ?? String(b.blur_strength); w.blur_iterations = w.blur_iterations ?? String(b.blur_iterations) }
    if (s.islandBlur >= 0) { const b = blurGlass(s.islandBlur); i.blur_strength = i.blur_strength ?? String(b.blur_strength); i.blur_iterations = i.blur_iterations ?? String(b.blur_iterations) }
    const hg = "hl.plugin.hyprglass"
    const wf = fields(w), isf = fields(i)
    return [
        `${hg}.preset("shell_windows", { inherits = ${str(s.look)}${wf ? ", " + wf : ""} })`,
        `${hg}.preset("shell_island", { inherits = "shell_windows"${isf ? ", " + isf : ""} })`,
        `${hg}.config({ enabled = ${s.enabled ? "true" : "false"}, default_preset = "shell_windows", default_theme = "${s.dark ? "dark" : "light"}" })`,
        // the mask as plugins.lua sets it: a second call may replace the first rather than add to it
        `${hg}.layer("glass:island", { preset = "shell_island", mask_mode = "contour", mask_threshold = 0.01 })`
    ]
}
