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
    readonly property var items: SystemTray.items.values
        .filter(i => i.status !== Status.Passive && !patterns.some(p => key(i).includes(p)))

    // the one whose menu the Tray view shows; null lists them all
    property var current: null

    function key(item) { return ((item.id ?? "") + " " + (item.title ?? "")).toLowerCase() }
    function name(item) { return item?.tooltipTitle || item?.title || item?.id || "" }
    function hide(item) {
        const id = (item.id || item.title || "").toLowerCase()
        if (id !== "") hidden = patterns.concat([id]).join(",")
    }
}
