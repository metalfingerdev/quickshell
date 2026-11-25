import QtQuick
import Quickshell.Widgets

// A titled platter of rows with hairlines between them (each flat ListEntry draws its own), and an optional
// footer under it: System Settings' inset grouped list. Rows go in as children; give them `flat: true`.
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

    ClippingRectangle {
        width: parent.width
        height: body.implicitHeight
        radius: Config.cardRadius
        color: Config.fill3

        Column {
            id: body
            width: parent.width
        }
    }

    Label {
        visible: root.footer !== ""
        width: parent.width
        leftPadding: Config.spaceM
        rightPadding: Config.spaceM
        wrapMode: Text.WordWrap
        text: root.footer
        color: Config.label2
        font.pixelSize: Config.small
    }
}
