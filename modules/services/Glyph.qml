pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.components

// Light along the island's edge, after Nothing's Glyph Interface (Nihil-Shell's frame light). Bar
// draws it (GlyphLight); this only says when. Progress needs nothing here: it is Activities.level.
Singleton {
    id: root

    property bool enabled: true
    property Store store: Store {
        category: "glyph"
        property alias enabled: root.enabled
    }

    // "run" (once around), "critical" (twice, in the warning colour), "charge" (up both sides)
    signal flashed(string kind)
    function flash(kind) { if (enabled) flashed(kind) }

    IpcHandler {
        target: "glyph"

        function flash(kind: string): void { root.flash(kind) }
        function enable(on: bool): void { root.enabled = on }
    }
}
