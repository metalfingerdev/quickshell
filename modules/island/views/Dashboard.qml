import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// The Control Center, after Android 16's quick settings (Material 3 Expressive): the time large, the
// levels first, four large tiles, then small tiles, icon only, that morph from a rounded square to a
// pill when on and give a little when pressed; the line under them names the one you point at, or
// says what's on. The power profile and the session are connected button groups: the chosen one
// rounds right out. Everything sits on one width split in halves, thirds or sixths with one gap.
Item {
    id: root

    readonly property int pad: 20
    readonly property int contentW: 600
    readonly property int gap: 10
    readonly property real half: (contentW - gap) / 2
    readonly property real sixth: (contentW - 5 * gap) / 6
    readonly property int joint: 4                    // between a connected group's buttons

    implicitWidth: contentW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    property bool showMore: false
    Store {
        category: "dashboard"
        property alias showMore: root.showMore
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function val(x) { return typeof x === "function" ? x() : x }
    function usable(item) { return (item.usable?.() ?? true) && (!item.tool || Toggles.has(item.tool)) }
    function open(view) { return x => Engine.open(view, x) }
    function caption(item) {
        const status = val(item.status) ?? (item.isOn ? (item.isOn() ? "On" : "Off") : "")
        return item.title + (status ? "  ·  " + status : "")
    }

    // the small tile under the pointer or the keyboard, for the line under them
    property Item pointed: null
    function point(item, on) {
        if (on) pointed = item
        else if (pointed === item) pointed = null
    }

    // Functions, not values: the lists stay put when a setting flips, so the tile with the keyboard
    // focus isn't rebuilt under it. The first row switches, the second captures and asks.
    readonly property var quick: [
        { letter: "m", title: "Microphone", usable: () => Audio.hasMic,
          icon: () => Audio.hasMic && !Audio.micMuted ? "mic" : "mic_off", isOn: () => Audio.hasMic && !Audio.micMuted,
          status: () => !Audio.hasMic ? "No microphone" : Audio.micMuted ? "Muted" : "On", run: () => Audio.toggleMic() },
        { letter: "a", title: "Airplane mode", icon: "flight", isOn: () => Toggles.airplane,
          run: () => Toggles.setAirplane(!Toggles.airplane) },
        { letter: "l", title: "Night light", tool: "hyprsunset", icon: "nightlight", isOn: () => Toggles.nightLight,
          status: () => Toggles.nightLight ? Toggles.warmth + " K" : "Off", run: () => Toggles.nightLight = !Toggles.nightLight },
        { letter: "c", title: "Caffeine", tool: "systemd-inhibit", icon: "coffee", isOn: () => Toggles.caffeine,
          run: () => Toggles.caffeine = !Toggles.caffeine },
        { letter: "k", title: "Dark theme", icon: "dark_mode", isOn: () => Config.dark,
          run: () => { Config.setDark(!Config.dark); Toggles.colorScheme(Config.dark) } },
        { letter: "s", title: "Screenshot", tool: "grimblast", icon: Config.symbol.screenshot, status: "Select an area",
          run: () => { Engine.close(); Toggles.screenshot() } },

        { letter: "r", title: "Record the screen", tool: "wf-recorder",
          icon: () => Toggles.recording && !Toggles.recordingMic ? "stop_circle" : Config.symbol.record,
          isOn: () => Toggles.recording && !Toggles.recordingMic,
          status: () => Toggles.recording && !Toggles.recordingMic ? Toggles.recordTime : "", run: () => root.record(false) },
        { title: "Record with the microphone", tool: "wf-recorder",
          icon: () => Toggles.recording && Toggles.recordingMic ? "stop_circle" : "record_voice_over",
          isOn: () => Toggles.recording && Toggles.recordingMic,
          status: () => Toggles.recording && Toggles.recordingMic ? Toggles.recordTime : "", run: () => root.record(true) },
        { letter: "n", title: "Voice memo", icon: () => Toggles.memoRecording ? "stop_circle" : "graphic_eq",
          isOn: () => Toggles.memoRecording, status: () => Toggles.memoRecording ? Toggles.memoTime : "",
          run: () => Toggles.voiceMemo(!Toggles.memoRecording) },
        { letter: "v", title: "Clipboard", icon: "content_paste", status: "Everything copied", run: root.open(Engine.View.Clipboard) },
        { letter: ".", title: "Emoji", icon: "mood", status: "And symbols, kaomoji",
          run: () => { Engine.launcherFilter = "emoji"; Engine.open(Engine.View.Launcher) } },
        { letter: "/", title: "Agent", icon: "smart_toy", status: "Ask the local model", run: root.open(Engine.View.Agent) }
    ]
    // Folded under More: the rest of the launcher's actions and views.
    readonly property var more: [
        { title: "Coding agent", icon: "terminal", status: "Crush, in kitty",
          run: () => { Engine.close(); Toggles.launch(["kitty", "-e", "crush"]) } },
        { letter: "x", title: "Mixer", icon: Config.symbol.mixer, status: "Volume for each app", run: root.open(Engine.View.Mixer) },
        { title: "Calendar", icon: Config.symbol.calendar, run: root.open(Engine.View.Clock) },
        { letter: "g", title: "Workspaces", icon: Config.symbol.overview, run: root.open(Engine.View.Workspaces) },
        { letter: "h", title: "Tabs", icon: Config.symbol.hub, status: "Every view", run: root.open(Engine.View.Tabs) },
        { title: "Notifications", icon: Config.symbol.notifications, count: () => Notifier.count,
          status: () => Notifier.count > 0 ? Notifier.count + " waiting" : "None", run: root.open(Engine.View.Notifications) },
        { title: "Media", icon: Config.symbol.media, status: "What's playing", run: root.open(Engine.View.Media) },
        { title: "Battery", icon: () => Energy.glyph, usable: () => Energy.present, run: root.open(Engine.View.Battery) },
        { title: "Colours", icon: Config.symbol.colours, run: root.open(Engine.View.Colours) },
        { title: "Theme", icon: Config.symbol.theme, run: root.open(Engine.View.Theme) },
        { title: "Wallpaper", icon: Config.symbol.wallpaper, run: root.open(Engine.View.Wallpapers) },
        { title: "Shuffle the wallpaper", icon: "shuffle", run: () => Wallpaper.random() }
    ]
    // record the screen, not the Control Center; either button stops whichever recording is on
    function record(mic) {
        if (Toggles.recording) return Toggles.record(false, false)
        Engine.close()
        Toggles.record(true, mic)
    }

    // Restart asks for a second press, as in the Power view: "Again?" for three seconds.
    readonly property var session: [
        { title: "Lock", icon: "lock", run: () => { Engine.close(); Session.run("lock") } },
        { title: "Suspend", icon: "bedtime", run: () => { Engine.close(); Session.run("suspend") } },
        { title: "Restart", icon: "restart_alt", confirm: true, run: () => { Engine.close(); Session.run("reboot") } },
        { letter: "p", title: "Power", icon: Config.symbol.power, run: root.open(Engine.View.Power) }
    ]
    property string armed: ""
    Timer { id: disarm; interval: 3000; onTriggered: root.armed = "" }
    function press(s, x) {
        if (s.confirm && armed !== s.title) { armed = s.title; disarm.restart(); return }
        armed = ""
        s.run(x)
    }

    Component.onCompleted: Toggles.readProfile()

    // levels from anywhere in the view (the tiles' letters are their shortcuts)
    Keys.onPressed: event => {
        const t = event.text
        if (t === "+" || t === "=") Audio.setVolume(Audio.volume + 5)
        else if (t === "-") Audio.setVolume(Audio.volume - 5)
        else if (t === "]") Backlight.set(Backlight.percent + 5)
        else if (t === "[") Backlight.set(Backlight.percent - 5)
        else { event.accepted = false; return }
        Engine.key()
    }

    // A small tile: its icon alone, a rounded square that rounds out to a pill when on.
    component Small: Rectangle {
        id: tile
        property string icon: ""
        property string caption: ""
        property bool on: false
        property int count: 0
        property string shortcut: ""
        property bool keyboardSelected: activeFocus && Config.focusVisible
        readonly property bool lit: area.containsMouse || keyboardSelected
        readonly property color ink: on ? Config.primaryInk : Config.text
        signal clicked(real sceneX)
        function activate() { clicked(-1) }
        onLitChanged: root.point(tile, lit)

        activeFocusOnTab: true
        width: root.sixth
        height: 60
        radius: on ? height / 2 : 18
        Behavior on radius { NumberAnimation { duration: 340; easing.type: Easing.OutBack } }
        scale: area.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        color: Config.state(on ? Config.primary : Config.container, ink, area.containsMouse, area.pressed || keyboardSelected)
        Behavior on color { ColorAnimation { duration: 160 } }
        opacity: enabled ? 1 : 0.38

        Icon {
            anchors.centerIn: parent
            name: tile.icon
            size: 24
            filled: tile.on
            color: tile.ink
        }
        ClickArea {
            id: area
            onClicked: mouse => tile.clicked(area.sceneX(mouse))
        }
        FocusRing { on: tile.keyboardSelected }
        KeyBadge { key: tile.shortcut }
        CountBadge { count: tile.count }
    }

    // One button of a connected group: its outer corners round, its inner ones nearly square, and
    // all of them round once it's the chosen one.
    component Segment: Rectangle {
        id: seg
        property string icon: ""
        property string text: ""
        property bool selected: false
        property bool first: false
        property bool last: false
        property string shortcut: ""
        property bool keyboardSelected: activeFocus && Config.focusVisible
        readonly property color ink: selected ? Config.primaryInk : Config.text
        readonly property real round: height / 2
        signal clicked(real sceneX)
        function activate() { clicked(-1) }

        activeFocusOnTab: true
        height: 48
        radius: round
        topLeftRadius: first || selected ? round : 8
        bottomLeftRadius: first || selected ? round : 8
        topRightRadius: last || selected ? round : 8
        bottomRightRadius: last || selected ? round : 8
        Behavior on topLeftRadius { Motion {} }
        Behavior on bottomLeftRadius { Motion {} }
        Behavior on topRightRadius { Motion {} }
        Behavior on bottomRightRadius { Motion {} }
        scale: area.pressed ? 0.96 : 1
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        color: Config.state(selected ? Config.primary : Config.container, ink, area.containsMouse, area.pressed || keyboardSelected)
        Behavior on color { ColorAnimation { duration: 160 } }

        Row {
            anchors.centerIn: parent
            spacing: 8

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: seg.icon
                size: 20
                filled: seg.selected
                color: seg.ink
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: seg.text
                color: seg.ink
                font.weight: Font.Medium
            }
        }
        ClickArea {
            id: area
            onClicked: mouse => seg.clicked(area.sceneX(mouse))
        }
        FocusRing { on: seg.keyboardSelected }
        KeyBadge { key: seg.shortcut }
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.contentW
        spacing: 14

        // the time large, as Android's shade opens with it
        Item {
            width: parent.width
            height: 72

            BackButton {
                id: back
                anchors.verticalCenter: parent.verticalCenter
                onClicked: Engine.back()
            }
            Column {
                anchors { left: back.right; leftMargin: 14; verticalCenter: parent.verticalCenter }

                Text {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: 42
                    font.weight: Font.Normal
                }
                Label {
                    text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Config.dim
                }
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 6

                Pill {
                    visible: Energy.present
                    icon: Energy.glyph
                    text: Energy.percent >= 0 ? Energy.percent + "%" : "…"
                    active: Energy.charging
                    shortcut: "e"
                    onClicked: x => Engine.open(Engine.View.Battery, x)
                }
                Pill { kind: "text"; icon: Config.symbol.settings; iconSize: 22; shortcut: "i"; onClicked: Engine.open(Engine.View.Settings) }
            }
        }

        Row {
            spacing: root.gap

            BrightnessSlider {
                visible: Backlight.available
                width: root.half
                implicitHeight: 52
            }
            VolumeSlider {
                width: Backlight.available ? root.half : root.contentW
                implicitHeight: 52
                enabled: Audio.sink !== null
            }
        }

        // large tiles: a pill when on, squarer when off, as the small ones
        Grid {
            columns: 2
            spacing: root.gap

            QuickTile {
                width: root.half
                implicitHeight: 64
                radius: on ? height / 2 : 22
                Behavior on radius { NumberAnimation { duration: 340; easing.type: Easing.OutBack } }
                focus: true                              // the keyboard starts here
                icon: Net.icon
                title: Net.ethernet && !Net.current ? "Ethernet" : "Wi-Fi"
                subtitle: Net.attempt ? "Connecting…" : Net.current ? Net.current.name
                        : Net.ethernet ? "Connected" : Net.summary
                on: Net.wifiEnabled || Net.ethernet
                split: true
                shortcut: "w"
                enabled: Net.available
                onToggled: Net.setWifi(!Net.wifiEnabled)
                onClicked: x => Engine.open(Engine.View.Network, x)
            }
            QuickTile {
                width: root.half
                implicitHeight: 64
                radius: on ? height / 2 : 22
                Behavior on radius { NumberAnimation { duration: 340; easing.type: Easing.OutBack } }
                icon: Bluez.icon
                title: "Bluetooth"
                subtitle: Bluez.summary
                on: Bluez.enabled
                split: true
                shortcut: "b"
                enabled: Bluez.available && !Bluez.blocked
                onToggled: Bluez.setEnabled(!Bluez.enabled)
                onClicked: x => Engine.open(Engine.View.Bluetooth, x)
            }
            QuickTile {
                width: root.half
                implicitHeight: 64
                radius: on ? height / 2 : 22
                Behavior on radius { NumberAnimation { duration: 340; easing.type: Easing.OutBack } }
                icon: Audio.muted ? Config.symbol.muted : Config.symbol.sound
                title: "Audio"
                subtitle: Audio.muted ? "Muted  ·  " + Audio.label(Audio.sink) : Audio.label(Audio.sink)
                on: !Audio.muted
                split: true
                shortcut: "o"
                enabled: Audio.sink !== null
                onToggled: Audio.toggleMute()
                onClicked: x => Engine.open(Engine.View.Media, x)
            }
            QuickTile {
                width: root.half
                implicitHeight: 64
                radius: on ? height / 2 : 22
                Behavior on radius { NumberAnimation { duration: 340; easing.type: Easing.OutBack } }
                icon: Notifier.dnd ? Config.symbol.dnd : "do_not_disturb_off"
                title: "Do not disturb"
                subtitle: Notifier.dnd ? "On" : Notifier.count > 0 ? Notifier.count + " notifications" : "Off"
                on: Notifier.dnd
                split: true
                shortcut: "d"
                onToggled: Notifier.dnd = !Notifier.dnd
                onClicked: x => Engine.open(Engine.View.Notifications, x)
            }
        }

        // the small tiles, and the rest of them unfolded right under, as one grid
        Column {
            spacing: root.gap

            Repeater {
                model: [root.quick, root.more]

                Grid {
                    required property var modelData
                    required property int index
                    visible: index === 0 || root.showMore
                    columns: 6
                    spacing: root.gap

                    Repeater {
                        model: parent.modelData

                        Small {
                            required property var modelData
                            icon: root.val(modelData.icon)
                            on: modelData.isOn?.() ?? false
                            count: modelData.count?.() ?? 0
                            caption: root.caption(modelData)
                            shortcut: modelData.letter ?? ""
                            enabled: root.usable(modelData)
                            onClicked: x => modelData.run(x)
                        }
                    }
                }
            }
        }

        // what the pointer is on, or what's on; and More, which unfolds the rest above
        Item {
            width: parent.width
            height: 32

            Label {
                anchors { left: parent.left; leftMargin: 4; right: more.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
                elide: Text.ElideRight
                color: root.pointed ? Config.text : Config.dim
                text: root.pointed ? root.pointed.caption : (() => {
                    const lit = root.quick.filter(q => q.isOn?.()).map(q => q.title)
                    return lit.length > 0 ? "On: " + lit.join(", ") : "Point at a tile for its name"
                })()
            }
            Pill {
                id: more
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                implicitHeight: 32
                kind: "text"
                icon: root.showMore ? "expand_less" : "expand_more"
                text: root.showMore ? "Less" : "More"
                onClicked: root.showMore = !root.showMore
            }
        }

        Row {
            visible: Toggles.profile !== ""
            spacing: root.joint

            Repeater {
                model: Toggles.profiles

                Segment {
                    required property var modelData
                    required property int index
                    width: (root.contentW - 2 * root.joint) / 3
                    first: index === 0
                    last: index === 2
                    icon: modelData.icon
                    text: modelData.label
                    selected: Toggles.profile === modelData.key
                    onClicked: Toggles.setProfile(modelData.key)
                }
            }
        }

        Row {
            spacing: root.joint

            Repeater {
                model: root.session

                Segment {
                    required property var modelData
                    required property int index
                    width: (root.contentW - 3 * root.joint) / 4
                    first: index === 0
                    last: index === 3
                    icon: modelData.icon
                    text: root.armed === modelData.title ? "Again?" : modelData.title
                    selected: root.armed === modelData.title
                    shortcut: modelData.letter ?? ""
                    onClicked: x => root.press(modelData, x)
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["Space", "switch"], ["Enter", "open"], ["+ −", "volume"], ["[ ]", "brightness"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
