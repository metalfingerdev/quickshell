import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// Every colour, in full: the custom colour the theme starts from, and each role of the palette, for dark and
// for light apart. A role set here is drawn exactly as set (alpha too), over whatever the theme made, until
// "Use the theme's" gives it back. Theme is where the colours come from; this is where they end up.
Item {
    id: root

    readonly property int pad: 24
    readonly property int contentW: 780
    // which mode's colours are being edited; the one showing, to begin with
    property bool editDark: Config.dark
    property string role: "accent"
    readonly property var palette: Config.paletteFor(editDark)
    readonly property var roles: editDark ? Config.rolesDark : Config.rolesLight
    readonly property bool accent: role === "accent"
    readonly property bool overridden: !accent && roles[role] !== undefined && roles[role] !== ""
    readonly property color shown: colourOf(role)

    readonly property var names: [
        ["accent", "Custom colour"], ["primary", "Accent as drawn"], ["primaryInk", "On the accent"],
        ["surface", "Surface"], ["container", "Container"], ["high", "Raised"], ["highest", "Highest"],
        ["secondary", "Selection"], ["secondaryInk", "On selection"], ["text", "Text"], ["dim", "Secondary text"],
        ["outline", "Outline"], ["good", "Good"], ["warn", "Warning"], ["bad", "Bad"]]
    // the palette's own key for a role (primaryInk is onPrimary there: a property can't be called onX)
    function key(r) { return r === "primaryInk" ? "onPrimary" : r === "secondaryInk" ? "onSecondary" : r }
    // a palette keeps some colours as strings ("#aarrggbb", a preset's hex): Qt.darker(x, 1) is the colour itself
    function colourOf(r) { return r === "accent" ? Config.accent : Qt.darker(palette[key(r)] ?? "transparent", 1) }

    // The colour as the picker holds it (HSV and alpha): a colour forgets its hue in grey, and a knob mustn't
    // jump when it gets there.
    property real hue: 0
    property real saturation: 1
    property real value: 1
    property real alpha: 1
    function load() {
        const c = colourOf(role)
        if (c.hsvHue >= 0) hue = c.hsvHue
        if (c.hsvValue > 0) saturation = c.hsvSaturation
        value = c.hsvValue
        alpha = c.a
    }
    function write(c) {
        Engine.key()
        if (accent) { Config.accent = Qt.rgba(c.r, c.g, c.b, 1); Config.source = "accent"; return }
        const all = Object.assign({}, roles)
        all[key(role)] = Config.argb(c)
        if (editDark) Config.rolesDark = all; else Config.rolesLight = all
    }
    function commit() { write(Qt.hsva(hue, saturation, value, alpha)) }
    function reset() {
        const all = Object.assign({}, roles)
        delete all[key(role)]
        if (editDark) Config.rolesDark = all; else Config.rolesLight = all
        Qt.callLater(load)
    }
    onRoleChanged: load()
    onEditDarkChanged: load()
    Component.onCompleted: load()
    Component.onDestruction: if (accent) Config.remember(Config.accent)

    // the eyedropper (hyprpicker): the island lets go of the screen first; Triggers brings this view back
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
            title: "Colours"
            subtitle: (root.names.find(n => n[0] === root.role)?.[1] ?? root.role) + "  ·  " + Config.hex(root.shown) + (root.accent ? "" : Math.round(root.shown.a * 255).toString(16).padStart(2, "0"))
                      + (root.overridden ? "  ·  set by you" : root.accent ? "" : "  ·  the theme's")
            onBack: Engine.back()

            Pill {
                visible: Toggles.has("hyprpicker") && root.accent
                icon: "colorize"
                text: "Pick from the screen"
                implicitHeight: 48
                shortcut: "e"
                onClicked: root.pick()
            }
        }

        Segmented {
            width: parent.width
            options: [{ key: "dark", label: "Dark colours", icon: "dark_mode" }, { key: "light", label: "Light colours", icon: "light_mode" }]
            current: root.editDark ? "dark" : "light"
            onPicked: key => root.editDark = key === "dark"
        }

        // every role, as a swatch: the ring marks the one being edited, the dot one set by hand
        Grid {
            width: parent.width
            columns: 5
            columnSpacing: Config.spaceS
            rowSpacing: Config.spaceS

            Repeater {
                model: root.names

                Rectangle {
                    id: cell
                    required property var modelData
                    readonly property bool chosen: root.role === modelData[0]
                    readonly property bool set: modelData[0] !== "accent" && root.roles[root.key(modelData[0])] !== undefined
                    readonly property bool keyboardSelected: activeFocus && Config.focusVisible
                    width: (parent.width - 4 * Config.spaceS) / 5
                    height: 52
                    radius: Config.innerRadius
                    color: chosen ? Config.fill1 : Config.state(Config.fill3, Config.text, area.containsMouse, area.pressed || keyboardSelected)
                    activeFocusOnTab: true
                    function activate() { root.role = modelData[0] }
                    Accessible.role: Accessible.RadioButton
                    Accessible.name: modelData[1]
                    Accessible.checked: chosen

                    Rectangle {
                        id: swatch
                        x: Config.spaceS
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28; height: 28; radius: 14
                        color: root.colourOf(cell.modelData[0])
                        border.width: 1
                        border.color: Config.fill1
                    }
                    Label {
                        anchors { left: swatch.right; leftMargin: Config.spaceS; right: parent.right; rightMargin: Config.spaceS; verticalCenter: parent.verticalCenter }
                        text: cell.modelData[1]
                        elide: Text.ElideRight
                        font.pixelSize: Config.small + 1
                        font.weight: cell.chosen ? Font.DemiBold : Font.Normal
                    }
                    Rectangle {
                        visible: cell.set
                        anchors { right: parent.right; top: parent.top; margins: Config.spaceXs }
                        width: 6; height: 6; radius: 3
                        color: Config.primary
                    }
                    ClickArea { id: area; onClicked: cell.activate() }
                    FocusRing { on: cell.keyboardSelected }
                }
            }
        }

        Row {
            width: parent.width
            spacing: Config.spaceL

            ColourMap {
                width: parent.width - side.width - parent.spacing
                height: 260
                hue: root.hue
                saturation: root.saturation
                value: root.value
                onMoved: (h, s, v) => { root.hue = h; root.saturation = s; root.value = v; root.commit() }
            }

            Column {
                id: side
                width: 260
                spacing: Config.spaceM

                // the colour as it will be drawn, on the island's own surface, so its alpha shows
                Rectangle {
                    width: parent.width
                    height: 80
                    radius: Config.innerRadius
                    color: Config.surface
                    Rectangle {
                        anchors { fill: parent; margins: Config.spaceS }
                        radius: Config.innerRadius - Config.spaceS
                        color: root.shown
                        border.width: 1
                        border.color: Config.fill1
                    }
                }

                Label { visible: !root.accent; text: "Opacity"; color: Config.label2 }
                ColourBar {
                    visible: !root.accent
                    width: parent.width
                    title: "Opacity"
                    checker: true
                    value: root.alpha
                    colourAt: t => Qt.hsva(root.hue, root.saturation, root.value, t)
                    onMoved: v => { root.alpha = v; root.commit() }
                }

                Rectangle {
                    width: parent.width
                    height: 44
                    radius: height / 2
                    color: Config.fill3
                    border.width: hex.activeFocus ? 2 : 0
                    border.color: Config.primary

                    TextInput {
                        id: hex
                        anchors { fill: parent; leftMargin: Config.spaceL; rightMargin: Config.spaceL }
                        verticalAlignment: TextInput.AlignVCenter
                        activeFocusOnTab: true
                        color: Config.text
                        font.family: Config.mono
                        font.pixelSize: Config.body + 1
                        maximumLength: 9
                        validator: RegularExpressionValidator { regularExpression: /#?[0-9A-Fa-f]{0,8}/ }
                        clip: true
                        // #rrggbb, or #rrggbbaa with the alpha last, as people write it
                        function apply() {
                            const d = text.replace("#", "")
                            if (d.length !== 6 && d.length !== 8) return
                            const n = i => parseInt(d.substr(i, 2), 16) / 255
                            root.write(Qt.rgba(n(0), n(2), n(4), d.length === 8 ? n(6) : 1))
                            text = ""
                            root.load()
                        }
                        Keys.onPressed: event => { Engine.key(); event.accepted = false }
                        Keys.onReturnPressed: apply()
                        Keys.onEnterPressed: apply()

                        Text {
                            visible: hex.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: Config.hex(root.shown) + (root.accent ? "" : Math.round(root.shown.a * 255).toString(16).padStart(2, "0"))
                            color: Config.label2
                            font: hex.font
                        }
                    }
                }

                Pill {
                    visible: root.overridden
                    width: parent.width
                    icon: "restart_alt"
                    text: "Use the theme's"
                    shortcut: "u"
                    onClicked: root.reset()
                }
                Label {
                    visible: root.accent && Config.keepReadable && Config.hex(Config.current.primary) !== Config.hex(Config.accent)
                    width: parent.width
                    wrapMode: Text.WordWrap
                    text: "Drawn " + (Config.dark ? "lighter" : "darker") + " to read on the island. Turn off “Keep colours readable” in Theme to draw it as picked."
                    color: Config.label2
                    font.pixelSize: Config.small
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["← → ↑ ↓", "saturation, brightness"], ["Tab", "hue, opacity, hex"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
