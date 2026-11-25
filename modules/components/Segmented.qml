import QtQuick

// One of a few, as the Control Centre's connected groups: buttons a joint apart, the outer corners of the
// group round and the joints nearly square, the chosen one in the accent and round all over.
Item {
    id: root

    property var options: []
    property string current: ""
    property bool showCheck: true
    signal picked(string key)

    implicitWidth: 320
    implicitHeight: 48
    readonly property int joint: 4

    Row {
        anchors.fill: parent
        spacing: root.joint

        Repeater {
            model: root.options

            Rectangle {
                id: segment
                required property var modelData
                required property int index
                readonly property bool chosen: modelData.key === root.current
                readonly property string shortcut: modelData.shortcut ?? ""
                readonly property bool ring: activeFocus && Config.focusVisible
                readonly property bool first: index === 0
                readonly property bool last: index === root.options.length - 1
                readonly property real round: height / 2
                readonly property color ink: chosen ? Config.primaryInk : Config.text

                function activate() { root.picked(modelData.key) }
                Accessible.role: Accessible.RadioButton
                Accessible.name: modelData.label ?? Config.spoken(modelData.icon)
                Accessible.checked: chosen
                Accessible.onPressAction: activate()
                activeFocusOnTab: true

                width: (root.width - (root.options.length - 1) * root.joint) / Math.max(1, root.options.length)
                height: root.height
                topLeftRadius: first || chosen ? round : 8
                bottomLeftRadius: first || chosen ? round : 8
                topRightRadius: last || chosen ? round : 8
                bottomRightRadius: last || chosen ? round : 8
                Behavior on topLeftRadius { Motion {} }
                Behavior on bottomLeftRadius { Motion {} }
                Behavior on topRightRadius { Motion {} }
                Behavior on bottomRightRadius { Motion {} }
                scale: area.pressed ? 0.96 : 1
                Behavior on scale { NumberAnimation { duration: Config.durationFast; easing.type: Easing.OutCubic } }
                color: Config.state(chosen ? Config.primary : Config.raised, ink, area.containsMouse, area.pressed || ring)
                Behavior on color { ColorAnimation { duration: Config.durationFast } }

                Row {
                    anchors.centerIn: parent
                    spacing: Config.spaceS

                    Icon {
                        readonly property string glyph: segment.modelData.icon ?? ""
                        visible: glyph !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        name: glyph
                        size: 20
                        filled: segment.chosen
                        color: segment.ink
                    }
                    Label {
                        visible: text !== ""                 // an icon-only option stays centred
                        anchors.verticalCenter: parent.verticalCenter
                        text: segment.modelData.label ?? ""
                        color: segment.ink
                        font.weight: Font.Medium
                    }
                }

                ClickArea {
                    id: area
                    onClicked: segment.activate()
                }
                FocusRing { on: segment.ring }
                KeyBadge { key: segment.shortcut; anchors { rightMargin: Config.spaceS; topMargin: -8 } }
            }
        }
    }
}
