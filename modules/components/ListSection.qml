import QtQuick

// A titled list of rows, as a connected list of tiles: each flat ListEntry is a tile of its own, the
// Control Centre's joint apart, rounded where the list ends. The title and the footer are pieces of the
// same list, so no words sit on the bare glass.
Column {
    id: root

    property string title: ""
    property string footer: ""
    default property alias rows: body.data
    readonly property bool cappedTop: title !== ""
    readonly property bool cappedBottom: footer !== ""

    width: parent ? parent.width : implicitWidth
    spacing: Config.spaceXs

    Rectangle {
        visible: root.title !== ""
        width: parent.width
        height: 36
        topLeftRadius: Config.cardRadius
        topRightRadius: Config.cardRadius
        bottomLeftRadius: 8
        bottomRightRadius: 8
        color: Config.tile

        Label {
            anchors { left: parent.left; leftMargin: Config.spaceL; verticalCenter: parent.verticalCenter }
            text: root.title
            color: Config.primary
            font.pixelSize: Config.small + 1
            font.weight: Font.DemiBold
        }
    }

    // ListEntry reads its own y and this column's height to round the list's ends, so rows stay its children
    Column {
        id: body
        width: parent.width
        spacing: 4
    }

    Rectangle {
        visible: root.footer !== ""
        width: parent.width
        height: footerLabel.implicitHeight + 2 * Config.spaceS
        topLeftRadius: 8
        topRightRadius: 8
        bottomLeftRadius: Config.cardRadius
        bottomRightRadius: Config.cardRadius
        color: Config.tile

        Label {
            id: footerLabel
            anchors { left: parent.left; right: parent.right; margins: Config.spaceL; verticalCenter: parent.verticalCenter }
            wrapMode: Text.WordWrap
            text: root.footer
            color: Config.dim
            font.pixelSize: Config.small
        }
    }
}
