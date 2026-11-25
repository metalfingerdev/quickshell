import QtQuick

Rectangle {
    id: root

    property var options: []
    property string current: ""
    property bool showCheck: true
    signal picked(string key)

    implicitWidth: 320
    implicitHeight: 48
    radius: height / 2
    // a tonal track and one thumb that slides to the chosen one: Material's connected button group, with Apple's motion
    color: Config.fill2
    readonly property int chosenIndex: options.findIndex(o => o.key === current)

    Rectangle {
        visible: root.chosenIndex >= 0
        y: Config.spaceHair + 1
        height: parent.height - 2 * (Config.spaceHair + 1)
        width: (root.width - 2 * (Config.spaceHair + 1)) / Math.max(1, root.options.length)
        x: Config.spaceHair + 1 + Math.max(0, root.chosenIndex) * width
        radius: height / 2
        color: Config.secondary
        Behavior on x { NumberAnimation { duration: Config.durationMedium; easing.type: Easing.OutCubic } }
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: root.options

            Rectangle {
                id: segment
                required property var modelData
                required property int index
                readonly property bool chosen: modelData.key === root.current
                readonly property string shortcut: modelData.shortcut ?? ""
                readonly property bool ring: activeFocus && Config.focusVisible

                function activate() { root.picked(modelData.key) }
                Accessible.role: Accessible.RadioButton
                Accessible.name: modelData.label ?? Config.spoken(modelData.icon)
                Accessible.checked: chosen
                Accessible.onPressAction: activate()

                width: root.width / Math.max(1, root.options.length)
                height: root.height
                radius: root.radius
                color: ring || area.pressed ? Config.fill1 : "transparent"

                activeFocusOnTab: true

                Row {
                    anchors.centerIn: parent
                    spacing: Config.spaceS

                    Icon {
                        readonly property string glyph: segment.modelData.icon ?? ""
                        visible: glyph !== ""
                        anchors.verticalCenter: parent.verticalCenter
                        name: glyph
                        size: 20
                        color: segment.chosen ? Config.secondaryInk : Config.label2
                    }
                    Label {
                        visible: text !== ""                 // an icon-only option stays centred
                        anchors.verticalCenter: parent.verticalCenter
                        text: segment.modelData.label ?? ""
                        color: segment.chosen ? Config.secondaryInk : Config.label2
                        font.weight: segment.chosen ? Font.DemiBold : Font.Medium
                    }
                }

                ClickArea {
                    id: area
                    onClicked: segment.activate()
                }

                // inside the segment: it touches its neighbours
                Rectangle {
                    anchors { fill: parent; margins: Config.spaceXs }
                    visible: segment.ring
                    radius: segment.radius - 4
                    color: "transparent"
                    border.width: 3
                    border.color: Config.primary
                }
                KeyBadge { key: segment.shortcut; anchors { rightMargin: Config.spaceS; topMargin: -8 } }
            }
        }
    }
}
