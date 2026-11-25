.pragma library

// The Control Centre's grid as data: each module's size in cells (columns x rows, of 6 columns), the order it
// comes in until the user changes it, and the packing of an ordered list into the grid. Pure, so node tests it.
const sizes = {
    wifi: [3, 1], bluetooth: [2, 1], airplane: [1, 1],
    volume: [4, 1], mic: [1, 1], mixer: [1, 1],
    brightness: [4, 1], nightlight: [1, 1], dark: [1, 1],
    dnd: [2, 1], notifications: [1, 1], caffeine: [1, 1], battery: [2, 1],
    agent: [2, 2],
    screenshot: [1, 1], record: [1, 1], recordmic: [1, 1], memo: [1, 1],
    clipboard: [1, 1], emoji: [1, 1], codeagent: [1, 1], picker: [1, 1],
    weather: [2, 1], event: [2, 1], system: [2, 1], profile: [6, 1], session: [6, 1],
    nowplaying: [3, 1], wallpaper: [2, 2], shuffle: [1, 1], colours: [1, 1], theme: [1, 1], workspaces: [1, 1],
    media: [1, 1], calendar: [1, 1], files: [1, 1], terminal: [1, 1], tasks: [1, 1], nixos: [1, 1],
    favourites: [1, 1], tray: [1, 1], lock: [1, 1], settings: [1, 1]
}
// what the grid starts as; first-fit fills it row by row, so a 1x1 after the agent's 2x2 tucks in beside it
const defaults = [
    "wifi", "bluetooth", "airplane", "volume", "mic", "mixer", "brightness", "nightlight", "dark",
    "dnd", "notifications", "caffeine", "battery", "agent",
    "screenshot", "record", "recordmic", "memo", "clipboard", "emoji", "codeagent", "picker",
    "weather", "event", "system", "profile", "session"
]

function known(id) { return Object.prototype.hasOwnProperty.call(sizes, id) }
function size(id) { return known(id) ? sizes[id] : [1, 1] }
// a hand-edited list: only known modules, each once, in order
function clean(ids) {
    const seen = {}
    return (Array.isArray(ids) ? ids : []).filter(id => typeof id === "string" && known(id) && !seen[id] && (seen[id] = true))
}
// ids -> [{ id, col, row, w, h }] and the rows used: each module takes the first free place, scanning rows
// left to right, so a hole left by a wide one is filled by the next that fits
function pack(ids, cols) {
    const taken = []
    const free = (r, c, w, h) => {
        for (let y = r; y < r + h; y++) for (let x = c; x < c + w; x++) if (taken[y]?.[x]) return false
        return true
    }
    const items = []
    let rows = 0
    for (const id of clean(ids)) {
        const w = Math.min(cols, size(id)[0]), h = size(id)[1]
        let placed = false
        for (let r = 0; !placed; r++) {
            for (let c = 0; c + w <= cols && !placed; c++) {
                if (!free(r, c, w, h)) continue
                for (let y = r; y < r + h; y++) { taken[y] = taken[y] ?? []; for (let x = c; x < c + w; x++) taken[y][x] = true }
                items.push({ id: id, col: c, row: r, w: w, h: h })
                rows = Math.max(rows, r + h)
                placed = true
            }
        }
    }
    return { items: items, rows: rows }
}
function move(ids, from, to) {
    const out = ids.slice()
    if (from < 0 || from >= out.length || to < 0 || to >= out.length) return out
    out.splice(to, 0, out.splice(from, 1)[0])
    return out
}
function without(ids, id) { return ids.filter(x => x !== id) }
function missing(ids) { return Object.keys(sizes).filter(id => !ids.includes(id)) }
