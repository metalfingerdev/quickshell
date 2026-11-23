import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

Item {
    id: root

    readonly property int pad: 24
    readonly property int contentW: 780
    readonly property bool generated: Config.source !== "preset"
    readonly property bool accent: Config.source === "accent"
    readonly property bool wallpaper: Config.source === "wallpaper"

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

    component Level: Slider {
        id: level
        property string title: ""
        valueText: title + "  " + Math.round(level.shown * 100) + "%"
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.contentW
        spacing: 14

        Header {
            width: parent.width
            title: "Colours"
            subtitle: Config.source === "preset" ? Config.current.label
                    : root.accent ? "From " + Config.hex(Config.accent) : "From the wallpaper"
            onBack: Engine.back()
        }

        Segmented {
            width: parent.width
            options: [
                { key: "preset",    label: "Presets",   icon: "palette",   shortcut: "p" },
                { key: "accent",    label: "Accent",    icon: "colorize",  shortcut: "a" },
                { key: "wallpaper", label: "Wallpaper", icon: "wallpaper", shortcut: "w" }
            ]
            current: Config.source
            onPicked: key => Config.source = key
        }

        Grid {
            visible: Config.source === "preset"
            columns: 4
            spacing: 12

            Repeater {
                model: Config.names

                Tile {
                    id: card
                    required property string modelData
                    readonly property var p: Config.palettes[modelData]

                    width: (column.width - 36) / 4
                    height: 112
                    padding: 14
                    tint: p.surface
                    current: Config.name === modelData
                    // a hairline, so a palette as dark as the island still has an edge
                    border.width: current ? 2 : 1
                    border.color: current ? Config.primary : Config.divider
                    focus: current && Config.source === "preset"   // the keyboard starts on the palette in use
                    onClicked: Config.name = modelData

                    Label {
                        anchors { left: parent.left; top: parent.top }
                        text: card.p.label
                        color: card.p.text
                        font.weight: Font.DemiBold
                    }
                    Row {
                        anchors { left: parent.left; bottom: parent.bottom }
                        spacing: -6

                        Repeater {
                            model: [card.p.primary, card.p.secondary, card.p.container]

                            Rectangle {
                                required property string modelData
                                width: 24; height: 24; radius: 12
                                color: modelData
                                border.width: 2
                                border.color: card.p.surface
                            }
                        }
                    }
                }
            }
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
                spacing: 8

                Label {
                    visible: Config.recentAccents.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    rightPadding: 4
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
                        onPicked: { Config.accent = modelData; Engine.key() }
                    }
                }
            }

            Row {
                visible: root.adjusted
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 8

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
            visible: root.wallpaper
            width: parent.width
            spacing: 16

            ClippingRectangle {
                width: 176
                height: 110
                radius: Config.innerRadius
                color: Config.container

                CoverImage {
                    source: Wallpaper.current ? Wallpaper.fileUrl(Wallpaper.current) : ""
                    sourceSize: Qt.size(352, 220)
                }
            }
            Flow {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 176 - parent.spacing
                spacing: 10

                Repeater {
                    model: Wallpaper.swatches

                    Swatch {
                        required property color modelData
                        width: 44; height: 44
                        tone: modelData
                        chosen: Config.hex(Wallpaper.seed) === Config.hex(modelData)
                        focus: chosen && root.wallpaper
                        onPicked: Wallpaper.pick(modelData)
                    }
                }
                Label {
                    visible: Wallpaper.swatches.length === 0
                    text: "No wallpaper colours yet"
                    color: Config.dim
                }
            }
        }

        // the accent's saturation is the square's own; the wallpaper's colour gets sliders for it
        Row {
            id: levels
            readonly property real each: (width - (root.wallpaper ? 2 : 0) * spacing) / (root.wallpaper ? 3 : 1)

            visible: root.generated
            width: parent.width
            spacing: 12

            Level {
                visible: root.wallpaper
                width: levels.each
                title: "Saturation"
                icon: "invert_colors"
                value: Config.wallpaperSaturation
                onMoved: v => { Config.wallpaperSaturation = v; Engine.key() }
            }
            Level {
                visible: root.wallpaper
                width: levels.each
                title: "Lightness"
                icon: "brightness_6"
                value: Config.wallpaperLightness
                onMoved: v => { Config.setWallpaperLightness(v); Engine.key() }
            }
            Level {
                width: levels.each
                title: "Surface tint"
                icon: "format_color_fill"
                value: Config.tint
                onMoved: v => { Config.tint = v; Engine.key() }
            }
        }

        Row {
            width: parent.width
            spacing: 12

            Rectangle {
                visible: root.accent
                width: parent.width - mode.width - parent.spacing - (eyedropper.visible ? eyedropper.width + parent.spacing : 0)
                height: mode.height
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
                    anchors { left: badge.right; leftMargin: 12; right: parent.right; rightMargin: 20; top: parent.top; bottom: parent.bottom }
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
                implicitHeight: mode.height
                icon: "colorize"
                text: "Pick"
                shortcut: "e"
                onClicked: root.pick()
            }
            Segmented {
                id: mode
                width: root.accent ? 240 : parent.width
                options: [{ key: "dark", label: "Dark", icon: "dark_mode" }, { key: "light", label: "Light", icon: "light_mode" }]
                current: Config.dark ? "dark" : "light"
                onPicked: key => { Config.setDark(key === "dark"); Toggles.colorScheme(Config.dark) }
            }
        }

        KeyHints {
            width: parent.width
            keys: root.accent ? [["← → ↑ ↓", "saturation, brightness"], ["Tab", "the hue, then on"], ["⌫", "back"], ["Esc", "close"]]
                              : [["⌫", "back"], ["Esc", "close"]]
        }
    }
}
