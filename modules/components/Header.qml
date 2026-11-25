import QtQuick
import QtQuick.Layouts

// A navigation bar: the back button, the panel's title, its actions at the far end, on a capsule of its
// own so the title reads on any glass. Components don't know the Engine: wire onBack yourself.
Rectangle {
    id: root

    property string icon: ""            // kept for the panels that name theirs; it is drawn small, in the primary colour
    property string title: ""
    property string subtitle: ""
    property bool showBack: true
    default property alias actions: tools.data
    signal back()

    implicitHeight: 56
    radius: height / 2
    color: Config.tile

    RowLayout {
        anchors { fill: parent; leftMargin: root.showBack ? Config.spaceS : Config.spaceL; rightMargin: Config.spaceS }
        spacing: Config.spaceM

        BackButton {
            visible: root.showBack
            Layout.alignment: Qt.AlignVCenter
            onClicked: root.back()
        }

        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Row {
                width: parent.width
                spacing: Config.spaceS

                Icon {
                    visible: root.icon !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.icon
                    size: 20
                    color: Config.primary
                }
                Label {
                    width: parent.width - (root.icon !== "" ? 28 : 0)
                    text: root.title
                    elide: Text.ElideRight
                    font.pixelSize: Config.title
                    font.weight: Font.DemiBold
                }
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
