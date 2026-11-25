import QtQuick
import QtQuick.Layouts

// A row, as the Control Centre's tiles are: alone a tile of its own (`filled`); in a ListSection (`flat`) one
// of a connected list, its outer corners round where the list ends and nearly square where it meets the next.
// Its icon sits in a raised circle; `lit` (on, connected) turns the whole tile the accent.
Rectangle {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property string trailing: ""
    property bool active: false
    property string shortcut: ""
    property bool keyboardSelected: activeFocus && Config.focusVisible
    readonly property bool hovered: area.containsMouse
    property Component lead: null
    default property alias extra: side.data
    // off by default: a list of entries still scrolls under the pointer
    property bool wheelable: false
    // alone, a platter of its own, so a list that is the view reads as cells; in a ListSection, the section's
    property bool filled: false
    property bool flat: false
    property bool lit: false
    signal clicked()
    signal scrolled(int step)

    activeFocusOnTab: true
    function activate() { clicked() }
    Accessible.role: Accessible.Button
    Accessible.name: title
    Accessible.description: subtitle
    Accessible.onPressAction: activate()

    readonly property int leadSize: flat ? 40 : 44
    readonly property color ink: lit ? Config.primaryInk : active ? Config.secondaryInk : Config.text
    // where it sits in its list: the ends round, the joints nearly square; a ListSection's title and footer are joints too
    readonly property bool first: !flat || (y < 0.5 && !(parent?.parent?.cappedTop ?? false))
    readonly property bool last: !flat || !parent || (y + height > parent.height - 0.5 && !(parent.parent?.cappedBottom ?? false))
    readonly property real outer: Config.cardRadius
    implicitWidth: 320
    width: flat && parent ? parent.width : implicitWidth
    implicitHeight: flat ? (subtitle !== "" ? 64 : 56) : subtitle !== "" ? 64 : 52
    topLeftRadius: first ? outer : 8
    topRightRadius: first ? outer : 8
    bottomLeftRadius: last ? outer : 8
    bottomRightRadius: last ? outer : 8
    color: {
        const base = lit ? Config.primary : active ? Config.secondary : filled || flat ? Config.tile : "transparent"
        const under = base.a > 0 ? base : Config.tile
        return keyboardSelected || area.pressed ? Config.mix(under, ink, 0.10)
             : area.containsMouse ? Config.mix(under, ink, 0.05)
             : base
    }
    Behavior on color { ColorAnimation { duration: Config.durationFast } }

    // under the children, so buttons in the row still get their own clicks
    ClickArea {
        id: area
        onClicked: root.clicked()
        onWheel: wheel => {
            if (!root.wheelable || wheel.angleDelta.y === 0) { wheel.accepted = false; return }
            root.scrolled(wheel.angleDelta.y > 0 ? 1 : -1)
        }
    }

    RowLayout {
        anchors { fill: parent; leftMargin: Config.spaceM; rightMargin: Config.spaceL }
        spacing: Config.spaceM

        Rectangle {
            readonly property bool on: root.lit || root.active
            visible: root.lead !== null || root.icon !== ""
            Layout.preferredWidth: root.leadSize
            Layout.preferredHeight: root.leadSize
            radius: root.leadSize / 2
            color: root.lead !== null ? "transparent" : root.lit ? Config.primaryDeep : root.active ? Config.primary : Config.raised

            Loader {
                anchors.centerIn: parent
                sourceComponent: root.lead
            }

            Icon {
                anchors.centerIn: parent
                visible: root.lead === null && root.icon !== ""
                name: root.icon
                size: root.flat ? 20 : 22
                filled: parent.on
                color: root.active && !root.lit ? Config.primaryInk : root.ink
            }
        }

        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: Config.spaceHair

            Label {
                width: parent.width
                text: root.title
                elide: Text.ElideRight
                color: root.ink
                font.pixelSize: Config.body + 1
                font.weight: Font.Medium
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: root.lit || root.active ? Config.mix(root.ink, root.color, 0.25) : Config.dim
                font.pixelSize: Config.small + 1
            }
        }

        Label {
            visible: text !== ""
            text: root.trailing
            color: Config.dim
            font.pixelSize: Config.small + 1
        }

        RowLayout {
            id: side
            spacing: Config.spaceS
        }
    }

    FocusRing { on: root.keyboardSelected }
    KeyBadge { key: root.shortcut }
}
