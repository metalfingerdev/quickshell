import QtQuick
import qs.modules.island
import qs.modules.components

// What every panel repeats: the Header on top (back goes to Engine.back()), the content in a column of its
// own, the KeyHints footer, inside padding that sets the panel's height. A panel is
//     Panel { id: root; icon: "..."; title: "..."; subtitle: "..."; keys: [["Enter", "open"]]; width: ...; <content> }
// Header actions (Pills) go in `actions: [ ... ]`. A list still brings its own EmptyState (lint-views checks).
Item {
    id: root

    readonly property int pad: Config.spaceXl
    property alias icon: header.icon
    property alias title: header.title
    property alias subtitle: header.subtitle
    property alias actions: header.actions
    property var keys: []                      // KeyHints' pairs, [["key", "what it does"], ...]
    default property alias content: body.data

    implicitWidth: 640
    implicitHeight: column.implicitHeight + 2 * pad

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceM

        Header {
            id: header
            width: parent.width
            onBack: Engine.back()
        }
        Column {
            id: body
            width: parent.width
            spacing: Config.spaceM
        }
        KeyHints {
            width: parent.width
            keys: root.keys
        }
    }
}
