import QtQuick
import QtQuick.Layouts

// A row. Alone it is a platter of its own (`filled`); inside a ListSection it is `flat`, and the section
// draws the platter and the hairlines. `tone` makes its icon a coloured rounded square, as in System Settings.
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
    property color tone: "transparent"
    signal clicked()
    signal scrolled(int step)

    activeFocusOnTab: true
    function activate() { clicked() }
    Accessible.role: Accessible.Button
    Accessible.name: title
    Accessible.description: subtitle
    Accessible.onPressAction: activate()

    readonly property int leadSize: flat ? 32 : 44
    implicitWidth: 320
    width: flat && parent ? parent.width : implicitWidth
    implicitHeight: flat ? (subtitle !== "" ? 60 : 48) : subtitle !== "" ? 64 : 52
    radius: flat ? 0 : Config.innerRadius + 4
    color: {
        const base = active ? Config.secondary : filled && !flat ? Config.fill3 : "transparent"
        return keyboardSelected || area.pressed ? Config.mix(active ? base : Config.fill3, Config.text, 0.10)
             : area.containsMouse ? Config.mix(active ? base : Config.fill3, Config.text, 0.05)
             : base
    }
    Behavior on color { ColorAnimation { duration: Config.durationFast } }

    // the hairline over a row that isn't first, inset past the icon; the row's own y says it isn't
    Rectangle {
        visible: root.flat && root.y > 0.5
        x: Config.spaceM + root.leadSize + Config.spaceM
        width: parent.width - x
        height: 1
        color: Config.fill2
    }

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
            readonly property bool square: root.tone.a > 0
            visible: root.lead !== null || root.icon !== ""
            Layout.preferredWidth: root.leadSize
            Layout.preferredHeight: root.leadSize
            radius: square ? Math.round(root.leadSize * 0.25) : root.leadSize / 2
            color: root.lead !== null ? "transparent" : square ? root.tone : root.active ? Config.primary : Config.fill3

            Loader {
                anchors.centerIn: parent
                sourceComponent: root.lead
            }

            Icon {
                anchors.centerIn: parent
                visible: root.lead === null && root.icon !== ""
                name: root.icon
                size: root.flat ? 20 : 22
                filled: root.active
                color: parent.square ? "white" : root.active ? Config.primaryInk : Config.text
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
                color: root.active ? Config.secondaryInk : Config.text
                font.pixelSize: Config.body + 1
                font.weight: Font.Medium
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: root.subtitle
                elide: Text.ElideRight
                color: root.active ? Config.mix(Config.secondaryInk, Config.secondary, 0.25) : Config.label2
                font.pixelSize: Config.small + 1
            }
        }

        Label {
            visible: text !== ""
            text: root.trailing
            color: Config.label2
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
