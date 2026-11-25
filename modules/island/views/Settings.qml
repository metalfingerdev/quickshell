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
                        + "  ·  " + (Glass.blurs.find(b => b.key === Glass.blur)?.label ?? "Medium") + " blur"
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

        Column {
            visible: root.section === "look"
            width: parent.width
            spacing: Config.spaceL

            SectionLabel { text: "Island"; topPadding: Config.spaceS }
            // its own opacity, down to see-through (the glass still shows its edge), or the windows'
            Level {
                text: "Opacity"
                valueText: Config.islandOpacity < 0 ? "Like the windows" : Math.round(Config.islandOpacity * 100) + "%"
                value: Config.islandOpacity < 0 ? Config.windowOpacity : Config.islandOpacity
                checker: true
                colourAt: t => root.seeThrough(t)
                onMoved: v => Config.islandOpacity = Math.round(v * 100) / 100
            }
            Pill {
                visible: Config.islandOpacity >= 0
                implicitHeight: 40
                kind: "text"
                icon: "link"
                text: "Like the windows"
                onClicked: Config.islandOpacity = -1
            }
            Switch {
                text: "Shadow"
                checked: Config.shadow
                onToggled: on => Config.shadow = on
            }

            // Hyprland's own, the windows' and the island's alike (or, with liquid glass, the glass's)
            SectionLabel { text: "Blur"; topPadding: Config.spaceXs }
            Segmented {
                width: parent.width
                options: Glass.blurs
                current: Glass.blur
                onPicked: key => Glass.blur = key
            }
            Level {
                text: "Windows"
                valueText: Math.round(value * 100) + "%"
                value: Glass.windows >= 0 ? Glass.windows : Config.windowOpacity
                checker: true
                colourAt: t => root.seeThrough(t)
                onMoved: v => Glass.windows = Math.round(v * 100) / 100
            }

            // hidden while Hyprland runs without the plugin (left out for another version): the blur above
            SectionLabel { visible: Glass.available; text: "Liquid glass"; topPadding: Config.spaceXs }
            Switch {
                visible: Glass.available
                text: "On windows and the island"
                checked: Glass.enabled
                onToggled: on => Glass.enabled = on
            }
            Segmented {
                visible: Glass.available && Glass.enabled
                width: parent.width
                options: Glass.presets
                current: Glass.preset
                onPicked: key => Glass.preset = key
            }

            SectionLabel { text: "Shape and motion"; topPadding: Config.spaceXs }
            Slider {
                width: parent.width
                icon: "rounded_corner"
                value: Config.roundness - 0.5
                valueText: "Roundness  " + Math.round((0.5 + shown) * 100) + "%"
                onMoved: v => Config.roundness = Math.round((0.5 + v) * 20) / 20
            }
            Switch {
                text: "Reduce motion"
                checked: Config.reduceMotion
                onToggled: on => Config.reduceMotion = on
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
