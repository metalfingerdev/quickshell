import QtQuick

// The usual colour picker: a square of the hue's saturation (across) and brightness (up), over a strip
// of every hue. HSV, so both are exact gradients: the hue, washed to white leftwards and darkened to
// black downwards. Each is its own stop for the keyboard: arrows move in the square, Left/Right on the
// strip; Tab goes from one to the other.
FocusScope {
    id: root

    property real hue: 0
    property real saturation: 1
    property real value: 1
    property int stripHeight: 22

    signal moved(real hue, real saturation, real value)

    function clamp(v) { return Math.max(0, Math.min(1, v)) }

    implicitWidth: 480
    implicitHeight: 240

    Item {
        id: square
        width: parent.width
        height: parent.height - root.stripHeight - 12
        focus: true
        activeFocusOnTab: true
        Keys.onLeftPressed:  root.moved(root.hue, root.clamp(root.saturation - 0.02), root.value)
        Keys.onRightPressed: root.moved(root.hue, root.clamp(root.saturation + 0.02), root.value)
        Keys.onUpPressed:    root.moved(root.hue, root.saturation, root.clamp(root.value + 0.02))
        Keys.onDownPressed:  root.moved(root.hue, root.saturation, root.clamp(root.value - 0.02))

        Rectangle {
            id: field
            anchors.fill: parent
            radius: Config.innerRadius
            color: Qt.hsva(root.hue, 1, 1, 1)
        }
        Rectangle {
            anchors.fill: parent
            radius: field.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#ffffffff" }
                GradientStop { position: 1; color: "#00ffffff" }
            }
        }
        Rectangle {
            anchors.fill: parent
            radius: field.radius
            gradient: Gradient {
                GradientStop { position: 0; color: "#00000000" }
                GradientStop { position: 1; color: "#ff000000" }
            }
        }

        Knob {
            x: root.saturation * square.width - width / 2
            y: (1 - root.value) * square.height - height / 2
            color: Qt.hsva(root.hue, root.saturation, root.value, 1)
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.CrossCursor
            preventStealing: true

            function set(mouse) { root.moved(root.hue, root.clamp(mouse.x / width), root.clamp(1 - mouse.y / height)) }
            onPressed: mouse => { square.forceActiveFocus(); set(mouse) }
            onPositionChanged: mouse => { if (pressed) set(mouse) }
        }

        FocusRing { target: field; on: square.activeFocus && Config.focusVisible }
    }

    HueStrip {
        y: square.height + 12
        width: parent.width
        height: root.stripHeight
        hue: root.hue
        onMoved: h => root.moved(h, root.saturation, root.value)
    }
}
