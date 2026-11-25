import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// A custom colour, in full: the map, a hex code, the eyedropper and the recent ones. Theme has the rest
// (where the colours come from, the bars, the surfaces); choosing a colour here makes it the source.
Item {
    id: root

    readonly property int pad: 24
    readonly property int contentW: 780
    readonly property bool accent: true

    // The accent as the picker holds it (HSV). Kept apart from Config.accent because a colour forgets:
    // grey has no hue, black no saturation either, and a handle mustn't jump when it gets there.
    property real hue: 0
    property real saturation: 1
    property real value: 1

    function loadAccent() {
        const c = Config.accent
        if (c.hsvHue >= 0) hue = c.hsvHue
        if (c.hsvValue > 0) saturation = c.hsvSaturation
        value = c.hsvValue
    }
    function setAccent() {
        Config.accent = Qt.hsva(hue, saturation, value, 1)
        Config.source = "accent"
        Engine.key()
    }
    Component.onCompleted: loadAccent()
    // what the map was left on goes in Recent, so it's one click away after trying others
    Component.onDestruction: if (accent) Config.remember(Config.accent)
    // it changed elsewhere: the hex field, the eyedropper, Recent, IPC
    Connections {
        target: Config
        function onAccentChanged() {
            if (Config.hex(Config.accent) !== Config.hex(Qt.hsva(root.hue, root.saturation, root.value, 1))) root.loadAccent()
        }
    }

    // What the scheme draws with: the accent, unless it had to be lighter or darker to read (Config.readable).
    readonly property color used: Config.current.primary
    readonly property bool adjusted: accent && Config.hex(used) !== Config.hex(Config.accent)

    // The eyedropper, as Nihil's (hyprpicker): the island lets go of the screen first, since it takes
    // every click while it's open. Triggers brings this view back with the colour picked (or as it
    // was, on Escape): by then this one is gone.
    function pick() { Engine.closeThen(() => Toggles.pickColour()) }

    implicitWidth: contentW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.contentW
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: Config.symbol.colours
            title: "Custom colour"
            subtitle: Config.hex(Config.accent) + (Config.source === "accent" ? "" : "  ·  not in use: choosing one makes it the theme's")
            onBack: Engine.back()
        }

        ColourMap {
            visible: root.accent
            width: parent.width
            height: 250
            focus: root.accent                       // the keyboard starts on the map
            hue: root.hue
            saturation: root.saturation
            value: root.value
            onMoved: (h, s, v) => { root.hue = h; root.saturation = s; root.value = v; root.setAccent() }
        }

        // Recent accents, and, when the one picked wouldn't read on the island, what it's drawn with instead
        Item {
            visible: root.accent && (Config.recentAccents.length > 0 || root.adjusted)
            width: parent.width
            height: 36

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Config.spaceS

                Label {
                    visible: Config.recentAccents.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    rightPadding: Config.spaceXs
                    text: "Recent"
                    color: Config.dim
                }
                Repeater {
                    model: Config.recentAccents

                    Swatch {
                        required property string modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32; height: 32
                        tone: modelData
                        chosen: Config.hex(Config.accent) === modelData
                        onPicked: { Config.accent = modelData; Config.source = "accent"; Engine.key() }
                    }
                }
            }

            Row {
                visible: root.adjusted
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: Config.spaceS

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20; height: 20; radius: 10
                    color: Config.accent
                    border.width: 1
                    border.color: Config.outline
                }
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: "arrow_forward"
                    size: 16
                    color: Config.dim
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20; height: 20; radius: 10
                    color: root.used
                    border.width: 1
                    border.color: Config.outline
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: (Config.dark ? "Lighter" : "Darker") + ", to read on the island"
                    color: Config.dim
                }
            }
        }

        Row {
            width: parent.width
            spacing: Config.spaceM

            Rectangle {
                visible: root.accent
                width: parent.width - (eyedropper.visible ? eyedropper.width + parent.spacing : 0)
                height: 48
                radius: height / 2
                color: Config.high
                border.width: field.activeFocus ? 2 : 0
                border.color: Config.primary

                Rectangle {
                    id: badge
                    x: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.height - 12
                    height: width
                    radius: width / 2
                    color: field.digits.length === 6 ? "#" + field.digits : Config.accent
                    border.width: 1
                    border.color: Config.outline
                }

                TextInput {
                    id: field
                    anchors { left: badge.right; leftMargin: Config.spaceM; right: parent.right; rightMargin: Config.spaceXl; top: parent.top; bottom: parent.bottom }
                    verticalAlignment: TextInput.AlignVCenter
                    activeFocusOnTab: true
                    color: Config.text
                    font.family: Config.mono
                    font.pixelSize: Config.body + 1
                    maximumLength: 7
                    validator: RegularExpressionValidator { regularExpression: /#?[0-9A-Fa-f]{0,6}/ }
                    clip: true

                    readonly property string digits: text.replace("#", "")
                    function apply() {
                        if (digits.length !== 6) return
                        Config.accent = "#" + digits
                        Config.source = "accent"
                        Config.remember(Config.accent)
                        text = ""
                    }
                    // the field accepts its keys, so ViewLoader never sees them: report them here
                    Keys.onPressed: event => { Engine.key(); event.accepted = false }
                    Keys.onReturnPressed: apply()
                    Keys.onEnterPressed:  apply()

                    Text {
                        visible: field.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: Config.hex(Config.accent)
                        color: Config.dim
                        font: field.font
                    }
                }
            }
            Pill {
                id: eyedropper
                visible: root.accent && Toggles.has("hyprpicker")
                implicitHeight: 48
                icon: "colorize"
                text: "Pick"
                shortcut: "e"
                onClicked: root.pick()
            }
        }

        KeyHints {
            width: parent.width
            keys: [["← → ↑ ↓", "saturation, brightness"], ["Tab", "the hue, then on"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
