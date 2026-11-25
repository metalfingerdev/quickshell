// Run: node modules/tests/lint-views.js [--strict]
// Style lint for views/, parts/ and components/. No dependencies. Prints a count per rule and fails on any violation (FAIL_ON).
// Every violation is a line you can fix, or, for a file that really is different, an ALLOW entry with the reason.
// Limits: it reads margins/padding/spacing and duration written as a plain positive number (a negative one is an
// optical overlap on purpose), not x/y, width expressions or `property int pad`.
const fs = require("fs"), path = require("path")
const root = path.join(__dirname, "..")
const dirs = ["island/views", "parts", "components"]

const SCALE = [0, 2, 4, 8, 12, 16, 24]        // Config.spaceHair..spaceXl (and 0)
const FAIL_ON = new Set(["hex", "duration", "spacing", "easing", "header", "hints", "empty"])                  // rules that fail the run; the rest only warn

// Panels and the files that are on purpose different. Rule names: hex, duration, spacing, easing,
// header, hints, empty.
const ALLOW = {
    "components/Config.qml":      { rules: ["hex", "duration"], reason: "the palettes and the tokens themselves" },
    "components/ColourMap.qml":   { rules: ["hex"], reason: "the picker's own white/black gradients" },
    "components/HueStrip.qml":    { rules: ["hex"], reason: "the hue gradient: the pure colours of the wheel" },
    "components/Knob.qml":        { rules: ["hex"], reason: "a white handle with a black shadow, on any palette" },
    "components/Swatch.qml":      { rules: ["hex"], reason: "black or white ink picked for contrast on an arbitrary swatch" },
    "island/views/Compact.qml":   { rules: ["header", "hints", "empty"], reason: "the resting indicator, not a panel" },
    "island/views/Expanded.qml":  { rules: ["header", "hints", "empty"], reason: "the hover peek: pointer only by design" },
    "island/views/Tabs.qml":      { rules: ["header", "hints", "empty"], reason: "the hub that opens the panels" },
    "island/views/Dashboard.qml": { rules: ["header", "empty"], reason: "a hub of tiles, has its own hints" },
    "island/views/Launcher.qml":  { rules: ["header", "hints", "empty"], reason: "a search field with its own results and keys" },
    "island/views/Volume.qml":     { rules: ["header", "hints", "empty"], reason: "a toast" },
    "island/views/Brightness.qml": { rules: ["header", "hints", "empty"], reason: "a toast" },
    "island/views/Mic.qml":        { rules: ["header", "hints", "empty"], reason: "a toast" },
    "island/views/Switcher.qml":   { rules: ["header", "hints", "empty"], reason: "an overlay switcher with fixed keys" },
}
// Panels that show a list, which can be empty or unavailable
const LISTS = ["Activity", "Battery", "Board", "Clipboard", "Dock", "Forecast", "History", "Schedule", "TrayMenu", "Wallpapers"]
const PANELS = ["Activity", "Battery", "Bluetooth", "Board", "Clipboard", "Dock", "History", "TrayMenu", "Clock", "Colours", "Conversation", "Media", "Mixer",
                "Network", "Notification", "Power", "Schedule", "Settings", "System", "Theme", "Forecast", "Wallpapers", "Workspaces", "Advanced"]

const strip = src => src.replace(/\/\*[\s\S]*?\*\//g, m => m.replace(/[^\n]/g, " "))
                        .replace(/(^|[^:"'])\/\/.*$/gm, "$1")
const rules = { hex: [], duration: [], spacing: [], easing: [], header: [], hints: [], empty: [] }

for (const dir of dirs) {
    for (const f of fs.readdirSync(path.join(root, dir)).filter(n => n.endsWith(".qml")).sort()) {
        const rel = dir + "/" + f, name = f.replace(".qml", "")
        const allowed = (ALLOW[rel] || {}).rules || []
        const lines = strip(fs.readFileSync(path.join(root, rel), "utf8")).split("\n")
        const hit = (rule, i, what) => { if (!allowed.includes(rule)) rules[rule].push(`${rel}:${i + 1}  ${what}`) }
        lines.forEach((line, i) => {
            for (const m of line.matchAll(/#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{8}\b|#[0-9a-fA-F]{3}\b/g)) hit("hex", i, m[0])
            for (const m of line.matchAll(/\bduration:\s*(\d+(?:\.\d+)?)\s*(?:[;}\n]|$)/g)) hit("duration", i, "duration: " + m[1])
            for (const m of line.matchAll(/\b\w*(?:[mM]argin\w*|[sS]pacing|[pP]adding\w*):\s*(\d+(?:\.\d+)?)\s*(?:[;}\n]|$)/g))
                if (!SCALE.includes(Number(m[1]))) hit("spacing", i, m[0].trim())
            for (const m of line.matchAll(/Easing\.(OutBack|InBack|InOutBack|OutElastic|InElastic|InOutElastic|OutBounce)/g)) hit("easing", i, m[0])
        })
        if (dir === "island/views" && PANELS.includes(name)) {
            const text = lines.join("\n")
            if (!/\bHeader\s*\{/.test(text)) hit("header", -1, "no Header")
            if (!/\bKeyHints\s*\{/.test(text)) hit("hints", -1, "no KeyHints")
            if (LISTS.includes(name) && !/\bEmptyState\s*\{/.test(text)) hit("empty", -1, "no EmptyState")
        }
    }
}

let failed = false
const strict = process.argv.includes("--strict")
for (const [rule, found] of Object.entries(rules)) {
    const fails = found.length && (strict || FAIL_ON.has(rule))
    console.log(`${fails ? "FAIL" : found.length ? "warn" : "ok  "} ${rule.padEnd(9)} ${found.length}`)
    if (process.argv.includes("-v")) found.forEach(l => console.log("       " + l))
    if (fails) failed = true
}
process.exit(failed ? 1 : 0)
