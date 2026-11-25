import QtQuick

// A switch, after iOS's: the accent when on, a fill when off, a round knob that stretches as it is pressed.
// It only reports: bind `checked` to the real state and act in onToggled.
Item {
    id: root

    property bool checked: false
    signal toggled(bool on)

    function activate() { if (enabled) toggled(!checked) }
    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true
    Accessible.checked: checked
    Accessible.onToggleAction: activate()
    Accessible.onPressAction: activate()

    activeFocusOnTab: true
    implicitWidth: 52
    implicitHeight: 32
    opacity: enabled ? 1 : 0.38

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Config.primary : Config.raised
        Behavior on color { ColorAnimation { duration: Config.durationMedium } }

        FocusRing { on: root.activeFocus }

        // Material 3's: a small dim thumb when off, a large one with a check when on, wider while held
        Rectangle {
            property real size: area.pressed ? 28 : root.checked ? 24 : 16
            width: size
            height: size
            radius: size / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? track.width - width - 4 - (24 - Math.min(24, size)) / 2 : 8 - (size - 16) / 2
            color: root.checked ? Config.primaryInk : Config.dim
            Behavior on x { NumberAnimation { duration: Config.durationMedium; easing.type: Easing.OutCubic } }
            Behavior on size { NumberAnimation { duration: Config.durationFast } }
            Behavior on color { ColorAnimation { duration: Config.durationFast } }

            Icon { anchors.centerIn: parent; visible: root.checked; name: "check"; size: 16; color: Config.primary }
        }
    }

    ClickArea {
        id: area
        onClicked: root.activate()
    }
}
