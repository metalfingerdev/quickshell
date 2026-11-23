import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The clipboard history (ClipHistory), newest first. Enter or a click copies one again, Delete
// forgets it. Held: Super+Shift+V again moves down the list, and letting go of Super copies the
// one reached (Held). Paste it yourself after: only you know whether it's Ctrl+V or Ctrl+Shift+V.
Item {
    id: root

    readonly property int pad: 24
    readonly property int rowH: 64

    implicitWidth: 640
    implicitHeight: column.implicitHeight + 2 * pad

    Component.onCompleted: ClipHistory.refresh()

    function copy(item) {
        ClipHistory.copy(item)
        Engine.close()
    }

    // Held: move the focus down the list (wrapping), or copy the one it's on
    function focusedIndex() {
        for (let i = 0; i < rows.count; i++) if (rows.itemAt(i)?.activeFocus) return i
        return -1
    }
    Connections {
        target: Held
        function onStepped(view, delta) {
            if (view !== Engine.View.Clipboard || rows.count === 0) return
            const i = (Math.max(0, root.focusedIndex()) + delta + rows.count) % rows.count
            rows.itemAt(i)?.forceActiveFocus()
        }
        function onChosen(view) {
            if (view === Engine.View.Clipboard) root.copy(ClipHistory.items[Math.max(0, root.focusedIndex())])
        }
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: 12

        Header {
            width: parent.width
            title: "Clipboard"
            subtitle: !ClipHistory.enabled ? "Needs cliphist and wl-clipboard"
                    : ClipHistory.items.length === 0 ? "What you copy shows here, until the session ends"
                    : ClipHistory.items.length + (ClipHistory.items.length === 1 ? " copy" : " copies") + ", kept in memory"
            onBack: Engine.back()

            Pill {
                visible: ClipHistory.items.length > 0
                implicitHeight: 48
                icon: "delete_sweep"
                text: "Clear"
                onClicked: ClipHistory.wipe()
            }
        }

        ScrollList {
            width: parent.width
            visible: ClipHistory.items.length > 0
            maxHeight: 6 * root.rowH + 14

            Repeater {
                id: rows
                model: ClipHistory.items

                ListEntry {
                    id: row
                    required property var modelData
                    required property int index

                    width: parent.width
                    focus: index === 0
                    icon: "content_paste"
                    title: modelData.picture !== "" ? "Picture" : modelData.text.replace(/\s+/g, " ").trim()
                    subtitle: modelData.info
                    lead: modelData.picture !== "" ? thumb : null
                    onClicked: root.copy(modelData)
                    Keys.onDeletePressed: { Engine.key(); ClipHistory.remove(modelData) }

                    property Component thumb: Component {
                        ClippingRectangle {
                            width: 44; height: 44; radius: 22
                            color: Config.high
                            CoverImage { source: row.modelData.picture; sourceSize: Qt.size(88, 88) }
                        }
                    }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["Enter", "copy"], ["Del", "forget"]]
        }
    }
}
