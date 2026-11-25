import QtQuick

// For the keys a view answers to that have no button to badge (volume up, seek...), on a capsule so
// they read on any glass.
Rectangle {
    id: root

    property var keys: []

    visible: Config.focusVisible && keys.length > 0
    implicitWidth: flow.implicitWidth + 2 * Config.spaceL
    implicitHeight: flow.implicitHeight + 2 * Config.spaceS
    radius: Math.min(height / 2, Config.cardRadius)
    color: Config.tile

    Flow {
        id: flow
        anchors { fill: parent; leftMargin: Config.spaceL; rightMargin: Config.spaceL; topMargin: Config.spaceS; bottomMargin: Config.spaceS }
        spacing: Config.spaceL

        Repeater {
            model: root.keys

            Row {
                required property var modelData
                spacing: Config.spaceS

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(22, cap.implicitWidth + 12)
                    height: 22
                    radius: 6
                    color: Config.raised
                    border.width: 1
                    border.color: Config.outline

                    Text {
                        id: cap
                        anchors.centerIn: parent
                        text: modelData[0]
                        color: Config.text
                        font.family: Config.mono
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData[1]
                    color: Config.dim
                    font.pixelSize: Config.small
                }
            }
        }
    }
}
