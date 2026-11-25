.pragma library

// What the Generations service's scripts print, read. Times are in seconds.

// "/nix/store/…-linux-6.18.64/bzImage" -> "6.18.64"
function kernel(path) {
    const m = String(path ?? "").match(/-linux-(\d[^/]*)\//)
    return m ? m[1] : ""
}

// Lines "system-N-link\tmade\tstore path\tnixos-version\tkernel", then "current\tpath" and
// "booted\tpath": newest first.
function generations(text) {
    const lines = String(text ?? "").split("\n").map(l => l.split("\t"))
    const running = lines.find(l => l[0] === "current")?.[1] ?? ""
    const booted = lines.find(l => l[0] === "booted")?.[1] ?? ""
    return lines
        .map(l => ({ id: Number((l[0].match(/^system-(\d+)-link$/) ?? [])[1]), l }))
        .filter(g => Number.isInteger(g.id) && g.l.length >= 3)
        .map(({ id, l }) => ({ id, made: Number(l[1]) || 0, path: l[2], version: l[3] ?? "", kernel: kernel(l[4]),
                               current: l[2] === running, booted: l[2] === booted }))
        .sort((a, b) => b.id - a.id)
}

// `nix store diff-closures`: "name: 1.0 → 1.1, +3.2 MiB", ∅ for a side that has none.
function closureDiff(text) {
    return String(text ?? "").replace(/\x1b\[[0-9;]*m/g, "").split("\n")
        .map(l => l.match(/^(.+?): (.+)$/)).filter(Boolean)
        .map(([, name, rest]) => {
            const parts = rest.split(", ")
            const size = /^[+-]\d[\d.]* [KMGT]?i?B$/.test(parts[parts.length - 1]) ? parts.pop() : ""
            const change = parts.join(", ")
            const kind = change.startsWith("∅") ? "added" : change.endsWith("∅") ? "removed" : change === "" ? "size" : "changed"
            return { name, change, size, kind }
        })
}

// The flake's own inputs (not the inputs' inputs, nor `follows`), by name.
function inputs(lockText) {
    let lock
    try { lock = JSON.parse(String(lockText ?? "")) } catch (e) { return [] }
    const root = lock?.nodes?.[lock.root]?.inputs ?? {}
    return Object.keys(root).filter(name => typeof root[name] === "string").sort().map(name => {
        const node = lock.nodes[root[name]] ?? {}
        const locked = node.locked ?? {}, original = node.original ?? {}
        const github = locked.type === "github"
        return { name, type: locked.type ?? "", owner: locked.owner ?? "", repo: locked.repo ?? "", ref: original.ref ?? "",
                 rev: locked.rev ?? "", modified: locked.lastModified ?? 0,
                 url: github ? "https://github.com/" + locked.owner + "/" + locked.repo : locked.url ?? "" }
    })
}

// Lines "name\tvalue\t…", as { name: [values] }
function table(text) {
    const out = {}
    for (const l of String(text ?? "").split("\n")) {
        const cells = l.split("\t")
        if (cells.length >= 2 && cells[0] !== "") out[cells[0]] = cells.slice(1)
    }
    return out
}

function ago(seconds, now) {
    const d = Math.max(0, now - seconds)
    if (d < 60) return "just now"
    if (d < 3600) return Math.floor(d / 60) + " min ago"
    if (d < 86400) return Math.floor(d / 3600) + " h ago"
    if (d < 2 * 86400) return "yesterday"
    if (d < 14 * 86400) return Math.floor(d / 86400) + " days ago"
    return Math.floor(d / (7 * 86400)) + " weeks ago"
}

// Where an input stands. `clone`: its checkout under config/ as [head, uncommitted files, unpushed
// commits (-1: no upstream)], if it has one; `head`: what its branch is upstream, "" not known.
// The first thing that keeps a change from reaching the system wins.
function standing(input, clone, head) {
    if (clone) {
        const dirty = Number(clone[1]) || 0, ahead = Number(clone[2])
        if (dirty > 0) return { text: dirty === 1 ? "1 file not committed" : dirty + " files not committed", attention: true }
        if (ahead > 0) return { text: ahead === 1 ? "1 commit not pushed" : ahead + " commits not pushed", attention: true }
        if (clone[0] && clone[0] !== input.rev && (!head || head === clone[0]))
            return { text: "Pushed, not in the lock: nix flake update " + input.name, attention: true }
    }
    if (head && head !== input.rev) return { text: "An update is available", attention: true }
    if (head) return { text: "Up to date", attention: false }
    return { text: "", attention: false }
}
