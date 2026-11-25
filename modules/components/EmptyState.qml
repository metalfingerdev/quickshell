import QtQuick

// What a panel shows instead of an empty list, or when the service behind it isn't there: say what is
// missing and why, and offer the one action that helps. `compact` is a single line for a part of a panel.
Item {
    id: root

    property string icon: "inbox"
    property string title: ""
    property string hint: ""
    property string actionText: ""
    property string actionIcon: ""
    property bool compact: false
    signal action()

    implicitWidth: 320
    implicitHeight: col.implicitHeight + (compact ? 0 : 2 * Config.spaceXl)

    Column {
        id: col
        anchors.centerIn: parent
        width: Math.min(parent.width, 380)
        spacing: Config.spaceS

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: root.icon
            size: root.compact ? 24 : 40
            color: Config.dim
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.title
            font.weight: Font.Medium
        }
        Label {
            width: parent.width
            visible: text !== ""
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: root.hint
            color: Config.dim
            font.pixelSize: Config.small + 1
        }
        Pill {
            visible: root.actionText !== ""
            anchors.horizontalCenter: parent.horizontalCenter
            icon: root.actionIcon
            text: root.actionText
            onClicked: root.action()
        }
    }
}
