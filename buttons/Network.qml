// buttons/Network.qml
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
        font.pixelSize: 16
        font.family: Config.font
        color: area.containsMouse ? Config.bgDark : Config.foreground
        text: {
            if (!NetworkAdapter.wifiEnabled && !NetworkAdapter.isWired) return "󰤭"
            if (NetworkAdapter.isWired)                                  return "󰈀"
            if (!NetworkAdapter.isWifi)                                  return "󰤫"
            var s = NetworkAdapter.signalPercent
            return s >= 75 ? "󰤨" : s >= 50 ? "󰤥" : s >= 25 ? "󰤢" : "󰤟"
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: button.clicked()
    }
}