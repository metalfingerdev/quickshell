import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The tray beside the island, as the status group is in Expanded: one pill of connected buttons, the list of
// background apps (the Tray view) at its start, then each app's icon, which opens its menu.
Rectangle {
    id: root

    readonly property int pad: 3
    property real segmentHeight: 32

    implicitWidth: row.implicitWidth + 2 * pad
    implicitHeight: segmentHeight + 2 * pad
    radius: height / 2
    color: Config.tile

    Row {
        id: row
        x: root.pad
        y: root.pad
        spacing: Config.spaceHair

        Pill {
            implicitHeight: root.segmentHeight
            kind: "text"
            icon: "widgets"
            iconSize: 18
            onClicked: x => Engine.open(Engine.View.Tray, x)
        }

        Repeater {
            model: Tray.strip

            Rectangle {
                id: seg
                required property var modelData
                required property int index
                readonly property bool first: index === 0
                readonly property bool last: index === Tray.strip.length - 1

                width: root.segmentHeight + 4
                height: root.segmentHeight
                topLeftRadius: first ? height / 2 : 6
                bottomLeftRadius: first ? height / 2 : 6
                topRightRadius: last ? height / 2 : 6
                bottomRightRadius: last ? height / 2 : 6
                color: Config.state(Config.raised, Config.text, icon.hovered, false)
                Behavior on color { ColorAnimation { duration: Config.durationFast } }

                TrayIcon {
                    id: icon
                    anchors.centerIn: parent
                    app: seg.modelData
                    size: root.segmentHeight
                    color: "transparent"
                }
            }
        }
    }
}
