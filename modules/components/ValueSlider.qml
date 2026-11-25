import QtQuick

// A quantity, as Apple's sliders show one: a thin track, the accent up to the value, a white knob. It moves
// under the pointer at once (moved) and settles on release (committed), so what is costly to apply (Hyprland,
// the glass) waits for the release. Left/Right step it (ViewLoader calls nudge).
Item {
    id: root

    property real value: 0                 // 0..1
    property real step: 0.01
    property string title: ""
    readonly property bool dragging: area.pressed
    property real dragValue: 0
    readonly property real shown: clamp(dragging ? dragValue : value)
    signal moved(real value)
    signal committed(real value)

    function clamp(v) { return isFinite(v) ? Math.max(0, Math.min(1, v)) : 0 }
    function nudge(dir) { const v = clamp(value + dir * step); moved(v); committed(v) }

    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.name: title
    Accessible.description: Math.round(shown * 100) + "%"
    Accessible.onIncreaseAction: nudge(1)
    Accessible.onDecreaseAction: nudge(-1)

    implicitWidth: 240
    implicitHeight: 28
    opacity: enabled ? 1 : 0.38

    Rectangle {
        id: track
        x: knob.width / 2
        width: parent.width - knob.width
        height: 4
        radius: 2
        anchors.verticalCenter: parent.verticalCenter
        color: Config.fill1

        Rectangle { width: parent.width * root.shown; height: parent.height; radius: 2; color: Config.primary }
    }
    Rectangle {
        id: knob
        width: 22; height: 22; radius: 11
        anchors.verticalCenter: parent.verticalCenter
        x: track.width * root.shown
        color: "white"
        border.width: 1
        border.color: Config.fill2
        scale: root.dragging ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: Config.durationFast } }
    }
    FocusRing { target: knob; on: root.activeFocus && Config.focusVisible }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        function at(x) { return root.clamp((x - knob.width / 2) / Math.max(1, track.width)) }
        onPressed: mouse => { root.forceActiveFocus(); root.dragValue = at(mouse.x); root.moved(root.dragValue) }
        onPositionChanged: mouse => { if (pressed) { root.dragValue = at(mouse.x); root.moved(root.dragValue) } }
        onReleased: root.committed(root.dragValue)
    }
}
