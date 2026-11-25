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
    implicitWidth: 51
    implicitHeight: 31
    opacity: enabled ? 1 : 0.38

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Config.primary : Config.fill1
        Behavior on color { ColorAnimation { duration: Config.durationMedium } }

        FocusRing { on: root.activeFocus }

        Rectangle {
            readonly property real size: track.height - 4
            width: area.pressed ? size + 6 : size
            height: size
            radius: height / 2
            y: 2
            x: root.checked ? track.width - width - 2 : 2
            color: "white"
            Behavior on x { NumberAnimation { duration: Config.durationMedium; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: Config.durationFast } }
        }
    }

    ClickArea {
        id: area
        onClicked: root.activate()
    }
}
