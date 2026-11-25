import QtQuick
import QtQuick.Layouts

// A navigation bar, after Apple's: a glass back button, the panel's title (large when it is a top-level
// panel), glass buttons at the far end. No card behind it. Components don't know the Engine: wire onBack yourself.
Item {
    id: root

    property string icon: ""            // kept for the panels that name theirs; it is drawn small, in the primary colour
    property string title: ""
    property string subtitle: ""
    property bool showBack: true
    default property alias actions: tools.data
    signal back()

    implicitHeight: 56

    RowLayout {
        anchors.fill: parent
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
                color: Config.label2
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
