import QtQuick

// A count on a control's corner, as on the Notifications tab: put it inside any button, tile or tab
// and give it a count. It hides at 0 and stops at 99+. Bottom right: the top right is the keycap's.
Rectangle {
    id: badge
    property int count: 0

    visible: count > 0
    x: parent ? parent.width - width + 2 : 0
    y: parent ? parent.height - height - 2 : 0
    width: Math.max(16, label.implicitWidth + 8)
    height: 16
    radius: 8
    color: Config.primary
    z: 100                                         // over the control's own content, under KeyBadge

    Label {
        id: label
        anchors.centerIn: parent
        text: badge.count > 99 ? "99+" : badge.count
        color: Config.primaryInk
        font.pixelSize: 10
        font.weight: Font.Bold
    }
}
