pragma Singleton

import QtQuick
import Quickshell
import qs.modules.components

// Favourite apps, for the Dock view and the top of the launcher, by desktop entry id. An app that's
// gone (uninstalled) keeps its pin, and shows again if it comes back.
Singleton {
    id: root

    property string ids: ""
    property Store store: Store {
        category: "pins"
        property alias ids: root.ids
    }
    readonly property var list: ids === "" ? [] : ids.split(",")
    // read through applications, so the pins show once the entries have been scanned (byId isn't a binding)
    readonly property var apps: {
        const all = DesktopEntries.applications.values
        return list.map(id => all.find(a => a.id === id)).filter(a => a !== undefined)
    }

    // As the launcher starts any app: in a scope of its own (Toggles.launch), so restarting the shell
    // leaves it open.
    readonly property string terminal: "kitty"
    function run(app) {
        if (app.runInTerminal) Toggles.launch([terminal, "-e"].concat(app.command), app.workingDirectory)
        else if (Toggles.has("uwsm")) Toggles.launch([app.id + ".desktop"])
        else app.execute()
    }

    function has(app) { return list.includes(app.id) }
    function toggle(app) { ids = (has(app) ? list.filter(id => id !== app.id) : list.concat([app.id])).join(",") }
    function shift(app, by) {
        const i = list.indexOf(app.id), j = i + by
        if (i < 0 || j < 0 || j >= list.length) return
        const next = list.slice()
        next[i] = next[j]
        next[j] = app.id
        ids = next.join(",")
    }
}
