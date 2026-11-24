pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "Agenda.js" as Agenda

// What's next in the calendars subscribed to by their secret iCal address, read by island-calendar
// (nixos-dotfiles, modules/features/quickshell/calendars.py). An address is a secret, so it's added
// in a terminal, never through the shell: `island-calendar add`, then paste it (it goes in on stdin,
// where no one else can read it). What it kept at the last read shows at once; then a read every
// quarter of an hour while any is subscribed, and again when the network comes back after one that
// didn't. From Nihil-Shell's Calendar (MIT: nixos-dotfiles, modules/features/nilo-agent/LICENSE).
Singleton {
    id: root

    // [{ id, name, ok }], and their events: [{ cal, title, where, allDay, start, end }] by start
    property var calendars: []
    property var events: []
    readonly property bool any: calendars.length > 0
    readonly property bool failed: calendars.some(c => !c.ok)
    property bool loaded: false
    readonly property string keptFile: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/island/calendar.json"
    readonly property string listFile: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/island/calendars.json"

    // the clock the next ones are measured against, a minute at a time
    property real now: Date.now() / 1000
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.now = Date.now() / 1000 }

    function upcoming(count) { return Agenda.upcoming(events, now, count) }
    readonly property var next: upcoming(1)[0] ?? null

    function take(text) {
        try {
            const kept = JSON.parse(text)
            if (!Array.isArray(kept?.calendars) || !Array.isArray(kept?.events)) return
            calendars = kept.calendars.filter(c => typeof c?.id === "string").map(c => ({ id: c.id, name: String(c.name ?? ""), ok: c.ok === true }))
            events = kept.events.filter(e => Number.isFinite(e?.start) && Number.isFinite(e?.end))
        } catch (error) {}
    }

    function sync() {
        if (!loaded) return
        if (syncer.running) { syncer.again = true; return }
        syncer.running = true
    }

    function title(event) { return event.title !== "" ? event.title : "Untitled" }
    // When one is, in a few words: Now, Today 10:00, Tomorrow, Thu 19 18:30
    function when(event) {
        if (!event.allDay && event.start <= now && now < event.end) return "Now"
        const away = Agenda.daysAway(event.start, now)
        const start = new Date(event.start * 1000)
        const time = Qt.formatTime(start, "HH:mm")
        if (away <= 0) return event.allDay ? "Today" : time
        if (away === 1) return event.allDay ? "Tomorrow" : "Tomorrow " + time
        const day = Qt.formatDate(start, "ddd d")
        return event.allDay ? day : day + " " + time
    }

    Timer {
        interval: 15 * 60 * 1000
        running: root.any
        repeat: true
        onTriggered: root.sync()
    }

    Connections {
        target: Net
        function onCurrentChanged() { if (root.failed) root.sync() }
        function onEthernetChanged() { if (root.failed) root.sync() }
    }

    Process {
        id: syncer
        property bool again: false
        command: ["island-calendar", "sync"]
        stdout: StdioCollector { onStreamFinished: root.take(text) }
        onExited: if (syncer.again) { syncer.again = false; syncAgain.restart() }
    }
    Timer {
        id: syncAgain
        interval: 50
        onTriggered: syncer.running ? syncAgain.restart() : root.sync()
    }

    // What was kept, at once, and whether any calendar is subscribed: then a read. With none,
    // nothing runs.
    Process {
        command: ["sh", "-c", "if [ -s \"$2\" ]; then echo some; else echo none; fi; cat \"$1\" 2>/dev/null", "sh",
                  root.keptFile, root.listFile]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const cut = text.indexOf("\n")
                root.take(text.slice(cut + 1))
                root.loaded = true
                if (text.slice(0, cut) === "some" || root.any) root.sync()
            }
        }
    }

    IpcHandler {
        target: "calendar"

        function sync(): void    { root.sync() }
        function next(): string  { return root.next ? root.when(root.next) + "  " + root.title(root.next) : "" }
    }
}
