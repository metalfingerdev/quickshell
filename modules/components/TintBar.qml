import QtQuick

// A colour quantity in a settings page: its name, and a bar drawn in the colours it gives.
Rectangle {
    id: bar
    property string text: ""
    property alias value: colours.value
    property alias colourAt: colours.colourAt
    signal moved(real value)
    width: parent ? parent.width : 0
    height: 56
    radius: 22
    color: Config.tile
    Label { x: Config.spaceL; anchors.verticalCenter: parent.verticalCenter; width: 120; text: bar.text; color: Config.dim }
    ColourBar {
        id: colours
        anchors { left: parent.left; leftMargin: 120 + Config.spaceL; right: parent.right; rightMargin: Config.spaceL; verticalCenter: parent.verticalCenter }
        title: bar.text
        onMoved: v => bar.moved(v)
    }
}
