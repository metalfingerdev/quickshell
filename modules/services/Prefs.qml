pragma Singleton

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import "PrefsSchema.js" as Schema

// Every setting, in one file the user can edit: ~/.config/island/settings.json, nested as the code is
// (colours.roles.text, island.tuning.gap...). Hand edits apply at once. Only what differs from its default is
// written, so deleting a key is resetting it, and a changed default still reaches whoever never touched it.
// Nothing is clamped: the file takes whatever has the right type. `qs ipc call prefs reset` brings it
// all back, for a shell too broken to read its own settings.
//
// shell.qml hands over `targets` (Config, Engine, Glass...) so this imports none of the island or lock modules.
Singleton {
    id: root

    property var targets: ({})
    readonly property var entries: Schema.entries
    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/island"
    readonly property string file: dir + "/settings.json"

    property bool loading: false
    property var defaults: ({})
    property string written: ""
    property bool ready: false

    function target(e) { return targets[e.t] ?? null }
    function get(e) {
        const o = target(e)
        if (!o) return undefined
        const v = o[e.p]
        return e.m ? (v ?? {})[e.m] : v
    }
    function set(e, v) {
        const o = target(e)
        if (!o) return
        if (e.m) {
            const copy = Object.assign({}, o[e.p] ?? {})
            if (v === undefined) delete copy[e.m]; else copy[e.m] = v
            o[e.p] = copy
        } else if (v !== undefined) o[e.p] = v
    }
    // what the user sees where the setting is derived: the value in use
    function shown(e) {
        const v = get(e)
        if (v !== undefined) return v
        const o = target(e)
        if (e.res && e.res.startsWith("lv:") && o?.lv) return o.lv(e.res.slice(3))
        if (e.res && o) return o[e.res]
        return undefined
    }
    function isSet(e) { return JSON.stringify(get(e)) !== JSON.stringify(defaults[e.key]) }
    function convert(v, kind) {
        if (v === undefined || v === null) return undefined
        if (kind === "bool") return v === true || v === "true" || v === 1
        if (kind === "number") { const n = Number(v); return isNaN(n) ? undefined : n }
        if (kind === "object") return typeof v === "object" ? v : undefined
        return String(v)
    }

    function nest(out, key, v) {
        const parts = key.split(".")
        let o = out
        for (let i = 0; i < parts.length - 1; i++) o = o[parts[i]] = o[parts[i]] ?? {}
        o[parts[parts.length - 1]] = v
    }
    function dig(obj, key) {
        let o = obj
        for (const part of key.split(".")) { if (o === null || typeof o !== "object" || !(part in o)) return undefined; o = o[part] }
        return o
    }

    function save() {
        if (!ready || loading) return
        const out = {}
        entries.forEach(e => { if (isSet(e)) nest(out, e.key, get(e)) })
        const text = JSON.stringify(out, null, 2) + "\n"
        if (text === written) return
        written = text
        view.setText(text)
    }
    Timer { id: later; interval: 400; onTriggered: root.save() }

    function apply(text) {
        let json = {}
        try { json = text.trim() === "" ? {} : JSON.parse(text) } catch (e) { console.warn("settings.json: " + e); return }
        loading = true
        entries.forEach(e => {
            const v = convert(dig(json, e.key), e.kind)
            set(e, v !== undefined ? v : defaults[e.key])
            // a member back to "derived" is removed, not set to undefined
            if (v === undefined && e.m && defaults[e.key] === undefined) set(e, undefined)
        })
        loading = false
    }

    // The first run has no file: take what island.ini had (kept strings, so booleans are converted by kind).
    Settings { id: ini; location: StandardPaths.writableLocation(StandardPaths.GenericStateLocation) + "/quickshell/island.ini" }
    function migrate() {
        loading = true
        entries.forEach(e => {
            if (!e.ini) return
            const v = convert(ini.value(e.ini), e.kind)
            if (v !== undefined) set(e, v)
        })
        loading = false
    }

    function reset(section) {
        loading = true
        entries.filter(e => !section || e.key === section || e.key.startsWith(section + ".")).forEach(e => set(e, defaults[e.key]))
        loading = false
        save()
    }

    function start() {
        if (ready) return
        const d = {}
        entries.forEach(e => { d[e.key] = get(e) })
        defaults = d
        entries.forEach(e => {
            const o = target(e)
            if (o && o[e.p + "Changed"]) o[e.p + "Changed"].connect(() => { if (!root.loading) later.restart() })
        })
        mkdir.running = true
    }
    // Quickshell's own singletons are made as they are first named, so shell.qml names Prefs and sets targets.
    onTargetsChanged: if (Object.keys(targets).length > 0) start()

    Process {
        id: mkdir
        command: ["mkdir", "-p", root.dir]
        onExited: { root.ready = true; view.reload() }
    }
    FileView {
        id: view
        path: root.ready ? root.file : ""
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { const t = text(); if (t !== root.written) { root.written = t; root.apply(t) } }
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound) return
            root.migrate()
            root.save()
        }
    }

    IpcHandler {
        target: "prefs"
        function reset(section: string): void { root.reset(section) }
        function path(): string { return root.file }
        function get(key: string): string {
            const e = root.entries.find(x => x.key === key)
            return e ? JSON.stringify(root.shown(e) ?? null) : "unknown setting"
        }
        function list(): string { return root.entries.map(e => e.key).join("\n") }
    }
}
