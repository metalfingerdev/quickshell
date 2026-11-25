import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.lock
import qs.modules.services

Item {
    id: root

    readonly property int pad: 24
    readonly property int colW: 520
    // "" is the home page: System Settings' list of categories; a category opens its page, and Back comes home
    property string section: ""
    function back() { Engine.key(); if (section !== "") section = ""; else Engine.back() }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Backspace && root.section !== "") { root.back(); event.accepted = true }
        else event.accepted = false
    }

    implicitWidth: colW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    // a tile like a list row's, so a switch reads as one thing with its words rather than floating apart
    component Switch: Rectangle {
        id: line
        property string text: ""
        property alias checked: toggle.checked
        signal toggled(bool on)

        width: parent.width
        height: 56
        radius: Config.innerRadius + 4
        color: Config.fill3

        Label {
            anchors { left: parent.left; leftMargin: Config.spaceL; verticalCenter: parent.verticalCenter }
            text: line.text
            font.pixelSize: Config.body + 1
        }
        Toggle {
            id: toggle
            anchors { right: parent.right; rightMargin: Config.spaceM; verticalCenter: parent.verticalCenter }
            onToggled: on => line.toggled(on)
        }
    }

    // a bar with its name and value above it; Look's opacities are see-through colours, over a checkerboard
    component Level: Column {
        id: level
        property string text: ""
        property string valueText: ""
        property alias value: bar.value
        property alias colourAt: bar.colourAt
        property alias checker: bar.checker
        signal moved(real value)
        width: parent.width
        spacing: Config.spaceS

        Item {
            width: parent.width
            height: name.implicitHeight
            Label { id: name; text: level.text; font.pixelSize: Config.body + 1 }
            Label { anchors.right: parent.right; text: level.valueText; color: Config.dim; font.features: { "tnum": 1 } }
        }
        ColourBar {
            id: bar
            width: parent.width
            title: level.text
            onMoved: v => level.moved(v)
        }
    }
    readonly property color see: Config.surface
    function seeThrough(alpha) { return Qt.rgba(see.r, see.g, see.b, alpha) }

    // the Glass and blur page
    readonly property bool liquid: Glass.available && Glass.enabled
    Component.onCompleted: Glass.readDescriptions()
    function hyprCurrent(key, fallback) { const o = Glass.descriptions.find(d => d.name === key); return o ? Number(o.current) : fallback }
    function hl(key, fallback) { const v = Glass.hl?.shared?.[key]; return v !== undefined ? Number(v) : hyprCurrent(key, fallback) }
    function setHl(key, value) {
        const all = Object.assign({ shared: {}, dark: {}, light: {} }, Glass.hl)
        all.shared = Object.assign({}, all.shared, { [key]: value })
        Glass.hl = all
    }
    readonly property real windowBlurShown: Glass.windowBlur >= 0 ? Glass.windowBlur
        : liquid ? Number(Glass.glassValue("windows", "blur_strength")) / 4 : hyprCurrent("decoration:blur:size", 8) / 16
    // "#rrggbbaa", as hyprglass and the settings keep a colour, to a colour, and back
    function parse(hex) {
        const h = String(hex ?? "").replace("#", "")
        const n = i => parseInt(h.substr(i, 2), 16) / 255
        return h.length >= 6 ? Qt.rgba(n(0), n(2), n(4), h.length >= 8 ? n(6) : 1) : Qt.rgba(0, 0, 0, 0)
    }
    function hexa(c) { return Config.hex(c) + Math.round(c.a * 255).toString(16).padStart(2, "0") }

    // one quantity: its name and value above, the slider across the row
    component Amount: Item {
        id: amount
        property string text: ""
        property real value: 0
        property string valueText: Math.round(slider.shown * 100) + "%"
        signal moved(real value)
        signal committed(real value)
        width: parent ? parent.width : 0
        height: visible ? 72 : 0
        opacity: enabled ? 1 : 0.38

        Rectangle { visible: amount.y > 0.5; x: Config.spaceL; width: parent.width - x; height: 1; color: Config.fill2 }
        Label { x: Config.spaceL; y: Config.spaceM; text: amount.text; font.pixelSize: Config.body + 1 }
        Label {
            anchors { right: parent.right; rightMargin: Config.spaceL }
            y: Config.spaceM
            text: amount.valueText
            color: Config.label2
            font.features: { "tnum": 1 }
        }
        ValueSlider {
            id: slider
            x: Config.spaceM; width: parent.width - 2 * Config.spaceM
            anchors { bottom: parent.bottom; bottomMargin: Config.spaceS }
            title: amount.text
            enabled: amount.enabled
            value: amount.value
            onMoved: v => amount.moved(v)
            onCommitted: v => amount.committed(v)
        }
    }

    // a yes/no in a section
    component SwitchRow: ListEntry {
        id: row
        property bool checked: false
        signal toggled(bool on)
        flat: true
        onClicked: toggled(!checked)
        Toggle { checked: row.checked; activeFocusOnTab: false; onToggled: on => row.toggled(on) }
    }

    // a colour quantity: its name, and a bar drawn in the colours it gives
    component TintBar: Item {
        id: bar
        property string text: ""
        property alias value: colours.value
        property alias colourAt: colours.colourAt
        signal moved(real value)
        width: parent ? parent.width : 0
        height: 56
        Rectangle { x: Config.spaceL; width: parent.width - x; height: 1; color: Config.fill2 }
        Label { x: Config.spaceL; anchors.verticalCenter: parent.verticalCenter; width: 120; text: bar.text; color: Config.label2 }
        ColourBar {
            id: colours
            anchors { left: parent.left; leftMargin: 120 + Config.spaceL; right: parent.right; rightMargin: Config.spaceL; verticalCenter: parent.verticalCenter }
            title: bar.text
            onMoved: v => bar.moved(v)
        }
    }

    // liquid glass's own settings for the island or the windows: the tint in full, the bend and the light
    component GlassAmounts: Column {
        id: glass
        property string which: "windows"
        readonly property color tint: root.parse(Glass.glassValue(which, "tint_color"))
        function setTint(c) { Glass.setGlass(which, "tint_color", root.hexa(c)) }
        width: parent ? parent.width : 0

        Amount {
            text: "Tint"
            value: glass.tint.a
            onCommitted: v => glass.setTint(Qt.rgba(glass.tint.r, glass.tint.g, glass.tint.b, v))
        }
        TintBar {
            text: "Tint hue"
            value: Math.max(0, glass.tint.hslHue)
            colourAt: t => Qt.hsla(t, 0.7, 0.55, 1)
            onMoved: v => glass.setTint(Qt.hsla(v, Math.max(0.01, glass.tint.hslSaturation), glass.tint.hslLightness, glass.tint.a))
        }
        TintBar {
            text: "Tint saturation"
            value: glass.tint.hslSaturation
            colourAt: t => Qt.hsla(Math.max(0, glass.tint.hslHue), t, 0.5, 1)
            onMoved: v => glass.setTint(Qt.hsla(Math.max(0, glass.tint.hslHue), v, glass.tint.hslLightness, glass.tint.a))
        }
        TintBar {
            text: "Tint lightness"
            value: glass.tint.hslLightness
            colourAt: t => Qt.hsla(Math.max(0, glass.tint.hslHue), glass.tint.hslSaturation, t, 1)
            onMoved: v => glass.setTint(Qt.hsla(Math.max(0, glass.tint.hslHue), glass.tint.hslSaturation, v, glass.tint.a))
        }
        Amount {
            text: "Refraction"
            value: Number(Glass.glassValue(glass.which, "refraction_strength")) / 10
            valueText: Number(Glass.glassValue(glass.which, "refraction_strength")).toFixed(1)
            onCommitted: v => Glass.setGlass(glass.which, "refraction_strength", Math.round(v * 100) / 10)
        }
        Amount {
            text: "Highlight"
            value: Number(Glass.glassValue(glass.which, "specular_strength"))
            onCommitted: v => Glass.setGlass(glass.which, "specular_strength", Math.round(v * 100) / 100)
        }
        Amount {
            text: "Edge glow"
            value: Number(Glass.glassValue(glass.which, "fresnel_strength"))
            onCommitted: v => Glass.setGlass(glass.which, "fresnel_strength", Math.round(v * 100) / 100)
        }
        ListEntry {
            flat: true
            icon: "restart_alt"
            title: "Back to the look's own"
            subtitle: "Tint, refraction, highlight and glow as " + (Glass.presets.find(p => p.key === Glass.preset)?.label ?? Glass.preset) + " has them"
            onClicked: Glass.resetGlass(glass.which, ["tint_color", "refraction_strength", "specular_strength", "fresnel_strength", "blur_strength", "blur_iterations"])
        }
    }

    // the waits an idle step can have, in seconds; 0 = never, at the far end of the slider
    readonly property var stops: [30, 60, 120, 180, 300, 600, 900, 1200, 1800, 2700, 3600, 7200, 0]
    function stopOf(seconds) {
        if (seconds <= 0) return stops.length - 1
        let best = 0
        for (let i = 0; i < stops.length - 1; i++)
            if (Math.abs(stops[i] - seconds) < Math.abs(stops[best] - seconds)) best = i
        return best
    }
    function spoken(seconds) {
        if (seconds <= 0) return "Never"
        const h = Math.floor(seconds / 3600), m = Math.floor(seconds % 3600 / 60), s = seconds % 60
        return [h && h + " h", m && m + " min", s && s + " s"].filter(Boolean).join(" ")
    }

    component Delay: Row {
        id: delay
        property string text: ""
        property alias icon: wait.icon
        property int seconds: 0
        signal picked(int seconds)

        width: parent.width
        spacing: Config.spaceM

        Label {
            id: caption
            width: 104
            leftPadding: Config.spaceXs
            anchors.verticalCenter: parent.verticalCenter
            text: delay.text
            font.pixelSize: Config.body + 1
        }
        Slider {
            id: wait
            readonly property int last: root.stops.length - 1
            width: parent.width - caption.width - parent.spacing
            value: root.stopOf(delay.seconds) / last
            // the real value, which may be no stop (the defaults, or one set over IPC)
            valueText: root.spoken(dragging ? root.stops[Math.round(shown * last)] : delay.seconds)
            step: 1 / last
            onCommitted: v => delay.picked(root.stops[Math.round(v * last)])
        }
    }

    // a text field that takes its keys (ViewLoader never sees them) and gives Escape and Backspace
    // back what they mean in a view
    component Field: SearchBar {
        width: parent.width
        height: 52
        fieldSize: Config.body
        onKey: Engine.key()
        onEscaped: Engine.close()
        onBackspaceEmpty: Engine.back()
    }

    // a picture's path: applied on Enter and on leaving the field
    property string pathError: ""
    component PathField: Field {
        id: path
        property string setting: ""
        text: LockConfig[setting]
        function apply() { root.pathError = LockConfig.setPicture(setting, text.trim()) }
        onAccepted: apply()

        Connections {
            target: path.field
            function onActiveFocusChanged() { if (!path.field.activeFocus && path.text !== LockConfig[path.setting]) path.apply() }
        }
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.colW
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: Config.symbol.settings
            title: "Settings"
            subtitle: root.section === "" ? "" : root.section === "look"
                      ? (Config.islandOpacity < 0 ? "Island like the windows" : "Island " + Math.round(Config.islandOpacity * 100) + " %")
                        + "  ·  " + (root.liquid ? "Liquid glass" : "Blur")
                      : root.section === "alerts"
                      ? (Notifier.dnd ? "Do not disturb is on" : "Popups: " + Notifier.popupLength) + (Sounds.enabled ? "  ·  sounds" : "")
                      : root.section === "idle"
                      ? (!Idle.enabled ? "Stays on" : Toggles.caffeine ? "Caffeine: stays on"
                         : Idle.mediaPlaying ? "Media playing: stays on" : "Locks after " + root.spoken(Idle.lockAfter))
                      : root.section === "lock" ? LockConfig.shownName + "  ·  " + LockConfig.shownInfo
                      : (Config.style === "notch" ? "Notch" : "Floating") + "  ·  " + Math.round(Config.scale * 100) + " %"
                        + (Engine.autoHide ? "  ·  Hides when not in use" : "")
            onBack: root.back()

            Pill { kind: "text"; icon: Config.symbol.theme; iconSize: 22; shortcut: "t"; onClicked: Engine.open(Engine.View.Theme) }
        }

        ListSection {
            visible: root.section === ""

            component Category: ListEntry {
                property string page: ""
                flat: true
                onClicked: root.section = page
                Icon { name: "chevron_right"; size: 22; color: Config.label3 }
            }
            ListEntry {
                flat: true
                focus: true
                tone: Config.tintBlue
                icon: Config.symbol.theme
                title: "Appearance"
                subtitle: "Light or dark, colours, wallpaper"
                shortcut: "t"
                onClicked: Engine.open(Engine.View.Theme)
                Icon { name: "chevron_right"; size: 22; color: Config.label3 }
            }
            Category { page: "shell"; tone: Config.tintOrange; icon: "dock_to_bottom"; title: "Island"; subtitle: "Size, shape, hiding, clock"; shortcut: "s" }
            Category { page: "look"; tone: Config.tintBlue; icon: "blur_on"; title: "Glass and blur"; subtitle: "Opacity, blur, liquid glass, motion"; shortcut: "k" }
            Category { page: "alerts"; tone: Config.tintRed; icon: "notifications"; title: "Notifications"; subtitle: "Popups, sounds, toasts"; shortcut: "a" }
            Category { page: "idle"; tone: Config.tintGreen; icon: "bolt"; title: "Energy"; subtitle: "Dim, lock and sleep when idle"; shortcut: "i" }
            Category { page: "lock"; tone: Config.tintOrange; icon: "lock"; title: "Lock screen"; subtitle: "Picture, profile"; shortcut: "l" }
        }
        ListSection {
            visible: root.section === ""
            ListEntry {
                flat: true
                tone: Config.tintBlue
                icon: "tune"
                title: "Advanced"
                subtitle: "Every setting, hand-editable"
                shortcut: "v"
                onClicked: Engine.open(Engine.View.Advanced)
                Icon { name: "chevron_right"; size: 22; color: Config.label3 }
            }
        }

        Column {
            visible: root.section === "shell"
            width: parent.width
            spacing: Config.spaceL

            SectionLabel { text: "Size"; topPadding: Config.spaceS }
            Row {
                width: parent.width
                spacing: Config.spaceM

                // applied on release (or per key step): the island rescales under the slider
                Slider {
                    id: size
                    width: parent.width - (reset.visible ? reset.width + parent.spacing : 0)
                    focus: true
                    icon: "format_size"
                    value: (Config.scale - 0.8) / 0.6
                    valueText: Math.round((0.8 + shown * 0.6) * 100) + "%"
                    step: 0.05 / 0.6
                    onCommitted: v => Config.scale = Math.round((0.8 + v * 0.6) * 20) / 20
                }
                Pill {
                    id: reset
                    visible: Math.abs(Config.scale - 1) > 0.001
                    implicitHeight: 52
                    kind: "text"
                    text: "Reset"
                    onClicked: Config.scale = 1
                }
            }

            SectionLabel { text: "Island"; topPadding: Config.spaceXs }
            Segmented {
                width: parent.width
                options: [{ key: "pill", label: "Floating" }, { key: "notch", label: "Notch" }]
                current: Config.style
                onPicked: key => Config.style = key
            }

            Switch {
                text: "Hide when not in use"
                checked: Engine.autoHide
                onToggled: on => Engine.setAutoHide(on)
            }
            Segmented {
                visible: Engine.autoHide
                width: parent.width
                options: [{ key: "strip", label: "Handle when hidden" }, { key: "none", label: "No handle" }]
                current: Config.handle
                onPicked: key => Config.handle = key
            }

            SectionLabel { text: "Clock"; topPadding: Config.spaceXs }
            Switch {
                text: "24-hour clock"
                checked: Config.clock24
                onToggled: on => Config.clock24 = on
            }
            Segmented {
                width: parent.width
                options: [{ key: "-1", label: "Week as the locale" }, { key: "1", label: "Monday" }, { key: "0", label: "Sunday" }]
                current: String(Config.firstDay)
                onPicked: key => Config.firstDay = Number(key)
            }

            SectionLabel { text: "Desktop"; topPadding: Config.spaceXs }
            Switch {
                text: "\"Activate Linux\""
                checked: Config.activateLinux
                onToggled: on => Config.activateLinux = on
            }
            Row {
                visible: Tray.hidden !== ""
                width: parent.width
                spacing: Config.spaceM

                Label {
                    width: parent.width - showTray.width - parent.spacing
                    leftPadding: Config.spaceXs
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: "Hidden from the tray: " + Tray.patterns.join(", ")
                    font.pixelSize: Config.body + 1
                }
                Pill {
                    id: showTray
                    implicitHeight: 40
                    kind: "text"
                    text: "Show all"
                    onClicked: Tray.hidden = ""
                }
            }
        }

        // Glass and blur: the island and the windows apart. A switch for a yes/no, a named choice for a kind,
        // a slider for an amount; each footer says what Hyprland really does with it.
        ScrollList {
            visible: root.section === "look"
            width: parent.width
            maxHeight: 640
            spacing: Config.spaceL

            ListSection {
                title: "Material"
                footer: !Glass.available ? "Liquid glass is the hyprglass plugin, which isn't loaded for this Hyprland: Hyprland's blur draws everything."
                      : root.liquid ? "The look is where liquid glass starts; everything below changes it, for the island and the windows apart."
                      : "Hyprland's blur. It has one blur for everything, so the island's follows the windows'."
                Item {
                    width: parent.width
                    height: 60
                    Segmented {
                        x: Config.spaceM; width: parent.width - 2 * Config.spaceM
                        anchors.verticalCenter: parent.verticalCenter
                        height: 40
                        enabled: Glass.available
                        options: [{ key: "blur", label: "Blur", icon: "blur_on" }, { key: "glass", label: "Liquid glass", icon: "water_drop" }]
                        current: root.liquid ? "glass" : "blur"
                        onPicked: key => Glass.enabled = key === "glass"
                    }
                }
                Item {
                    visible: root.liquid
                    width: parent.width
                    height: visible ? 60 : 0
                    Segmented {
                        x: Config.spaceM; width: parent.width - 2 * Config.spaceM
                        anchors.verticalCenter: parent.verticalCenter
                        height: 40
                        options: Glass.presets
                        current: Glass.preset
                        onPicked: key => Glass.preset = key
                    }
                }
            }

            ListSection {
                title: "Island"
                footer: root.liquid ? "At 0% opacity the island draws nothing of its own: only the glass shows, and its tint below."
                      : "At 0% opacity the island draws nothing, so the blur has no shape to fill either."
                SwitchRow {
                    title: "Opacity like the windows"
                    checked: Config.islandOpacity < 0
                    onToggled: on => Config.islandOpacity = on ? -1 : Math.round(Config.windowOpacity * 100) / 100
                }
                Amount {
                    text: "Opacity"
                    enabled: Config.islandOpacity >= 0
                    value: Config.islandAlpha
                    onMoved: v => Config.islandOpacity = Math.round(v * 100) / 100
                }
                Amount {
                    text: "Blur"
                    enabled: root.liquid
                    value: Glass.islandBlur >= 0 ? Glass.islandBlur : root.windowBlurShown
                    valueText: !root.liquid || Glass.islandBlur < 0 ? "Like the windows" : Math.round(value * 100) + "%"
                    onCommitted: v => Glass.islandBlur = Math.round(v * 100) / 100
                }
                Amount {
                    text: "Shadow"
                    value: Config.shadowStrength
                    onMoved: v => Config.shadowStrength = Math.round(v * 100) / 100
                }
                GlassAmounts { which: "island"; visible: root.liquid }
            }

            ListSection {
                title: "Windows"
                footer: "Video players, Firefox and qimgv stay opaque (hypr/modules/rules.lua), so opacity doesn't show on them."
                Amount {
                    text: "Opacity"
                    value: Glass.activeOpacity >= 0 ? Glass.activeOpacity : Config.windowOpacity
                    onCommitted: v => Glass.activeOpacity = Math.round(v * 100) / 100
                }
                Amount {
                    text: "Opacity when inactive"
                    value: Glass.inactiveOpacity >= 0 ? Glass.inactiveOpacity : root.hyprCurrent("decoration:inactive_opacity", Config.windowOpacity)
                    onCommitted: v => Glass.inactiveOpacity = Math.round(v * 100) / 100
                }
                Amount {
                    text: "Blur"
                    value: root.windowBlurShown
                    onCommitted: v => Glass.windowBlur = Math.round(v * 100) / 100
                }
                Amount {
                    visible: !root.liquid
                    text: "Vibrancy"
                    value: root.hl("decoration:blur:vibrancy", 0.17)
                    onCommitted: v => root.setHl("decoration:blur:vibrancy", Math.round(v * 100) / 100)
                }
                Amount {
                    visible: !root.liquid
                    text: "Brightness"
                    value: root.hl("decoration:blur:brightness", 1) / 2
                    valueText: Math.round(value * 200) + "%"
                    onCommitted: v => root.setHl("decoration:blur:brightness", Math.round(v * 200) / 100)
                }
                Amount {
                    visible: !root.liquid
                    text: "Contrast"
                    value: root.hl("decoration:blur:contrast", 0.9) / 2
                    valueText: Math.round(value * 200) + "%"
                    onCommitted: v => root.setHl("decoration:blur:contrast", Math.round(v * 200) / 100)
                }
                GlassAmounts { which: "windows"; visible: root.liquid }
            }

            ListSection {
                title: "Shape and motion"
                Amount {
                    text: "Roundness"
                    value: Config.roundness - 0.5
                    valueText: Math.round(Config.roundness * 100) + "%"
                    onMoved: v => Config.roundness = Math.round((0.5 + v) * 20) / 20
                }
                SwitchRow {
                    title: "Reduce motion"
                    checked: Config.reduceMotion
                    onToggled: on => Config.reduceMotion = on
                }
            }
        }

        Column {
            visible: root.section === "alerts"
            width: parent.width
            spacing: Config.spaceL

            // for a notification that doesn't say how long it should stay; a critical one stays
            SectionLabel { text: "Popups stay"; topPadding: Config.spaceS }
            Segmented {
                width: parent.width
                options: [{ key: "short", label: "5 s" }, { key: "normal", label: "10 s" }, { key: "long", label: "20 s" }]
                current: Notifier.popupLength
                onPicked: key => Notifier.popupLength = key
            }
            Switch {
                text: "Do not disturb"
                checked: Notifier.dnd
                onToggled: on => Notifier.dnd = on
            }
            Switch {
                text: "Sounds"
                checked: Sounds.enabled
                onToggled: on => Sounds.enabled = on
            }

            SectionLabel { text: "Toasts"; topPadding: Config.spaceXs }
            Switch {
                text: "Volume, brightness, microphone"
                checked: Config.levelToasts
                onToggled: on => Config.levelToasts = on
            }
            Switch {
                text: "Switching workspace"
                checked: Config.switcherToasts
                onToggled: on => Config.switcherToasts = on
            }
        }

        Column {
            visible: root.section === "idle"
            width: parent.width
            spacing: Config.spaceL

            Switch {
                text: "When there's no input"
                checked: Idle.enabled
                onToggled: on => Idle.enabled = on
            }
            Repeater {
                model: [{ text: "Dim",         icon: "brightness_low",          key: "dimAfter" },
                        { text: "Lock",        icon: "lock",                    key: "lockAfter" },
                        { text: "Screens off", icon: "desktop_access_disabled", key: "offAfter" },
                        { text: "Suspend",     icon: "bedtime",                 key: "suspendAfter" }]

                Delay {
                    required property var modelData
                    enabled: Idle.enabled
                    text: modelData.text
                    icon: modelData.icon
                    seconds: Idle[modelData.key]
                    onPicked: s => Idle[modelData.key] = s
                }
            }

            // the same switch as the dashboard's tile: while it's on, none of the above runs
            Switch {
                visible: Toggles.has("systemd-inhibit")
                text: "Caffeine: stay awake for now"
                checked: Toggles.caffeine
                onToggled: on => Toggles.caffeine = on
            }
        }

        Column {
            visible: root.section === "lock"
            width: parent.width
            spacing: Config.spaceM

            SectionLabel { text: "Pictures"; topPadding: Config.spaceS }
            PathField {
                setting: "image"
                icon: Config.symbol.wallpaper
                placeholder: "Background: follows the wallpaper"

                Pill {
                    implicitHeight: 38
                    kind: "text"
                    icon: "keep"
                    iconSize: 20
                    shortcut: "w"
                    onClicked: { root.pathError = ""; LockConfig.image = Wallpaper.current }
                }
            }
            PathField {
                setting: "avatar"
                icon: "person"
                placeholder: "Profile picture: a path, GIFs play"
            }
            Segmented {
                width: parent.width
                options: [{ key: "circle", label: "Circle" }, { key: "square", label: "Square" }]
                current: LockConfig.avatarShape
                onPicked: key => LockConfig.avatarShape = key
            }
            Label {
                visible: root.pathError !== ""
                width: parent.width
                leftPadding: Config.spaceXs
                elide: Text.ElideMiddle
                text: root.pathError
                color: Config.bad
                font.pixelSize: Config.small
            }

            // how far the picture softens once the sign-in comes up
            Slider {
                width: parent.width
                icon: "blur_on"
                value: LockConfig.blur
                valueText: "Softened behind the sign-in  " + Math.round(shown * 100) + "%"
                onMoved: v => LockConfig.blur = v
            }

            SectionLabel { text: "Who"; topPadding: Config.spaceS }
            Field {
                text: LockConfig.name
                icon: "badge"
                placeholder: LockConfig.fullName || LockConfig.user
                onTextChanged: LockConfig.name = text
            }
            Field {
                text: LockConfig.info
                icon: "info"
                placeholder: LockConfig.defaultInfo
                onTextChanged: LockConfig.info = text
            }
        }

        KeyHints {
            width: parent.width
            keys: root.section === "" ? [["⏎", "open"], ["⌫", "back"], ["Esc", "close"]]
                : root.section === "lock" ? [["⏎", "apply"], ["Esc", "close"]]
                : root.section === "alerts" ? [["⏎", "switch"], ["⌫", "back"], ["Esc", "close"]]
                : [["← →", root.section === "idle" ? "wait" : root.section === "look" ? "adjust" : "size"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
