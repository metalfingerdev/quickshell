// Run: node modules/tests/controllayout.test.js
const fs = require("fs"), path = require("path"), assert = require("assert")
const src = fs.readFileSync(path.join(__dirname, "../services/ControlLayout.js"), "utf8").replace(".pragma library", "")
const L = new Function(src + "; return { sizes, defaults, clean, pack, move, without, missing }")()
let n = 0
const t = (name, f) => { f(); n++ }
const overlap = items => {
    const seen = new Set()
    for (const i of items) for (let y = i.row; y < i.row + i.h; y++) for (let x = i.col; x < i.col + i.w; x++) {
        const k = x + "," + y
        assert(!seen.has(k), "overlap at " + k)
        seen.add(k)
    }
}
t("the default layout fits six columns without overlap", () => {
    const { items } = L.pack(L.defaults, 6)
    overlap(items)
    assert(items.every(i => i.col + i.w <= 6))
    assert.strictEqual(items.length, L.defaults.length)
})
t("the first rows are the ones it always had", () => {
    const at = id => L.pack(L.defaults, 6).items.find(i => i.id === id)
    assert.deepStrictEqual([at("wifi").row, at("bluetooth").col, at("airplane").col], [0, 3, 5])
    assert.deepStrictEqual([at("volume").row, at("mic").col, at("mixer").col], [1, 4, 5])
    assert.deepStrictEqual([at("agent").row, at("agent").col, at("screenshot").col, at("screenshot").row], [4, 0, 2, 4])
    assert.strictEqual(at("picker").row, 6)          // after Wallpaper and Tasks, which the marin layout adds
})
t("a 1x1 fills the hole beside a tall one", () => {
    const { items } = L.pack(["wallpaper", "mic", "mixer"], 6)
    assert.deepStrictEqual(items.map(i => [i.col, i.row]), [[0, 0], [2, 0], [3, 0]])
})
t("unknown and repeated ids are dropped", () => {
    assert.deepStrictEqual(L.clean(["wifi", "nope", "wifi", 3, "dark"]), ["wifi", "dark"])
    assert.deepStrictEqual(L.clean("x"), [])
})
t("move, remove and what's left to add", () => {
    assert.deepStrictEqual(L.move(["a", "b", "c"], 0, 2), ["b", "c", "a"])
    assert.deepStrictEqual(L.move(["a", "b"], 5, 0), ["a", "b"])
    assert.deepStrictEqual(L.without(["a", "b"], "a"), ["b"])
    assert(L.missing(L.defaults).includes("shuffle") && !L.missing(L.defaults).includes("wifi"))
})
console.log(n + " ok")
