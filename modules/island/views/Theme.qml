import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// Every colour choice in one place, top to bottom: light or dark, where the colours come from, then
// what to adjust for that source. Each bar is drawn in the colours it gives (ColourBar), so it says what
// it does. The full picker for a custom colour is Colours.
Item {
    id: root

    readonly property int pad: 24
    readonly property int contentW: 840
    readonly property int thumbW: 200
    readonly property int thumbH: 125
    readonly property int gap: 12
    readonly property int labelW: 150

    readonly property bool custom: Config.source === "accent"
    readonly property bool wallpaper: Config.source === "wallpaper"
    readonly property bool generated: Config.source !== "preset"

    // The custom colour as its bars hold it (HSV), apart from Config.accent: grey forgets its hue,
    // black its saturation too, and a knob mustn't jump when it gets there (as in Colours).
    property real hue: 0
    property real saturation: 1
    property real value: 1
    function loadAccent() {
        const c = Config.accent
        if (c.hsvHue >= 0) hue = c.hsvHue
        if (c.hsvValue > 0) saturation = c.hsvSaturation
        value = c.hsvValue
    }
    function setAccent() { Config.accent = Qt.hsva(hue, saturation, value, 1); Engine.key() }
    Component.onCompleted: loadAccent()
    Connections {
        target: Config
        function onAccentChanged() {
            if (Config.hex(Config.accent) !== Config.hex(Qt.hsva(root.hue, root.saturation, root.value, 1))) root.loadAccent()
        }
    }

    // ten even steps round the wheel, and the recent ones after
    readonly property var quick: [0, 0.07, 0.12, 0.3, 0.45, 0.53, 0.6, 0.7, 0.78, 0.9].map(h => Qt.hsla(h, 0.65, 0.62, 1))
    // the wallpaper's primary hue, which its two bars are drawn in
    readonly property real seedHue: Math.max(0, Config.wallpaperSeed.hslHue)
    readonly property real surfaceHueShown: root.custom && Config.surfaceFollows ? Math.max(0, Config.accent.hslHue) : Config.surfaceHue

    implicitWidth: contentW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    // a bar with its name and value: what Theme adjusts, each in the colours it gives
    component Adjust: Item {
        id: adjust
        property string text: ""
        property string valueText: Math.round(bar.value * 100) + "%"
        property alias value: bar.value
        property alias colourAt: bar.colourAt
        signal moved(real value)
        width: parent.width
        height: 32

        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: root.labelW
            text: adjust.text
            color: Config.dim
        }
        ColourBar {
            id: bar
            anchors { left: parent.left; leftMargin: root.labelW; right: shown.left; rightMargin: Config.spaceL; verticalCenter: parent.verticalCenter }
            title: adjust.text
            onMoved: v => adjust.moved(v)
        }
        Label {
            id: shown
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: 48
            horizontalAlignment: Text.AlignRight
            text: adjust.valueText
            font.features: { "tnum": 1 }
        }
    }

    component Section: Item {
        id: section
        property string title: ""
        property string letter: ""                  // the arrow's shortcut
        property int view: -1
        property string action: ""
        width: parent.width
        height: 40

        SectionLabel {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            text: section.title
        }
        Pill {
            visible: section.view >= 0
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            implicitHeight: 40
            kind: "text"
            text: section.action
            icon: Config.symbol.open
            shortcut: section.letter
            onClicked: Engine.open(section.view)
        }
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.contentW
        spacing: Config.spaceM

        Header {
            width: parent.width
            icon: Config.symbol.theme
            title: "Theme"
            subtitle: (root.custom ? "Custom colour " + Config.hex(Config.accent)
                     : root.wallpaper ? "From the wallpaper" + (Wallpaper.option ? ", " + Wallpaper.option.name : "")
                     : Config.current.label)
                    + (Config.contrastLevel === "high" ? "  ·  High contrast" : "")
            onBack: Engine.back()

            Pill {
                icon: Config.symbol.settings
                implicitHeight: 48
                Accessible.name: "Settings"
                onClicked: Engine.open(Engine.View.Settings)
            }
        }

        Row {
            width: parent.width
            spacing: Config.spaceM
            readonly property real each: (width - spacing) / 2

            Segmented {
                width: parent.each
                options: [{ key: "dark", label: "Dark", icon: "dark_mode", shortcut: "d" },
                          { key: "light", label: "Light", icon: "light_mode", shortcut: "l" }]
                current: Config.dark ? "dark" : "light"
                onPicked: key => Config.setDark(key === "dark")
            }
            Segmented {
                width: parent.each
                options: [{ key: "standard", label: "Standard", icon: "contrast" },
                          { key: "high", label: "High contrast", icon: "visibility", shortcut: "h" }]
                current: Config.contrastLevel
                onPicked: key => Config.contrastLevel = key
            }
        }

        SectionLabel { text: "Colours from"; topPadding: Config.spaceS }
        Segmented {
            width: parent.width
            options: [{ key: "wallpaper", label: "Wallpaper", icon: Config.symbol.wallpaper },
                      { key: "accent", label: "Custom colour", icon: "colorize" },
                      { key: "preset", label: "Presets", icon: "palette" }]
            current: Config.source
            onPicked: key => Config.source = key
        }

        // what the picture offers (Wallpaper.options): each circle the whole scheme it makes
        Row {
            visible: root.wallpaper
            width: parent.width
            spacing: Config.spaceL

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
                spacing: Config.spaceL

                Repeater {
                    model: Wallpaper.options

                    Column {
                        id: option
                        required property var modelData
                        required property int index
                        spacing: Config.spaceS

                        PaletteDot {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 48; height: 48
                            palette: Config.wallpaperScheme(option.modelData)
                            chosen: Wallpaper.optionIndex === option.index
                            focus: chosen && root.wallpaper
                            onPicked: {
                                Wallpaper.pick(option.index)
                                Config.takeSurface(Wallpaper.option, Wallpaper.optionKey, true)
                                Engine.key()
                            }
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: option.modelData.name
                            color: Wallpaper.optionIndex === option.index ? Config.text : Config.dim
                            font.pixelSize: Config.small
                        }
                    }
                }
                Label {
                    visible: Wallpaper.options.length === 0
                    text: "No wallpaper colours yet"
                    color: Config.dim
                }
            }
        }

        // ten to start from, the recent ones, and the full picker
        Flow {
            visible: root.custom
            width: parent.width
            spacing: Config.spaceS

            Repeater {
                model: root.quick.concat(Config.recentAccents.filter(c => !root.quick.some(q => Config.hex(q) === c)))

                Swatch {
                    required property var modelData
                    width: 40; height: 40
                    tone: modelData
                    chosen: Config.hex(Config.accent) === Config.hex(modelData)
                    focus: chosen && root.custom
                    onPicked: { Config.accent = modelData; Config.remember(Config.accent); Engine.key() }
                }
            }
            Pill {
                implicitHeight: 40
                kind: "text"
                icon: "colorize"
                text: "More colours"
                shortcut: "c"
                onClicked: Engine.open(Engine.View.Colours)
            }
        }

        Grid {
            visible: Config.source === "preset"
            columns: 4
            spacing: Config.spaceM

            Repeater {
                model: Config.names

                Tile {
                    id: card
                    required property string modelData
                    readonly property var p: Config.palettes[modelData]

                    width: (column.width - 3 * Config.spaceM) / 4
                    height: 88
                    padding: Config.spaceL
                    tint: p.surface
                    current: Config.name === modelData
                    // a hairline, so a palette as dark as the island still has an edge
                    border.width: current ? 2 : 1
                    border.color: current ? Config.primary : Config.divider
                    focus: current && Config.source === "preset"
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
                                width: 22; height: 22; radius: 11
                                color: modelData
                                border.width: 2
                                border.color: card.p.surface
                            }
                        }
                    }
                }
            }
        }

        // The bars for the source in use. The accent's and the wallpaper's are sampled through
        // Config.readable, as the primary is: the colours the island will really draw.
        Column {
            visible: root.generated
            width: parent.width
            spacing: Config.spaceS
            topPadding: Config.spaceS

            Adjust {
                visible: root.custom
                text: "Hue"
                valueText: Math.round(root.hue * 360) + "°"
                value: root.hue
                colourAt: t => Qt.hsva(t, 1, 1, 1)
                onMoved: v => { root.hue = v; root.setAccent() }
            }
            Adjust {
                text: "Colourfulness"
                value: root.custom ? root.saturation : Config.wallpaperSaturation
                colourAt: t => root.custom ? Config.readable(Qt.hsva(root.hue, t, root.value, 1), Config.surface, Config.dark)
                                           : Config.readable(Qt.hsla(root.seedHue, t, Config.wallpaperLightness, 1), Config.surface, Config.dark)
                onMoved: v => {
                    if (root.custom) { root.saturation = v; root.setAccent() }
                    else { Config.wallpaperSaturation = v; Engine.key() }
                }
            }
            Adjust {
                text: "Brightness"
                value: root.custom ? root.value : Config.wallpaperLightness
                colourAt: t => root.custom ? Config.readable(Qt.hsva(root.hue, root.saturation, t, 1), Config.surface, Config.dark)
                                           : Config.readable(Qt.hsla(root.seedHue, Config.wallpaperSaturation, t, 1), Config.surface, Config.dark)
                onMoved: v => {
                    if (root.custom) { root.value = v; root.setAccent() }
                    else { Config.setWallpaperLightness(v); Engine.key() }
                }
            }

            // the surfaces: the accent's hue (Android's way), a hue of their own, or grey
            Item {
                visible: root.custom
                width: parent.width
                height: 48

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Surfaces"
                    color: Config.dim
                }
                Segmented {
                    anchors { left: parent.left; leftMargin: root.labelW; right: parent.right; verticalCenter: parent.verticalCenter }
                    options: [{ key: "matched", label: "Match the colour" }, { key: "custom", label: "Their own hue" }, { key: "neutral", label: "Neutral" }]
                    current: Config.tint === 0 ? "neutral" : Config.surfaceFollows ? "matched" : "custom"
                    onPicked: key => {
                        Config.surfaceFollows = key === "matched"
                        if (key === "neutral") Config.tint = 0
                        else if (Config.tint === 0) Config.tint = 0.5
                    }
                }
            }
            Adjust {
                visible: root.wallpaper || (Config.tint > 0 && !Config.surfaceFollows)
                text: "Surface hue"
                valueText: Math.round(root.surfaceHueShown * 360) + "°"
                value: Config.surfaceHue
                colourAt: t => Qt.hsla(t, 0.55, 0.55, 1)
                onMoved: v => { Config.surfaceHue = v; Engine.key() }
            }
            // drawn in the surfaces' outline role: the lightest of them, so the tint shows in the dark too
            Adjust {
                visible: root.wallpaper || Config.tint > 0
                text: "Surface tint"
                value: Config.tint
                colourAt: t => Config.scheme(Config.current.primary, root.surfaceHueShown, t, Config.dark).outline
                onMoved: v => { Config.tint = v; Engine.key() }
            }
        }

        Section { title: "Wallpaper"; action: "All"; letter: "w"; view: Engine.View.Wallpapers }
        ListView {
            id: strip
            visible: Wallpaper.files.length > 0
            width: parent.width
            height: root.thumbH
            orientation: ListView.Horizontal
            spacing: root.gap
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Wallpaper.files
            currentIndex: Math.max(0, Wallpaper.currentIndex)
            highlightMoveDuration: 0                     // follow the selection at once, not at 400 px/s
            activeFocusOnTab: true
            Component.onCompleted: positionViewAtIndex(currentIndex, ListView.Center)
            // the row moves its own selection with Left/Right (off its ends it lets them go, and
            // ViewLoader moves focus out); report every key, so the countdown restarts
            Keys.onPressed: event => { Engine.key(); event.accepted = false }
            WheelHandler {
                target: null
                onWheel: event => {
                    const d = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
                    strip.contentX = Math.max(strip.originX,
                                     Math.min(strip.originX + strip.contentWidth - strip.width, strip.contentX - d))
                }
            }
            // the current delegate holds the active focus, not the row, so Enter activates the thumb
            delegate: WallpaperThumb {
                required property string modelData
                required property int index
                width: root.thumbW
                height: root.thumbH
                path: modelData
                picked: strip.activeFocus && ListView.isCurrentItem
                onClicked: { strip.currentIndex = index; Wallpaper.set(modelData) }
            }
        }
        Label {
            visible: Wallpaper.files.length === 0
            leftPadding: Config.spaceXs
            text: "No images in " + Wallpaper.dir
            color: Config.dim
        }

        KeyHints {
            width: parent.width
            keys: [["D L", "dark, light"], ["← →", "adjust a bar"], ["C", "more colours"], ["⌫", "back"]]
        }
    }
}
