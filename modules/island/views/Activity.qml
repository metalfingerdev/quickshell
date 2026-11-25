import QtQuick
import QtQuick.Layouts
import qs.modules.island
import qs.modules.components
import qs.modules.services

// As a toast: the activity that just ended, done or failed. Pinned (a click on the toast, or
// `qs ipc call island open activity`): every activity running now, with how far it has got.
Item {
    id: root

    readonly property int pad: 24

    implicitWidth: Engine.pinned ? 560 : Math.max(300, toast.implicitWidth + 40)
    implicitHeight: Engine.pinned ? column.implicitHeight + 2 * pad : 72

    // the glass may be clear: what the capsule shows sits on a capsule of its own
    Rectangle {
        visible: !Engine.pinned
        anchors { fill: parent; margins: Config.spaceS }
        radius: height / 2
        color: Config.tile
    }

    Row {
        id: toast
        visible: !Engine.pinned
        anchors.centerIn: parent
        spacing: Config.spaceL

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 44; height: 44; radius: 22
            color: Activities.lastOk ? Config.primary : Config.bad

            Icon {
                anchors.centerIn: parent
                name: Activities.lastOk ? "check" : "error"
                size: 22
                filled: true
                color: Activities.lastOk ? Config.primaryInk : Config.surface
            }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Config.spaceHair

            Label {
                text: Activities.lastLabel
                font.pixelSize: Config.body + 1
                font.weight: Font.Medium
                width: Math.min(implicitWidth, 320)
                elide: Text.ElideRight
            }
            Label {
                text: Activities.lastOk ? "Done" : "Failed"
                color: Activities.lastOk ? Config.dim : Config.bad
                font.pixelSize: Config.small + 1
            }
        }
    }

    Column {
        id: column
        visible: Engine.pinned
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceM

        Header {
            width: parent.width
            icon: "pending_actions"
            title: "Activities"
            subtitle: Activities.working ? Activities.list.length + " running" : "Nothing running"
            onBack: Engine.back()
        }

        EmptyState {
            width: parent.width
            visible: !Activities.working
            icon: "task_alt"
            title: "Nothing running"
            hint: "Downloads and other jobs show here while they work."
        }

        ScrollList {
            width: parent.width
            visible: Activities.working
            maxHeight: 4 * (64 + spacing) + 14
            spacing: Config.spaceXs

            Repeater {
                model: Activities.list

                ListEntry {
                    required property var modelData
                    width: parent.width
                    filled: true
                    icon: modelData.id === "downloads" ? "download" : "pending"
                    title: modelData.label
                    subtitle: modelData.fraction >= 0 ? Math.round(modelData.fraction * 100) + " %" : "Working…"

                    Progress {
                        visible: modelData.fraction >= 0
                        Layout.preferredWidth: 140
                        fraction: modelData.fraction
                    }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["⌫", "back"], ["Esc", "close"]]
        }
    }
}
