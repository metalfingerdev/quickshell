// config/quickshell/buttons/Bluetooth.qml
import QtQuick
import qs.config
import qs.services

Rectangle {
    id: btBtn

    signal clicked()

    implicitWidth: 28
    implicitHeight: 28
    radius: Config.radius
    color: btArea.containsMouse ? Config.accent : Config.highlight

    Text {
        anchors.centerIn: parent
        color: btArea.containsMouse ? Config.bgDark : Config.foreground
        font.pixelSize: 16
        font.family: Config.font
        text: {
            if (!BluetoothAdapter.available) return "󰂲";
            if (!BluetoothAdapter.powered)   return "󰂲";
            if (BluetoothAdapter.connected)  return "󰂱";
            return "󰂯";
        }
    }

    MouseArea {
        id: btArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: btBtn.clicked()
    }
}