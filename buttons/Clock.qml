// buttons/Clock.qml
import QtQuick
import qs.services
import qs.config

Rectangle {
    id: button

    signal clicked()

    implicitWidth: label.implicitWidth + 12
    implicitHeight: 28
    radius: Config.radius
    color: area.containsMouse ? Config.accent : Config.highlight

    Text {
        id: label
        anchors.centerIn: parent
        color: area.containsMouse ? Config.bgDark : Config.foreground
        font.family: "Maple Mono"
        font.pixelSize: 14
        text: Time.time
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}