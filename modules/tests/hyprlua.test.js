// Run: node modules/tests/hyprlua.test.js
const fs = require("fs"), path = require("path"), assert = require("assert")
const src = fs.readFileSync(path.join(__dirname, "../services/HyprLua.js"), "utf8").replace(".pragma library", "")
const H = new Function(src + "; return { str, hyprlandColour, glassColour, kindOf, hyprland, glass, blurGlass, blurHyprland, shellGlass }")()
let n = 0
const t = (name, f) => { f(); n++ }
t("strings are escaped", () => assert.strictEqual(H.str('a"b\\c\n'), '"a\\"b\\\\c\\n"'))
t("colours go to each side's order", () => { assert.strictEqual(H.hyprlandColour("#11223380"), "0x80112233"); assert.strictEqual(H.glassColour("#11223380"), "0x11223380"); assert.strictEqual(H.glassColour("#112233"), "0x112233ff") })
t("bad colour is dropped", () => assert.strictEqual(H.hyprlandColour("red"), null))
t("kinds", () => { assert.strictEqual(H.kindOf(true), "bool"); assert.strictEqual(H.kindOf(3), "number"); assert.strictEqual(H.kindOf("ee33ccff"), "colour"); assert.strictEqual(H.kindOf("ffffffff 0deg"), null) })
const desc = { "decoration:blur:size": 8, "decoration:shadow:enabled": true, "decoration:shadow:color": "ee1a1a1a", "general:col.active_border": "ffffffff 0deg" }
t("hyprland nests and the mode wins", () => {
    const tables = { shared: { "decoration:blur:size": 4 }, dark: { "decoration:blur:size": 20 }, light: { "decoration:blur:size": 2 } }
    assert.strictEqual(H.hyprland(tables, true, desc), "hl.config({ decoration = { blur = { size = 20 } } })")
    assert.strictEqual(H.hyprland(tables, false, desc), "hl.config({ decoration = { blur = { size = 2 } } })")
})
t("unknown keys, injected values and gradients are dropped", () => {
    assert.strictEqual(H.hyprland({ shared: { "nope:x": 1, "decoration:blur:size": "1); os.execute('x'" } }, true, desc), "")
    assert.strictEqual(H.hyprland({ shared: { "general:col.active_border": "x" } }, true, desc), "")
})
t("colour and bool", () => assert.strictEqual(H.hyprland({ shared: { "decoration:shadow:color": "#000000cc", "decoration:shadow:enabled": false } }, true, desc), "hl.config({ decoration = { shadow = { color = 0xcc000000, enabled = false } } })"))
t("glass keys are checked", () => {
    const g = H.glass({ shared: { blur_strength: 2, tint_color: "#8899aa22", evil: 1 }, dark: { blur_strength: 3 } }, true, { blur_strength: "number", tint_color: "colour" })
    assert.deepStrictEqual(g, { blur_strength: "3", tint_color: "0x8899aa22" })
})
t("blur amount maps both blurs, 0.5 is today's", () => {
    assert.deepStrictEqual(H.blurHyprland(0.5), { enabled: true, size: 8, passes: 3 })
    assert.deepStrictEqual(H.blurGlass(0.5), { blur_strength: 2, blur_iterations: 3 })
    assert.deepStrictEqual(H.blurHyprland(0), { enabled: false, size: 0, passes: 1 })
    assert.deepStrictEqual(H.blurGlass(1), { blur_strength: 4, blur_iterations: 5 })
})
t("two presets, the island on the windows', the layer with its mask", () => {
    const known = { blur_strength: "number", blur_iterations: "number", tint_color: "colour" }
    const out = H.shellGlass({ look: "pomme", enabled: true, dark: true, known,
        windows: { shared: { tint_color: "#11223344" } }, island: { dark: { tint_color: "#00000080" } }, windowBlur: -1, islandBlur: 0.25 })
    assert.strictEqual(out[0], 'hl.plugin.hyprglass.preset("shell_windows", { inherits = "pomme", tint_color = 0x11223344 })')
    assert.strictEqual(out[1], 'hl.plugin.hyprglass.preset("shell_island", { inherits = "shell_windows", tint_color = 0x00000080, blur_strength = 1, blur_iterations = 2 })')
    assert.ok(out[2].includes('default_preset = "shell_windows"') && out[2].includes('enabled = true'))
    assert.ok(out[3].includes('preset = "shell_island"') && out[3].includes('mask_mode = "contour"') && out[3].includes("mask_threshold = 0.01"))
})
t("a look name can't inject", () => assert.ok(H.shellGlass({ look: 'x") os.exit() --', enabled: false, dark: false, known: {}, windows: {}, island: {}, windowBlur: -1, islandBlur: -1 })[0].includes('inherits = "x\\") os.exit() --"')))
console.log(n + " ok")
