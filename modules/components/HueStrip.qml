import QtQuick

// Every hue along a capsule, red to red, with a knob on the one chosen. Drag or click it; Left/Right
// step it when it has the keyboard. The accent's picker (ColourMap) and the surfaces' tint use it.
Item {
    id: root

    property real hue: 0
    signal moved(real hue)

    function clamp(v) { return Math.max(0, Math.min(1, v)) }

    implicitWidth: 320
    implicitHeight: 22
    activeFocusOnTab: true
    Keys.onLeftPressed:  moved(clamp(hue - 1 / 120))
    Keys.onRightPressed: moved(clamp(hue + 1 / 120))

    Rectangle {
        id: hues
        anchors.fill: parent
        radius: height / 2
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0;     color: "#ff0000" }
            GradientStop { position: 1 / 6; color: "#ffff00" }
            GradientStop { position: 2 / 6; color: "#00ff00" }
            GradientStop { position: 3 / 6; color: "#00ffff" }
            GradientStop { position: 4 / 6; color: "#0000ff" }
            GradientStop { position: 5 / 6; color: "#ff00ff" }
            GradientStop { position: 1;     color: "#ff0000" }
        }
    }

    Knob {
        // kept inside the rounded ends
        x: root.height / 2 + root.hue * (root.width - root.height) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        color: Qt.hsva(root.hue, 1, 1, 1)
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true

        function set(mouse) { root.moved(root.clamp((mouse.x - root.height / 2) / (width - root.height))) }
        onPressed: mouse => { root.forceActiveFocus(); set(mouse) }
        onPositionChanged: mouse => { if (pressed) set(mouse) }
    }

    FocusRing { target: hues; on: root.activeFocus && Config.focusVisible }
}
