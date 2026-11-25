// Shared by the *.test.js files: load a `.pragma library` file and count what passes.
const fs = require("fs"), path = require("path")

// In this realm, not a vm context's: objects from another realm fail assert.deepStrictEqual on their prototype.
exports.load = file => {
    const src = fs.readFileSync(path.join(__dirname, "..", file), "utf8").replace(/^\.pragma library.*$/m, "")
    const names = [...src.matchAll(/^function (\w+)/gm)].map(m => m[1])
    return new Function(src + "\nreturn { " + names.join(", ") + " }")()
}

let pass = 0, fail = 0
exports.test = (name, fn) => {
    try { fn(); pass++; console.log("  ok   " + name) }
    catch (err) { fail++; console.log("  FAIL " + name + "\n         " + err.message.split("\n")[0]) }
}
process.on("exit", () => {
    console.log(`${pass} passed, ${fail} failed`)
    if (fail) process.exitCode = 1
})
