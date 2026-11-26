import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// Android's Wallpaper & style, grouped the Apple way: what it looks like, light or dark, where the colours
// come from as one row of whole schemes, then the fine-tuning for that source. Every circle is the scheme
// it would really make (through Config.readable, as the island draws it), and the view says when colours
// set by hand in Colours win over all of it.
Item {
    id: root

    readonly property int pad: 24
    readonly property int contentW: 820
    readonly property int labelW: 132

    readonly property bool custom: Config.source === "accent"
    readonly property bool wallpaper: Config.source === "wallpaper"
    readonly property bool generated: Config.source !== "preset"
    // the roles Colours set by hand for the mode showing: they override whatever is picked here
    readonly property int overrides: Object.values(Config.dark ? Config.rolesDark : Config.rolesLight).filter(v => v !== "" && v !== undefined).length

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

    // the colour in use first (it is always there to see), ten even steps round the wheel, then the recent ones
    readonly property var quickNames: ["Red", "Orange", "Amber", "Green", "Mint", "Cyan", "Blue", "Indigo", "Violet", "Pink"]
    readonly property var quick: [0, 0.07, 0.12, 0.3, 0.45, 0.53, 0.6, 0.7, 0.78, 0.9].map(h => Qt.hsla(h, 0.65, 0.62, 1))
    readonly property var customChoices: {
        const all = quick.map((c, i) => ({ colour: c, name: quickNames[i] }))
        const seen = all.map(q => Config.hex(q.colour))
        const add = (h, name) => { if (!seen.includes(h)) { seen.push(h); all.push({ colour: Qt.color(h), name: name }) } }
        add(Config.hex(Config.accent), "Yours")
        Config.recentAccents.forEach(h => add(h, h.toUpperCase()))
        const yours = all.findIndex(c => c.name === "Yours")
        if (yours > 0) all.unshift(all.splice(yours, 1)[0])
        return all.slice(0, 11)     // and Other: twelve to a row
    }
    function customScheme(c) {
        return Config.scheme(c, Config.surfaceFollows ? Math.max(0, c.hslHue) : Config.surfaceHue, Config.tint, Config.dark)
    }
    readonly property real seedHue: Math.max(0, Config.wallpaperSeed.hslHue)
    readonly property real surfaceHueShown: root.custom && Config.surfaceFollows ? Math.max(0, Config.accent.hslHue) : Config.surfaceHue

    implicitWidth: contentW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    // a scheme to pick, named under its circle
    component Choice: Column {
        id: choice
        property var scheme: null
        property string name: ""
        property bool chosen: false
        signal picked()
        width: 62
        spacing: Config.spaceXs

        PaletteDot {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 52; height: 52
            palette: choice.scheme
            chosen: choice.chosen
            focus: choice.chosen
            Accessible.name: choice.name
            onPicked: { choice.picked(); Engine.key() }
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: choice.name
            color: choice.chosen ? Config.text : Config.dim
            font.pixelSize: Config.small
            font.weight: choice.chosen ? Font.DemiBold : Font.Normal
        }
    }

    // a bar with its name and value, drawn in the colours it gives
    component Adjust: Item {
        id: adjust
        property string text: ""
        property string valueText: Math.round(bar.value * 100) + "%"
        property alias value: bar.value
        property alias colourAt: bar.colourAt
        signal moved(real value)
        width: parent.width
        height: 28

        Label {
            anchors { left: parent.left; leftMargin: Config.spaceXs; verticalCenter: parent.verticalCenter }
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
            anchors { right: parent.right; rightMargin: Config.spaceXs; verticalCenter: parent.verticalCenter }
            width: 48
            horizontalAlignment: Text.AlignRight
            text: adjust.valueText
            font.features: { "tnum": 1 }
        }
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.contentW
        spacing: Config.spaceS

        Header {
            width: parent.width
            icon: Config.symbol.theme
            title: "Theme"
            subtitle: (root.custom ? "Custom colour " + Config.hex(Config.accent)
                     : root.wallpaper ? "From the wallpaper" + (Wallpaper.option ? ", " + Wallpaper.option.name : "")
                     : Config.current.label)
                    + (Config.contrastLevel === "high" ? "  ·  High contrast" : "")
                    + (root.overrides > 0 ? "  ·  " + root.overrides + " set by hand" : "")
            onBack: Engine.back()

            Pill {
                icon: Config.symbol.settings
                Accessible.name: "Settings"
                onClicked: Engine.open(Engine.View.Settings)
            }
        }

        // Light or dark, each drawn as it will look (the scheme of that mode, for the colours picked
        // now), and how strongly things stand apart.
        Card {
            title: "Appearance"

            Row {
                width: parent.width
                spacing: Config.spaceS

                Row {
                    width: (parent.width - Config.spaceS) * 0.62
                    spacing: Config.spaceS

                    Repeater {
                        model: [{ dark: true, label: "Dark", shortcut: "d" }, { dark: false, label: "Light", shortcut: "l" }]

                        Tile {
                            id: mode
                            required property var modelData
                            readonly property var p: Config.paletteFor(modelData.dark)
                            width: (parent.width - Config.spaceS) / 2
                            height: 76
                            padding: Config.spaceM
                            shortcut: modelData.shortcut
                            tint: p.surface
                            current: Config.dark === modelData.dark
                            border.width: current ? 2 : 1
                            border.color: current ? Config.primary : Config.divider
                            Accessible.name: modelData.label
                            onClicked: Config.setDark(modelData.dark)

                            Label {
                                anchors { left: parent.left; top: parent.top }
                                text: mode.modelData.label
                                color: mode.p.text
                                font.weight: Font.DemiBold
                            }
                            // a little panel in that mode: a tile with a line of text, a switch in the accent
                            Rectangle {
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                width: 96; height: 36; radius: 18
                                color: mode.p.container
                                Rectangle { x: 12; anchors.verticalCenter: parent.verticalCenter; width: 28; height: 6; radius: 3; color: mode.p.dim }
                                Rectangle {
                                    anchors { right: parent.right; rightMargin: Config.spaceS; verticalCenter: parent.verticalCenter }
                                    width: 36; height: 20; radius: 10
                                    color: mode.p.primary
                                    Rectangle { x: 19; y: 3; width: 14; height: 14; radius: 7; color: mode.p.onPrimary }
                                }
                            }
                            Row {
                                anchors { left: parent.left; bottom: parent.bottom }
                                spacing: Config.spaceXs
                                Repeater {
                                    model: [mode.p.primary, mode.p.secondary, mode.p.high]
                                    Rectangle { required property color modelData; width: 14; height: 14; radius: 7; color: modelData }
                                }
                            }
                        }
                    }
                }
                // how strongly things stand apart
                Segmented {
                    width: (parent.width - Config.spaceS) * 0.38
                    height: 76
                    options: [{ key: "standard", label: "Standard", icon: "contrast" },
                              { key: "high", label: "High", icon: "visibility", shortcut: "h" }]
                    current: Config.contrastLevel
                    onPicked: key => Config.contrastLevel = key
                }
            }
        }

        // Every source the same way: a row of the schemes it offers, and Other for any colour at all
        Card {
            title: "Colours"
            action: "Every colour"
            actionShortcut: "c"
            onActionClicked: Engine.open(Engine.View.Colours)

            Segmented {
                width: parent.width
                options: [{ key: "wallpaper", label: "Wallpaper", icon: Config.symbol.wallpaper, shortcut: "w" },
                          { key: "accent", label: "Custom", icon: "colorize", shortcut: "u" },
                          { key: "preset", label: "Presets", icon: "palette", shortcut: "p" }]
                current: Config.source
                onPicked: key => Config.source = key
            }

            Flow {
                width: parent.width
                spacing: Config.spaceXs
                topPadding: Config.spaceXs

                Repeater {
                    model: root.wallpaper ? Wallpaper.options : []
                    Choice {
                        required property var modelData
                        required property int index
                        scheme: Config.wallpaperScheme(modelData)
                        name: modelData.name
                        chosen: Wallpaper.optionIndex === index
                        onPicked: {
                            Wallpaper.pick(index)
                            Config.takeSurface(Wallpaper.option, Wallpaper.optionKey, true)
                        }
                    }
                }
                Repeater {
                    model: root.custom ? root.customChoices : []
                    Choice {
                        required property var modelData
                        scheme: root.customScheme(modelData.colour)
                        name: modelData.name
                        chosen: Config.hex(Config.accent) === Config.hex(modelData.colour)
                        onPicked: { Config.accent = modelData.colour; Config.remember(Config.accent) }
                    }
                }
                Repeater {
                    model: root.generated ? [] : Config.names
                    Choice {
                        required property string modelData
                        scheme: Config.palettes[modelData]
                        name: Config.palettes[modelData].label
                        chosen: Config.name === modelData
                        onPicked: Config.name = modelData
                    }
                }

                // any colour: the full picker, where the custom colour and every role are set
                Column {
                    visible: !root.wallpaper || Wallpaper.options.length > 0
                    width: 62
                    spacing: Config.spaceXs
                    Pill {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitHeight: 52
                        icon: "add"
                        iconSize: 24
                        Accessible.name: "Other colours"
                        onClicked: { if (!root.custom) Config.source = "accent"; Engine.open(Engine.View.Colours) }
                    }
                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: "Other"
                        color: Config.dim
                        font.pixelSize: Config.small
                    }
                }
            }
            EmptyState {
                visible: root.wallpaper && Wallpaper.options.length === 0
                width: parent.width
                compact: true
                icon: Config.symbol.wallpaper
                title: "No colours from this wallpaper yet"
                hint: "They are read once the picture has loaded"
                color: Config.raised
            }

            // honest about what wins: a role set by hand is drawn as set, whatever is picked above
            Rectangle {
                visible: root.overrides > 0
                width: parent.width
                height: 44
                radius: height / 2
                color: Config.raised
                Row {
                    anchors { left: parent.left; leftMargin: Config.spaceL; verticalCenter: parent.verticalCenter }
                    spacing: Config.spaceS
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "info"; size: 18; color: Config.primary }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.overrides + (root.overrides === 1 ? " colour is" : " colours are")
                              + " set by hand for " + (Config.dark ? "dark" : "light") + " and drawn as set, over what is picked here"
                        font.pixelSize: Config.small + 1
                    }
                }
            }
        }

        // The bars for the source in use, sampled through Config.readable as the primary is
        Card {
            visible: root.generated
            title: root.custom ? "Fine-tune the colour" : "Fine-tune the wallpaper's colour"

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

            // the surfaces: the colour's hue (Android's way), a hue of their own, or grey
            Item {
                visible: root.custom
                width: parent.width
                height: 48

                Label {
                    anchors { left: parent.left; leftMargin: Config.spaceXs; verticalCenter: parent.verticalCenter }
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

        Card {
            title: "Wallpaper"
            action: "All"
            actionShortcut: "a"
            onActionClicked: Engine.open(Engine.View.Wallpapers)

            ListView {
                id: strip
                visible: Wallpaper.files.length > 0
                width: parent.width
                height: 88
                orientation: ListView.Horizontal
                spacing: Config.spaceS
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
                    width: 140
                    height: 88
                    path: modelData
                    picked: strip.activeFocus && ListView.isCurrentItem
                    onClicked: { strip.currentIndex = index; Wallpaper.set(modelData) }
                }
            }
            EmptyState {
                visible: Wallpaper.files.length === 0
                width: parent.width
                compact: true
                icon: Config.symbol.wallpaper
                title: "No images in " + Wallpaper.dir
                color: Config.raised
            }
        }

        KeyHints {
            width: parent.width
            keys: [["D L", "dark, light"], ["W U P", "source"], ["← →", "adjust a bar"], ["⌫", "back"]]
        }
    }
}
