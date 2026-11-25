import QtQuick

// A heading over a group, as the accent on a capsule of its own: the glass under it may be clear.
// topPadding stays a gap above the capsule, as views use it to set the heading apart.
Label {
    id: root

    readonly property int inset: Config.spaceXs
    leftPadding: Config.spaceM
    rightPadding: Config.spaceM
    topPadding: inset
    bottomPadding: inset
    color: Config.primary
    font.pixelSize: Config.small + 1
    font.weight: Font.DemiBold

    Rectangle {
        z: -1
        anchors { left: parent.left; bottom: parent.bottom }
        width: root.implicitWidth
        height: root.contentHeight + 2 * root.inset
        radius: height / 2
        color: Config.tile
    }
}
