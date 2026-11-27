pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The clipboard history, kept by cliphist under $XDG_STATE_HOME/island/clipboard, so it survives a reboot.
// That puts what you copy on disk (and in its backups), which the runtime folder avoided: a password copied
// from a terminal stays until it ages out of the last `size` or is deleted. What a password manager marks
// secret (x-kde-passwordManagerHint, which wl-paste passes on as CLIPBOARD_STATE=sensitive) cliphist never
// keeps. Nothing is inlined into a text file: cliphist's own database holds the entries (capped at `size`),
// and each picture is decoded once into pictures/<id> for its thumbnail, a file the list refers to by path
// and drops when its entry has aged out. Needs cliphist and wl-clipboard.
Singleton {
    id: root

    property int size: 50
    readonly property string stateHome: (Quickshell.env("XDG_STATE_HOME") ?? "") !== "" ? Quickshell.env("XDG_STATE_HOME")
                                  : (Quickshell.env("HOME") ?? "") !== "" ? Quickshell.env("HOME") + "/.local/state" : ""
    readonly property string dir: stateHome !== "" ? stateHome + "/island/clipboard" : ""
    property bool available: false
    readonly property bool enabled: available && dir !== ""

    // newest first: { line (cliphist's own, to decode or delete it), id, text, picture (a file URL), info }
    property var items: []

    Process {
        running: true
        command: ["sh", "-c", "command -v cliphist && command -v wl-paste && command -v wl-copy"]
        onExited: code => root.available = code === 0
    }

    // Every copy goes in, from the start of the session; brought back if it ever stops.
    Process {
        id: watcher
        running: root.enabled
        command: ["sh", "-c", "mkdir -p \"$1\" && chmod 700 \"$1\" \"$1/..\" && exec wl-paste --watch cliphist -db-path \"$1/db\" -max-items \"$2\" store",
                  "sh", root.dir, String(root.size)]
        onRunningChanged: if (!running && root.enabled) rewatch.start()
    }
    Timer { id: rewatch; interval: 3000; onTriggered: watcher.running = root.enabled }

    // The list, with each picture decoded once into the state folder for its thumbnail; a picture whose
    // entry has aged out of the list is deleted, so the folder doesn't outgrow `size`.
    readonly property string listing: "db=\"$1/db\"; pics=\"$1/pictures\"; mkdir -p \"$pics\"; chmod 700 \"$pics\"; list=$(cliphist -db-path \"$db\" list); "
        + "printf '%s\\n' \"$list\" | while IFS= read -r line; do id=${line%%\t*}; "
        + "case $line in *'[[ binary data '*) [ -s \"$pics/$id\" ] || printf '%s\\n' \"$line\" | cliphist -db-path \"$db\" decode > \"$pics/$id\";; esac; "
        + "printf '%s\\n' \"$line\"; done; "
        + "ids=$(printf '%s\\n' \"$list\" | cut -f1); for f in \"$pics\"/*; do [ -e \"$f\" ] || continue; "
        + "printf '%s\\n' \"$ids\" | grep -qx \"${f##*/}\" || rm -f \"$f\"; done"

    function refresh() { if (enabled && !lister.running) lister.running = true }
    Process {
        id: lister
        command: ["sh", "-c", root.listing, "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                root.items = text.split("\n").filter(l => l.includes("\t")).map(l => {
                    const tab = l.indexOf("\t"), id = l.slice(0, tab), shown = l.slice(tab + 1)
                    const binary = shown.match(/^\[\[ binary data (.*?) ?\]\]$/)
                    return { line: l, id: id, text: binary ? "" : shown,
                             picture: binary ? "file://" + root.dir + "/pictures/" + id : "", info: binary ? binary[1] : "" }
                })
            }
        }
    }

    // In a scope of its own (Toggles.launch): wl-copy stays behind to hold what was copied, and a
    // restart of the shell would take it along.
    function copy(item) {
        if (item) Toggles.launch(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist -db-path \"$2\" decode | wl-copy", "sh", item.line, dir + "/db"])
    }

    // Into the window you were in, after the island has let go of the keyboard: copied, and one line
    // of text also typed there (wtype), which works the same in a terminal and anywhere else. More
    // lines are only copied, as typing them would run each one in a terminal; a picture is only copied.
    function paste(item) {
        if (!item) return
        copy(item)
        if (item.picture !== "" || !Toggles.has("wtype")) return
        Quickshell.execDetached(["sh", "-c", "t=$(printf '%s\\n' \"$1\" | cliphist -db-path \"$2\" decode) || exit 0; "
                                         + "case $t in *\"\n\"*|'') exit 0;; esac; sleep 0.15; exec wtype -- \"$t\"",
                                 "sh", item.line, dir + "/db"])
    }

    function remove(item) {
        if (!item) return
        items = items.filter(i => i.id !== item.id)
        run(["sh", "-c", "printf '%s\\n' \"$1\" | cliphist -db-path \"$2/db\" delete; rm -f \"$2/pictures/$3\"", "sh", item.line, dir, item.id])
    }

    function wipe() {
        items = []
        run(["sh", "-c", "cliphist -db-path \"$1/db\" wipe; rm -rf \"$1/pictures\"", "sh", dir])
    }

    function run(command) {
        if (!enabled) return
        changer.command = command
        changer.running = true
    }
    Process { id: changer; onExited: root.refresh() }

    IpcHandler {
        target: "clipboard"

        function wipe(): void { root.wipe() }
    }
}
