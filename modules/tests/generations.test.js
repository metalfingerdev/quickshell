// Run: node modules/tests/generations.test.js
const assert = require("assert")
const { load, test } = require("./harness")
const G = load("services/Generations.js")

const a = "/nix/store/aaa-nixos-system-omen-26.11.20261121.2786a2a", b = "/nix/store/bbb-nixos-system-omen-26.11.20261124.9f00b1c"

test("the kernel's version from its store path", () => {
    assert.strictEqual(G.kernel("/nix/store/qpbd-linux-6.18.64/bzImage"), "6.18.64")
    assert.strictEqual(G.kernel("/nix/store/x-linux-6.19-rc2/Image"), "6.19-rc2")
    assert.strictEqual(G.kernel(""), "")
})
test("generations newest first, the running and the booted one marked", () => {
    const text = [
        `system-150-link\t1764000000\t${a}\t26.11.20261121.2786a2a (Xantusia)\t/nix/store/k-linux-6.18.63/bzImage`,
        `system-151-link\t1764100000\t${b}\t26.11.20261124.9f00b1c (Xantusia)\t/nix/store/k-linux-6.18.64/bzImage`,
        "system-link\tjunk", `current\t${b}`, `booted\t${a}`, ""].join("\n")
    const gens = G.generations(text)
    assert.deepStrictEqual(gens.map(g => [g.id, g.current, g.booted, g.kernel]), [[151, true, false, "6.18.64"], [150, false, true, "6.18.63"]])
    assert.strictEqual(gens[0].made, 1764100000)
})
test("a closure diff: changed, added, removed and only grown", () => {
    const rows = G.closureDiff("\x1b[1mfirefox\x1b[0m: 140.0 → 141.0, +3.2 MiB\nfoo: ∅ → 1.0, +12.0 KiB\nbar: 2.1 → ∅, -1.5 MiB\n"
                               + "glibc: +0.1 KiB\npython3: 3.12.9, 3.13.2 → 3.13.3\n")
    assert.deepStrictEqual(rows.map(r => [r.name, r.kind, r.size]),
        [["firefox", "changed", "+3.2 MiB"], ["foo", "added", "+12.0 KiB"], ["bar", "removed", "-1.5 MiB"],
         ["glibc", "size", "+0.1 KiB"], ["python3", "changed", ""]])
    assert.strictEqual(rows[4].change, "3.12.9, 3.13.2 → 3.13.3")
})
test("the flake's own inputs, not follows nor the inputs' inputs", () => {
    const lock = JSON.stringify({ root: "root", version: 7, nodes: {
        root: { inputs: { nixpkgs: "nixpkgs", quickshell: "quickshell", hm: "home-manager", follow: ["hm", "nixpkgs"] } },
        nixpkgs: { locked: { type: "github", owner: "NixOS", repo: "nixpkgs", rev: "r1", lastModified: 100 }, original: { type: "github", owner: "NixOS", repo: "nixpkgs", ref: "nixos-unstable" } },
        quickshell: { locked: { type: "github", owner: "me", repo: "quickshell", rev: "q1", lastModified: 200 }, original: { type: "github", owner: "me", repo: "quickshell" } },
        "home-manager": { inputs: { nixpkgs: ["nixpkgs"] }, locked: { type: "git", url: "https://example.org/hm.git", rev: "h1" }, original: {} } } })
    const got = G.inputs(lock)
    assert.deepStrictEqual(got.map(i => i.name), ["hm", "nixpkgs", "quickshell"])
    assert.strictEqual(got[1].url, "https://github.com/NixOS/nixpkgs")
    assert.strictEqual(got[1].ref, "nixos-unstable")
    assert.strictEqual(got[0].url, "https://example.org/hm.git")
    assert.deepStrictEqual(G.inputs("{"), [])
})
test("tab-separated lines by their first cell", () => {
    assert.deepStrictEqual(G.table("quickshell\tabc\t0\t2\nnixpkgs\tdef\n\n"), { quickshell: ["abc", "0", "2"], nixpkgs: ["def"] })
})
test("ages read as a person says them", () => {
    const now = 1764100000
    assert.deepStrictEqual([0, 120, 7200, 90000, 3 * 86400, 30 * 86400].map(d => G.ago(now - d, now)),
        ["just now", "2 min ago", "2 h ago", "yesterday", "3 days ago", "4 weeks ago"])
})
test("an input's standing: what keeps a change from the system comes first", () => {
    const input = { name: "quickshell", rev: "q1" }
    assert.deepStrictEqual(G.standing(input, ["q2", "3", "1"], "q1"), { text: "3 files not committed", attention: true })
    assert.deepStrictEqual(G.standing(input, ["q2", "0", "1"], "q1"), { text: "1 commit not pushed", attention: true })
    assert.strictEqual(G.standing(input, ["q2", "0", "0"], "q2").text, "Pushed, not in the lock: nix flake update quickshell")
    assert.deepStrictEqual(G.standing(input, ["q1", "0", "0"], "q1"), { text: "Up to date", attention: false })
    assert.strictEqual(G.standing({ name: "nixpkgs", rev: "r1" }, undefined, "r2").text, "An update is available")
    assert.strictEqual(G.standing({ name: "nixpkgs", rev: "r1" }, undefined, "").text, "")
})
