// config/quickshell/buttons/Launcher.qml
import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: center

    signal requestSurface(string name, real anchorX)

    anchors.centerIn: parent

    Rectangle {
        id: button

        width: 32
        height: 32
        radius: Config.radius
        color: area.containsMouse ? Config.accent : Config.highlight

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                const anchorX = area.mapToItem(null, area.width / 2, 0).x
                if (mouse.button === Qt.RightButton) {
                    requestSurface("player", anchorX)
                } else {
                    requestSurface("launch", anchorX)
                }
            }
        }

        Text {
            anchors.centerIn: parent
            color: area.containsMouse ? Config.bgDark : Config.foreground
            font.family: "Maple Mono"
            font.pixelSize: 14
            font.bold: true
            text: "〇"
        }
    }
}