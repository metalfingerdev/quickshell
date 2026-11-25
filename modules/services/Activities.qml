pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

// Work that takes a while: shown on the island while it runs (Compact), with a toast when it ends,
// what the Dynamic Island calls a Live Activity. Anything can report one (docs/ipc.md):
//   qs ipc call activity start rebuild "Rebuilding NixOS"
//   qs ipc call activity progress rebuild 0.4      0..1; below 0: no idea how far
//   qs ipc call activity done rebuild              or failed; clear ends it without a toast
// A download in a browser is one too: a *.part or *.crdownload growing in the downloads folder.
// One with a card of its own in Expanded (the agent's) starts with `own`: Compact and the list show
// it, ActivityCard doesn't.
Singleton {
    id: root

    property var jobs: ({})                 // id -> { label, fraction, own }, fraction -1 = unknown
    readonly property var list: Object.keys(jobs).map(id => ({ id: id, label: jobs[id].label, fraction: jobs[id].fraction, own: jobs[id].own }))
    readonly property var shared: list.filter(j => !j.own)   // for ActivityCard
    readonly property bool working: list.length > 0
    // the furthest behind of those that say how far they are; -1 = none says
    readonly property real level: {
        const known = list.filter(j => j.fraction >= 0).map(j => j.fraction)
        return known.length > 0 ? Math.min(...known) : -1
    }
    readonly property string label: list.length === 0 ? "" : list[0].label + (list.length > 1 ? " +" + (list.length - 1) : "")

    // the last one to end, for the toast
    property string lastLabel: ""
    property bool lastOk: true
    signal ended(bool ok)

    function start(id, label, own = false) { put(id, label, -1, own) }
    function progress(id, fraction) { put(id, jobs[id]?.label ?? id, fraction, jobs[id]?.own ?? false) }
    function put(id, label, fraction, own) {
        const next = Object.assign({}, jobs)
        next[id] = { label: label || id, fraction: isFinite(fraction) && fraction >= 0 ? Math.min(1, fraction) : -1, own: own }
        jobs = next
    }
    // outcome: "done", "failed" or "quiet" (gone without a toast)
    function finish(id, outcome) {
        if (!(id in jobs)) return
        const label = jobs[id].label
        const next = Object.assign({}, jobs)
        delete next[id]
        jobs = next
        if (outcome === "quiet") return
        lastLabel = label
        lastOk = outcome === "done"
        ended(lastOk)
    }

    IpcHandler {
        target: "activity"

        function start(id: string, label: string): void     { root.start(id, label) }
        function progress(id: string, fraction: real): void { root.progress(id, fraction) }
        function done(id: string): void   { root.finish(id, "done") }
        function failed(id: string): void { root.finish(id, "failed") }
        function clear(id: string): void  { root.finish(id, "quiet") }
        function list(): string           { return JSON.stringify(root.list, null, 2) }
    }

    // Downloads. A partial file counts only while it grows: one left behind (a paused download, a
    // browser that crashed) would keep the activity up for good. Gone, it was done; stalled, quiet.
    property string downloads: ""
    property int growing: 0
    readonly property bool downloading: downloads !== "" && partial.count > 0 && growing > 0
    onDownloadingChanged: {
        if (downloading) start("downloads", "Download")
        else finish("downloads", partial.count === 0 ? "done" : "quiet")
    }

    FolderListModel {
        id: partial
        folder: root.downloads !== "" ? "file://" + root.downloads : ""
        nameFilters: ["*.part", "*.crdownload"]
        showDirs: false
        showHidden: true
        onCountChanged: {
            if (count > 0) look.restart()
            else root.growing = 0
        }
    }

    // Written to in the last half minute: looked at every few seconds while one grows, every
    // minute while only stale ones lie there, and at once when one comes or goes.
    Process {
        id: fresh
        command: ["sh", "-c", "find \"$1\" -maxdepth 1 -type f \\( -name '*.part' -o -name '*.crdownload' \\) -newermt '30 seconds ago' | wc -l",
                  "sh", root.downloads]
        stdout: StdioCollector { onStreamFinished: root.growing = parseInt(text) || 0 }
    }
    Timer {
        id: look
        interval: root.growing > 0 ? 5000 : 60000
        running: root.downloads !== "" && partial.count > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!fresh.running) fresh.running = true
    }
    Process {
        running: true
        command: ["sh", "-c", "xdg-user-dir DOWNLOAD 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const dir = text.trim(), home = Quickshell.env("HOME")
                root.downloads = dir !== "" && dir !== home ? dir : home + "/Downloads"
            }
        }
    }
}
