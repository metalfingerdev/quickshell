import QtQuick
import QtQuick.Layouts

// A panel's title on a card of its own, after Noctalia's: the panel's glyph in the primary colour, its
// name, and its actions at the far end. Components don't know the Engine: wire onBack yourself.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool showBack: true
    default property alias actions: tools.data
    signal back()

    implicitHeight: 64
    radius: Config.cardRadius
    color: Config.container
    border.color: Config.border
    border.width: 1

    RowLayout {
        anchors { fill: parent; leftMargin: Config.spaceS; rightMargin: Config.spaceS }
        spacing: Config.spaceM

        BackButton {
            visible: root.showBack
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.back()
        }

        Icon {
            visible: root.icon !== ""
            Layout.leftMargin: root.showBack ? 0 : Config.spaceS
            name: root.icon
            size: 26
            color: Config.primary
        }

        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Label {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                font.pixelSize: Config.large
                font.weight: Font.DemiBold
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: Config.dim
                font.pixelSize: Config.small + 1
            }
        }

        RowLayout {
            id: tools
            Layout.alignment: Qt.AlignVCenter
            spacing: Config.spaceS
        }
    }
}
