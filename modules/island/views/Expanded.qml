import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// It has no keyboard and lives only as long as the hover, so the pointer passing over it can't take
// typing from an app.
Item {
    id: root

    readonly property int pad: 12

    implicitWidth: 460 + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: 8

        Item {
            width: parent.width
            height: 52

            Rectangle {
                id: when
                readonly property bool ring: activeFocus && Config.focusVisible
                anchors.verticalCenter: parent.verticalCenter
                width: dateColumn.implicitWidth + 16
                height: 52
                radius: Config.innerRadius
                color: Config.layer(whenArea.containsMouse, whenArea.pressed || ring)

                activeFocusOnTab: true
                function activate() { Engine.open(Engine.View.Clock) }

                DateStamp {
                    id: dateColumn
                    anchors.centerIn: parent
                    date: clock.date
                }

                ClickArea {
                    id: whenArea
                    onClicked: mouse => Engine.open(Engine.View.Clock, whenArea.sceneX(mouse))
                }

                FocusRing { on: when.ring }
            }

            StatusGroup {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                maxWidth: parent.width - when.x - when.width - 16
                onClicked: (view, x) => Engine.open(view, x)
            }
        }

        MediaCard {
            visible: Players.hasTrack
            width: parent.width
            compact: true
        }
    }
}
