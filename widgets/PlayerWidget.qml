import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Item {
    property var close: function() { }
    Component.onCompleted: forceActiveFocus()
    Keys.onEscapePressed: close()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

 Item {
    id: cavaRow
    Layout.fillWidth: true
    Layout.fillHeight: true
    height: 48
    Keys.onEscapePressed: close()

    Repeater {
        model: 64
        delegate: Item {
            required property int index
            readonly property real value: index < 32
                ? (Cava.leftBars[index] ?? 0)
                : (Cava.rightBars[index - 32] ?? 0)

            x: index * (cavaRow.width / 64)
            width: cavaRow.width / 64
            height: cavaRow.height

            Rectangle {
    width: parent.width - 2
    height: Math.max(2, parent.value * cavaRow.height)
    radius: 1
    color: Config.foreground
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    Behavior on height { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
}
        }
    }
}

        }
    }