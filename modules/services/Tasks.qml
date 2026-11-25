pragma Singleton

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import "Cards.js" as Cards

// The task board (views/Board.qml), kept in a file of its own rather than island.ini, so it can be
// edited by hand, or by a script, and the board follows.
Singleton {
    id: root

    property var cards: []
    readonly property int open: cards.filter(c => c.column < 2).length
    readonly property var columns: [Cards.column(cards, 0), Cards.column(cards, 1), Cards.column(cards, 2)]

    function set(next) {
        if (next === cards) return
        cards = next
        file.setText(Cards.save(next))
    }
    // the id only has to be new: the time, and a counter for two in the same millisecond
    property int made: 0
    function add(text) { set(Cards.add(cards, text, Date.now().toString(36) + (made++).toString(36))) }
    function edit(id, text) { set(Cards.edit(cards, id, text)) }
    function remove(id) { set(Cards.remove(cards, id)) }
    function move(id, to) { set(Cards.move(cards, id, to)) }
    function shift(id, by) { set(Cards.shift(cards, id, by)) }
    function clearDone() { set(Cards.clearDone(cards)) }

    FileView {
        id: file
        path: StandardPaths.writableLocation(StandardPaths.GenericStateLocation).toString().replace(/^file:\/\//, "")
              + "/quickshell/tasks.json"
        watchChanges: true
        atomicWrites: true
        printErrors: false
        onFileChanged: reload()
        // the watcher sees our own writes too: only a real change replaces the cards (and rebuilds the board)
        onLoaded: {
            const next = Cards.read(text())
            if (Cards.save(next) !== Cards.save(root.cards)) root.cards = next
        }
    }

    IpcHandler {
        target: "tasks"

        function add(text: string): void { root.add(text) }
        function list(): string { return Cards.save(root.cards) }
    }
}
