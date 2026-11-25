import QtQuick

// A titled list of rows, as a connected list of tiles: each flat ListEntry is a tile of its own, the
// Control Centre's joint apart, rounded where the list ends. An optional footer under it.
Column {
    id: root

    property string title: ""
    property string footer: ""
    default property alias rows: body.data

    width: parent ? parent.width : implicitWidth
    spacing: Config.spaceXs

    SectionLabel {
        visible: root.title !== ""
        text: root.title
        leftPadding: Config.spaceM
    }

    Column {
        id: body
        width: parent.width
        spacing: 4
    }

    Label {
        visible: root.footer !== ""
        width: parent.width
        leftPadding: Config.spaceM
        rightPadding: Config.spaceM
        wrapMode: Text.WordWrap
        text: root.footer
        color: Config.dim
        font.pixelSize: Config.small
    }
}
