import QtQuick

// A quantity: a fat pill track (the Control Centre's sliders, in Material 3 Expressive's form), the accent up
// to the value and a handle bar at its end. It moves under the pointer at once (moved) and settles on release
// (committed), so what is costly to apply (Hyprland, the glass) waits for the release. Left/Right step it
// (ViewLoader calls nudge).
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
    implicitHeight: 36
    opacity: enabled ? 1 : 0.38

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Config.fill2

        Rectangle {
            width: Math.max(height / 2, (parent.width - handle.width) * root.shown)
            height: parent.height
            radius: height / 2
            color: Config.primary
            Behavior on width { enabled: !root.dragging; NumberAnimation { duration: Config.durationFast } }
        }
    }
    // the handle: a bar, taller than the track, that widens the pill's end as it's held
    Rectangle {
        id: handle
        width: root.dragging ? 3 : 4; height: parent.height + 8; radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(height / 4, (track.width - width) * root.shown)
        color: Config.primaryDeep
        border.width: 2
        border.color: Config.fill2
        Behavior on width { NumberAnimation { duration: Config.durationFast } }
    }
    FocusRing { target: track; on: root.activeFocus && Config.focusVisible }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        function at(x) { return root.clamp(x / Math.max(1, track.width)) }
        onPressed: mouse => { root.forceActiveFocus(); root.dragValue = at(mouse.x); root.moved(root.dragValue) }
        onPositionChanged: mouse => { if (pressed) { root.dragValue = at(mouse.x); root.moved(root.dragValue) } }
        onReleased: root.committed(root.dragValue)
    }
}
