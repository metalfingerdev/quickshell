import QtQuick
import Quickshell
import qs.modules.services
import qs.modules.components
import qs.modules.island
import qs.modules.parts

// One view, two faces, picked by the phase: the popups as a toast (Triggers closes it when the last
// one goes), the center when pinned.
Item {
    id: root

    readonly property bool center: Engine.pinned
    readonly property var popups: Notifier.popups.slice(0, Notifier.maxPopups)
    readonly property int more: Notifier.popups.length - popups.length
    // the center's groups, by the day each came: Today, Yesterday, Earlier
    function band(time) {
        const start = new Date()
        start.setHours(0, 0, 0, 0)
        if (time >= start.getTime()) return "Today"
        start.setDate(start.getDate() - 1)
        return time >= start.getTime() ? "Yesterday" : "Earlier"
    }

    implicitWidth: center ? 720 : 480
    implicitHeight: (center ? centerColumn.implicitHeight : popupColumn.implicitHeight) + (center ? 48 : 16)

    Column {
        id: popupColumn
        visible: !root.center
        x: 8; y: 8
        width: parent.width - 16
        spacing: Config.spaceS

        Repeater {
            model: root.center ? [] : root.popups
            delegate: NotificationCard {
                width: popupColumn.width
                center: false
            }
        }

        Rectangle {
            visible: root.more > 0
            width: parent.width
            height: moreNote.implicitHeight + 2 * Config.spaceS
            radius: Math.min(height / 2, Config.innerRadius)
            color: Config.tile

            Label {
                id: moreNote
                anchors { left: parent.left; right: parent.right; margins: Config.spaceM; verticalCenter: parent.verticalCenter }
                text: "+" + root.more + " more"
                color: Config.dim
                font.pixelSize: Config.small + 1
            }
        }
    }

    Column {
        id: centerColumn
        visible: root.center
        x: 24; y: 24
        width: parent.width - 48
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: Config.symbol.notifications
            title: "Notifications"
            subtitle: Notifier.count === 0 ? "" : Notifier.count === 1 ? "1 notification" : Notifier.count + " notifications"
            onBack: Engine.back()

            Pill {
                icon: Notifier.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
                text: "Do not disturb"
                implicitHeight: 48
                active: Notifier.dnd
                shortcut: "d"
                onClicked: Notifier.dnd = !Notifier.dnd
            }
            Pill {
                visible: Notifier.count > 0
                implicitHeight: 48
                kind: "text"
                text: "Clear all"
                shortcut: "c"
                onClicked: Notifier.dismissAll()
            }
        }

        ScrollList {
            id: notes
            visible: Notifier.count > 0
            width: parent.width
            maxHeight: Math.min(600, Engine.room - 200)
            spacing: Config.spaceM

            Repeater {
                model: ScriptModel { values: root.center ? Notifier.items : []; objectProp: "id" }
                delegate: Column {
                    id: entry
                    required property var modelData
                    required property int index
                    readonly property string band: root.band(modelData.time)

                    width: notes.innerWidth
                    spacing: Config.spaceS

                    SectionLabel {
                        visible: entry.index === 0 || root.band(Notifier.items[entry.index - 1]?.time ?? 0) !== entry.band
                        text: entry.band
                    }
                    NotificationCard {
                        width: parent.width
                        modelData: entry.modelData
                        center: true
                    }
                }
            }
        }

        EmptyState {
            visible: Notifier.count === 0
            width: parent.width
            icon: Notifier.dnd ? "notifications_off" : "notifications_none"
            title: Notifier.dnd ? "Do not disturb is on" : "No notifications"
        }

        KeyHints {
            width: parent.width
            keys: [["Enter", "open"], ["Del", "dismiss"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
