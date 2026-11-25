import QtQuick

// What sits on the island sits on this: the glass can be any colour at any opacity, even none, and words
// drawn straight on it are lost over a busy wallpaper. Controls inside take Config.raised, one step up.
// Not focusable: a Card only holds things (Tile is the one you press).
Rectangle {
    id: root

    property string title: ""
    property string action: ""                // the title's trailing link, e.g. "All"
    property string actionShortcut: ""
    property int padding: Config.spaceM
    default property alias content: body.data
    signal actionClicked()

    implicitWidth: 320
    implicitHeight: column.implicitHeight + 2 * padding
    width: parent ? parent.width : implicitWidth
    radius: Config.cardRadius
    color: Config.tile

    Column {
        id: column
        x: root.padding
        y: root.padding
        width: parent.width - 2 * root.padding
        spacing: Config.spaceS

        Item {
            visible: root.title !== ""
            width: parent.width
            height: root.action !== "" ? 32 : titleLabel.implicitHeight

            // Android's section title: the accent, so it reads as a heading and not as a row
            Label {
                id: titleLabel
                anchors { left: parent.left; leftMargin: Config.spaceXs; verticalCenter: parent.verticalCenter }
                text: root.title
                color: Config.primary
                font.pixelSize: Config.small + 1
                font.weight: Font.DemiBold
            }
            Pill {
                visible: root.action !== ""
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                implicitHeight: 32
                kind: "text"
                text: root.action
                icon: Config.symbol.open
                iconSize: 18
                shortcut: root.actionShortcut
                onClicked: root.actionClicked()
            }
        }

        Column {
            id: body
            width: parent.width
            spacing: Config.spaceS
        }
    }
}
