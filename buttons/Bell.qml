// buttons/Bell.qml
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

    Text {
        anchors.centerIn: parent
        color: area.containsMouse ? Config.bgDark : Config.foreground
        font.family: "Maple Mono"
        font.pixelSize: 14
        text: "\uf0f3"
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}