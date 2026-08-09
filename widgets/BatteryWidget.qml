import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config

Item {
    property var close: function() {}

    MouseArea {
        anchors.fill: parent
        onClicked: close()
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: UPower.icon
            color: UPower.isCritical ? "#f38ba8" : UPower.isCharging ? "#a6e3a1" : Config.foreground
            font.family: "Maple Mono"
            font.pixelSize: 48
            font.weight: Font.Light
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: UPower.percentage + "%"
            color: Config.foreground
            font.family: "Maple Mono"
            font.pixelSize: 48
            font.weight: Font.Light
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: UPower.statusLabel
            color: Config.foreground
            font.family: "Maple Mono"
            font.pixelSize: 14
            font.weight: Font.Light
            opacity: 0.6
        }
    }
}