import QtQuick
import qs.config
import qs.services

Rectangle {
    id: button

    signal clicked()

    implicitWidth: 28
    implicitHeight: 28
    radius: Config.radius
    color: area.containsMouse ? Config.accent : Config.highlight

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.clicked()

        Text {
            anchors.centerIn: parent
            color: area.containsMouse ? Config.bgDark : UPower.isCritical ? "#f38ba8" : UPower.isCharging ? "#a6e3a1" : Config.foreground
            font.family: "Maple Mono"
            font.pixelSize: 14
            text: UPower.icon
        }
    }
}