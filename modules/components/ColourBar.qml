import QtQuick

// A slider whose track is the colours it gives, so the bar itself says what it does (Theme's colours,
// Settings' opacity): `colourAt(t)` paints it at nine points along (a Repeater can't fill a Gradient),
// and the knob takes the colour under it. `checker` shows see-through colours over a checkerboard.
Item {
    id: root

    property real value: 0
    property var colourAt: t => Qt.hsva(t, 1, 1, 1)
    property bool checker: false
    property real step: 0.02
    property string title: ""
    signal moved(real value)

    function clamp(v) { return Math.max(0, Math.min(1, v)) }
    function nudge(dir) { moved(clamp(value + dir * step)) }

    implicitWidth: 320
    implicitHeight: 24
    activeFocusOnTab: true
    Accessible.role: Accessible.Slider
    Accessible.name: title
    Accessible.description: Math.round(value * 100) + "%"
    Accessible.onIncreaseAction: nudge(1)
    Accessible.onDecreaseAction: nudge(-1)

    Canvas {
        visible: root.checker
        anchors.fill: parent
        onPaint: {
            const g = getContext("2d"), r = height / 2, cell = height / 3
            g.reset()
            g.beginPath()
            g.roundedRect(0, 0, width, height, r, r)
            g.clip()
            for (let x = 0; x * cell < width; x++)
                for (let y = 0; y * cell < height; y++) {
                    g.fillStyle = (x + y) % 2 ? Config.outline : Config.raised
                    g.fillRect(x * cell, y * cell, cell, cell)
                }
        }
        onWidthChanged: requestPaint()
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0;     color: root.colourAt(0) }
            GradientStop { position: 0.125; color: root.colourAt(0.125) }
            GradientStop { position: 0.25;  color: root.colourAt(0.25) }
            GradientStop { position: 0.375; color: root.colourAt(0.375) }
            GradientStop { position: 0.5;   color: root.colourAt(0.5) }
            GradientStop { position: 0.625; color: root.colourAt(0.625) }
            GradientStop { position: 0.75;  color: root.colourAt(0.75) }
            GradientStop { position: 0.875; color: root.colourAt(0.875) }
            GradientStop { position: 1;     color: root.colourAt(1) }
        }
    }

    Knob {
        // kept inside the rounded ends
        x: root.height / 2 + root.clamp(root.value) * (root.width - root.height) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: root.colourAt(root.clamp(root.value))
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function set(mouse) { root.moved(root.clamp((mouse.x - root.height / 2) / (width - root.height))) }
        onPressed: mouse => { root.forceActiveFocus(); set(mouse) }
        onPositionChanged: mouse => { if (pressed) set(mouse) }
    }

    FocusRing { target: track; on: root.activeFocus && Config.focusVisible }
}
