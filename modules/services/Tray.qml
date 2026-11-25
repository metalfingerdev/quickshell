pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.modules.components

// The system tray (StatusNotifierItem). Quickshell is the watcher, so apps started before the shell
// show up once it runs. Passive items are left out, as other trays do: an app marks itself passive
// when it has nothing to say.
Singleton {
    id: root

    // hidden from the island by a part of their id or title, case-insensitive
    property string hidden: ""
    property Store store: Store {
        category: "tray"
        property alias hidden: root.hidden
    }
    readonly property var patterns: hidden.split(",").map(s => s.trim().toLowerCase()).filter(s => s !== "")
    // every app with something to say, hidden or not: the Tray view lists these, so a hidden one can come back
    readonly property var all: SystemTray.items.values.filter(i => i.status !== Status.Passive)
    readonly property var items: all.filter(i => !isHidden(i))

    // Apple shows a menu bar extra only when it matters: an app that says it needs attention is the one
    // Compact shows, and Expanded's strip puts those first.
    readonly property var attention: items.filter(i => i.status === Status.NeedsAttention)
    readonly property var strip: attention.concat(items.filter(i => i.status !== Status.NeedsAttention)).slice(0, 6)
    // the one whose menu the Tray view shows; null lists them all
    property var current: null

    function key(item) { return ((item.id ?? "") + " " + (item.title ?? "")).toLowerCase() }
    function name(item) { return item?.tooltipTitle || item?.title || item?.id || "" }
    function isHidden(item) { return patterns.some(p => key(item).includes(p)) }
    function hide(item) {
        const id = (item.id || item.title || "").toLowerCase()
        if (id !== "") hidden = patterns.concat([id]).join(",")
    }
    // every pattern that hides it goes, so it shows again whichever way it was hidden (here, or by hand)
    function show(item) { hidden = patterns.filter(p => !key(item).includes(p)).join(",") }
}
