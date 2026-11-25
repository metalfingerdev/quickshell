import QtQuick

// A panel that rises inside the view over a scrim, for a confirmation or a short form (a password, "Shut
// down in 60 s"). Content goes in as children; `open` shows it, Escape or a click on the scrim dismisses.
// The caller sets the view's focus where it should be once it closes.
FocusScope {
    id: root

    property bool open: false
    property string title: ""
    default property alias content: body.data
    signal dismissed()

    anchors.fill: parent
    visible: opacity > 0
    opacity: open ? 1 : 0
    focus: open
    z: 20
    Behavior on opacity { NumberAnimation { duration: Config.durationMedium } }

    function close() { if (open) { open = false; dismissed() } }
    Keys.onEscapePressed: event => { close(); event.accepted = true }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.4)
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Rectangle {
        id: panel
        width: parent.width - 2 * Config.spaceL
        x: Config.spaceL
        height: column.implicitHeight + 2 * Config.spaceL
        y: root.open ? parent.height - height - Config.spaceL : parent.height
        radius: Config.cardRadius
        color: Config.high
        Behavior on y { Motion {} }

        MouseArea { anchors.fill: parent }          // a click on the panel isn't a click on the scrim

        Column {
            id: column
            x: Config.spaceL; y: Config.spaceL
            width: parent.width - 2 * Config.spaceL
            spacing: Config.spaceM

            Label {
                visible: root.title !== ""
                width: parent.width
                text: root.title
                font.pixelSize: Config.large
                font.weight: Font.DemiBold
            }
            Column { id: body; width: parent.width; spacing: Config.spaceM }
        }
    }
}
