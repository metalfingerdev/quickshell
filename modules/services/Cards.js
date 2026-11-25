.pragma library

// The task board's cards, { id, text, column }: 0 to do, 1 doing, 2 done. Their order in the list is
// their order in a column. Every change returns a new list.

function read(text) {
    let data
    try { data = JSON.parse(String(text ?? "")) } catch (e) { return [] }
    const seen = new Set()
    return (Array.isArray(data) ? data : data?.cards ?? [])
        .filter(c => typeof c?.text === "string" && c.text.trim() !== "")
        .map((c, i) => ({ id: typeof c.id === "string" && c.id !== "" ? c.id : "card" + i, text: c.text.trim(),
                          column: Math.max(0, Math.min(2, Math.round(Number(c.column) || 0))) }))
        .filter(c => !seen.has(c.id) && seen.add(c.id))
}

function save(cards) { return JSON.stringify({ cards }, null, 2) + "\n" }

function column(cards, n) { return cards.filter(c => c.column === n) }

// new ones go on top of To do, where they're seen
function add(cards, text, id) {
    const t = String(text ?? "").trim()
    return t === "" ? cards : [{ id: String(id), text: t, column: 0 }].concat(cards)
}

function edit(cards, id, text) {
    const t = String(text ?? "").trim()
    return t === "" ? remove(cards, id) : cards.map(c => c.id === id ? Object.assign({}, c, { text: t }) : c)
}

function remove(cards, id) { return cards.filter(c => c.id !== id) }

// to the bottom of the column it goes to; to where it is, nothing changes
function move(cards, id, to) {
    const card = cards.find(c => c.id === id)
    const n = Math.max(0, Math.min(2, to))
    if (!card || card.column === n) return cards
    return cards.filter(c => c.id !== id).concat([Object.assign({}, card, { column: n })])
}

// up (-1) or down (1) within its column, over the neighbour there
function shift(cards, id, by) {
    const i = cards.findIndex(c => c.id === id)
    if (i < 0) return cards
    const same = cards.map((c, k) => c.column === cards[i].column ? k : -1).filter(k => k >= 0)
    const j = same[same.indexOf(i) + by]
    if (j === undefined) return cards
    const next = cards.slice()
    next[i] = cards[j]
    next[j] = cards[i]
    return next
}

function clearDone(cards) { return cards.filter(c => c.column !== 2) }
