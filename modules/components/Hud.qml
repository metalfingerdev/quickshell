import QtQuick

// The macOS HUD in a toast: a symbol and a thin track, the number only while the keyboard is in use (the
// toast shows what a key did, and a number answers "how much"). The wheel over it steps the value.
Item {
    id: root

    property string icon: ""
    property real value: 0          // 0..1
    property string valueText: Math.round(value * 100) + "%"
    property color tone: Config.text
    signal stepped(int direction)

    implicitWidth: 280
    implicitHeight: 52

    Icon {
        id: glyph
        x: Config.spaceL
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: 24
        color: root.tone
    }

    Rectangle {
        anchors { left: glyph.right; leftMargin: Config.spaceM; right: number.left; rightMargin: Config.spaceM; verticalCenter: parent.verticalCenter }
        height: 4
        radius: 2
        color: Config.fill1

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: 2
            color: root.tone
            Behavior on width { NumberAnimation { duration: Config.durationFast } }
        }
    }

    Label {
        id: number
        anchors { right: parent.right; rightMargin: Config.spaceL; verticalCenter: parent.verticalCenter }
        width: Config.focusVisible ? 44 : 0
        visible: Config.focusVisible
        horizontalAlignment: Text.AlignRight
        text: root.valueText
        color: Config.label2
        font.features: { "tnum": 1 }
    }

    WheelHandler {
        onWheel: event => root.stepped(event.angleDelta.y > 0 ? 1 : -1)
    }
}
