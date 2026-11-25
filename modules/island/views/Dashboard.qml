import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// The Control Center as a bento grid, after Android 16's quick settings (Material 3 Expressive): six
// columns, and a row for each kind of thing, in tiles one, two, three or four cells wide, and two
// cards two by two (the agent, and under More the wallpaper). Tiles round out to a pill when on and
// give a little when pressed; the line under the grid names the small tile you point at, or says
// what's on. The power profile and the session are connected button groups.
Item {
    id: root

    readonly property int pad: 20
    readonly property int contentW: 600
    readonly property int gap: 10
    readonly property int rowH: 60
    readonly property real sixth: (contentW - 5 * gap) / 6
    readonly property int joint: 4                    // between a connected group's buttons

    // a cell's place and size, in columns and rows
    function cx(c) { return c * (sixth + gap) }
    function cy(r) { return r * (rowH + gap) }
    function cw(w) { return w * sixth + (w - 1) * gap }
    function ch(h) { return h * rowH + (h - 1) * gap }

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
    function launch(command) { return () => { Engine.close(); Toggles.launch(command) } }
    function caption(item) {
        const status = val(item.status) ?? (item.isOn ? (item.isOn() ? "On" : "Off") : "")
        return item.title + (status ? "  ·  " + status : "")
    }

    // the small tile under the pointer or the keyboard, for the line under the grid
    property Item pointed: null
    function point(item, on) {
        if (on) pointed = item
        else if (pointed === item) pointed = null
    }

    // The small tiles, each in its cell; the wide ones and the cards are placed below by hand.
    // Functions, not values: the lists stay put when a setting flips, so the tile with the keyboard
    // focus isn't rebuilt under it.
    readonly property var small: [
        // connections: Internet, Bluetooth, and
        { col: 5, row: 0, letter: "a", title: "Airplane mode", icon: "flight", isOn: () => Toggles.airplane,
          run: () => Toggles.setAirplane(!Toggles.airplane) },
        // sound: the volume, and
        { col: 4, row: 1, letter: "m", title: "Microphone", usable: () => Audio.hasMic,
          icon: () => Audio.hasMic && !Audio.micMuted ? "mic" : "mic_off", isOn: () => Audio.hasMic && !Audio.micMuted,
          status: () => !Audio.hasMic ? "No microphone" : Audio.micMuted ? "Muted" : "On", run: () => Audio.toggleMic() },
        { col: 5, row: 1, letter: "x", title: "Mixer", icon: Config.symbol.mixer, status: "Volume for each app",
          run: root.open(Engine.View.Mixer) },
        // the screen: the brightness, and
        { col: 4, row: 2, letter: "l", title: "Night light", tool: "hyprsunset", icon: "nightlight", isOn: () => Toggles.nightLight,
          status: () => Toggles.nightLight ? Toggles.warmth + " K" : "Off", run: () => Toggles.nightLight = !Toggles.nightLight },
        { col: 5, row: 2, letter: "k", title: "Dark theme", icon: "dark_mode", isOn: () => Config.dark,
          run: () => { Config.setDark(!Config.dark); Toggles.colorScheme(Config.dark) } },
        // attention and power: Do not disturb, and between it and Battery
        { col: 2, row: 3, title: "Notifications", icon: Config.symbol.notifications, count: () => Notifier.count,
          status: () => Notifier.count > 0 ? Notifier.count + " waiting" : "None", run: root.open(Engine.View.Notifications) },
        { col: 3, row: 3, letter: "c", title: "Caffeine", tool: "systemd-inhibit", icon: "coffee", isOn: () => Toggles.caffeine,
          status: () => Toggles.caffeine ? "Staying awake" : "Off", run: () => Toggles.caffeine = !Toggles.caffeine },
        // beside the agent: capture, then text and tools
        { col: 2, row: 4, letter: "s", title: "Screenshot", tool: "grimblast", icon: Config.symbol.screenshot,
          status: "Select an area", run: () => { Engine.close(); Toggles.screenshot() } },
        { col: 3, row: 4, letter: "r", title: "Record the screen", tool: "wf-recorder",
          icon: () => Toggles.recording && !Toggles.recordingMic ? "stop_circle" : Config.symbol.record,
          isOn: () => Toggles.recording && !Toggles.recordingMic,
          status: () => Toggles.recording && !Toggles.recordingMic ? Toggles.recordTime : "", run: () => root.record(false) },
        { col: 4, row: 4, title: "Record with the microphone", tool: "wf-recorder",
          icon: () => Toggles.recording && Toggles.recordingMic ? "stop_circle" : "record_voice_over",
          isOn: () => Toggles.recording && Toggles.recordingMic,
          status: () => Toggles.recording && Toggles.recordingMic ? Toggles.recordTime : "", run: () => root.record(true) },
        { col: 5, row: 4, letter: "n", title: "Voice memo", icon: () => Toggles.memoRecording ? "stop_circle" : "graphic_eq",
          isOn: () => Toggles.memoRecording, status: () => Toggles.memoRecording ? Toggles.memoTime : "",
          run: () => Toggles.voiceMemo(!Toggles.memoRecording) },
        { col: 2, row: 5, letter: "v", title: "Clipboard", icon: "content_paste", status: "Everything copied",
          run: root.open(Engine.View.Clipboard) },
        { col: 3, row: 5, letter: ".", title: "Emoji", icon: "mood", status: "And symbols, kaomoji",
          run: () => { Engine.launcherFilter = "emoji"; Engine.open(Engine.View.Launcher) } },
        { col: 4, row: 5, title: "Coding agent", icon: "code", status: "Crush, in kitty", run: root.launch(["kitty", "-e", "crush"]) },
        { col: 5, row: 5, letter: "u", title: "Colour picker", tool: "hyprpicker", icon: "colorize",
          status: "A colour from anywhere, copied", run: () => { Engine.close(); Toggles.pickColour() } }
    ]
    // Under More, beside the wallpaper: its look, then places to go.
    readonly property var more: [
        { col: 2, row: 0, title: "Shuffle the wallpaper", icon: "shuffle", run: () => Wallpaper.random() },
        { col: 3, row: 0, title: "Colours", icon: Config.symbol.colours, status: "Palettes, an accent", run: root.open(Engine.View.Colours) },
        { col: 4, row: 0, title: "Theme", icon: Config.symbol.theme, run: root.open(Engine.View.Theme) },
        { col: 5, row: 0, letter: "g", title: "Workspaces", icon: Config.symbol.overview, run: root.open(Engine.View.Workspaces) },
        { col: 2, row: 1, title: "Media", icon: Config.symbol.media, status: "What's playing", run: root.open(Engine.View.Media) },
        { col: 3, row: 1, title: "Calendar", icon: Config.symbol.calendar, run: root.open(Engine.View.Clock) },
        { col: 4, row: 1, letter: "f", title: "Files", icon: "folder", status: "Yazi, in kitty", run: root.launch(["kitty", "-e", "yazi"]) },
        { col: 5, row: 1, letter: "t", title: "Terminal", icon: "terminal", status: "Kitty", run: root.launch(["kitty"]) },
        // a row under the wallpaper: what's kept, then what's around
        { col: 0, row: 2, letter: "o", title: "Tasks", icon: "checklist", count: () => Tasks.open,
          status: () => Tasks.open > 0 ? Tasks.open + " not done" : "None", run: root.open(Engine.View.Tasks) },
        { col: 1, row: 2, letter: "h", title: "NixOS", icon: "history", status: "Generations, updates", run: root.open(Engine.View.Generations) },
        { col: 2, row: 2, title: "Favourites", icon: "keep", status: () => Pins.apps.length + " pinned", run: root.open(Engine.View.Dock) },
        { col: 3, row: 2, title: "Tray", icon: "widgets", status: () => Tray.items.length + " apps", run: root.open(Engine.View.Tray) }
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
        Accessible.role: Accessible.Button
        Accessible.name: caption !== "" ? caption : Config.spoken(icon)
        Accessible.checked: on
        Accessible.onPressAction: activate()
        onLitChanged: root.point(tile, lit)

        activeFocusOnTab: true
        width: root.sixth
        height: root.rowH
        radius: on ? height / 2 : 18
        Behavior on radius { Motion {} }
        scale: area.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: Config.durationFast; easing.type: Easing.OutCubic } }
        color: Config.state(on ? Config.primary : Config.container, ink, area.containsMouse, area.pressed || keyboardSelected)
        Behavior on color { ColorAnimation { duration: Config.durationFast } }
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

    // A wide tile in its cell: Android's large tile, rounding out the same way.
    component Wide: QuickTile {
        required property int col
        required property int row
        property int span: 2
        x: root.cx(col)
        y: root.cy(row)
        width: root.cw(span)
        height: root.rowH
        split: true
        radius: on ? height / 2 : 22
        Behavior on radius { Motion {} }
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
        Accessible.role: Accessible.RadioButton
        Accessible.name: text !== "" ? text : Config.spoken(icon)
        Accessible.checked: selected
        Accessible.onPressAction: activate()

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
        Behavior on scale { NumberAnimation { duration: Config.durationFast; easing.type: Easing.OutCubic } }
        color: Config.state(selected ? Config.primary : Config.container, ink, area.containsMouse, area.pressed || keyboardSelected)
        Behavior on color { ColorAnimation { duration: Config.durationFast } }

        Row {
            anchors.centerIn: parent
            spacing: Config.spaceS

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
        spacing: Config.spaceL

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
                anchors { left: back.right; leftMargin: Config.spaceL; verticalCenter: parent.verticalCenter }

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
            Pill {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                kind: "text"
                icon: Config.symbol.settings
                iconSize: 22
                shortcut: "i"
                onClicked: Engine.open(Engine.View.Settings)
            }
        }

        Item {
            width: parent.width
            height: root.cy(6) - root.gap

            Wide {
                col: 0; row: 0; span: 3
                focus: true                              // the keyboard starts here
                icon: Net.icon
                title: Net.ethernet && !Net.current ? "Ethernet" : "Wi-Fi"
                subtitle: Net.attempt ? "Connecting…" : Net.current ? Net.current.name
                        : Net.ethernet ? "Connected" : Net.summary
                on: Net.wifiEnabled || Net.ethernet
                shortcut: "w"
                enabled: Net.available
                onToggled: Net.setWifi(!Net.wifiEnabled)
                onClicked: x => Engine.open(Engine.View.Network, x)
            }
            Wide {
                col: 3; row: 0
                icon: Bluez.icon
                title: "Bluetooth"
                subtitle: Bluez.summary
                on: Bluez.enabled
                shortcut: "b"
                enabled: Bluez.available && !Bluez.blocked
                onToggled: Bluez.setEnabled(!Bluez.enabled)
                onClicked: x => Engine.open(Engine.View.Bluetooth, x)
            }

            // the icon mutes, as the Audio tile's did; Media and outputs are under More and in Mixer
            VolumeSlider {
                x: root.cx(0); y: root.cy(1)
                width: root.cw(4); height: root.rowH
                enabled: Audio.sink !== null
            }
            BrightnessSlider {
                x: root.cx(0); y: root.cy(2)
                width: root.cw(4); height: root.rowH
                enabled: Backlight.available
            }

            Wide {
                col: 0; row: 3
                icon: Notifier.dnd ? Config.symbol.dnd : "do_not_disturb_off"
                title: "Do not disturb"
                subtitle: Notifier.dnd ? "On" : "Off"
                on: Notifier.dnd
                shortcut: "d"
                onToggled: Notifier.dnd = !Notifier.dnd
                onClicked: x => Engine.open(Engine.View.Notifications, x)
            }
            // nothing to switch: lit while the charger is in, and both halves open Battery
            Wide {
                col: 4; row: 3
                icon: Energy.glyph
                title: "Battery"
                // short: the tile is two cells wide, and lit already says the charger is in
                subtitle: !Energy.present ? "None" : Energy.percent < 0 ? "…"
                    : Energy.percent + "%" + (Energy.full ? " · Full" : Energy.charging ? " · Charging"
                    : !Energy.plugged && Energy.minutesLeft >= 0 ? " · " + Energy.duration(Energy.minutesLeft) : "")
                on: Energy.plugged
                shortcut: "e"
                enabled: Energy.present
                onToggled: Engine.open(Engine.View.Battery)
                onClicked: x => Engine.open(Engine.View.Battery, x)
            }

            // The agent, two by two: what it's doing or was last asked, over a field that opens it.
            Rectangle {
                id: agentCard
                readonly property string shortcut: "/"
                property bool keyboardSelected: activeFocus && Config.focusVisible
                readonly property color ink: Config.secondaryInk
                function activate() { Engine.open(Engine.View.Agent) }

                activeFocusOnTab: true
                x: root.cx(0); y: root.cy(4)
                width: root.cw(2); height: root.ch(2)
                radius: 28
                scale: agentArea.pressed ? 0.97 : 1
                Behavior on scale { NumberAnimation { duration: Config.durationFast; easing.type: Easing.OutCubic } }
                color: Config.state(Config.secondary, ink, agentArea.containsMouse, agentArea.pressed || keyboardSelected)

                Column {
                    x: 16; y: 14
                    width: parent.width - 32
                    spacing: Config.spaceS

                    Row {
                        spacing: Config.spaceS

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "smart_toy"
                            size: 22
                            filled: true
                            color: agentCard.ink
                        }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Agent"
                            color: agentCard.ink
                            font.pixelSize: Config.body + 1
                            font.weight: Font.DemiBold
                        }
                    }
                    Label {
                        width: parent.width
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        color: Config.mix(agentCard.ink, Config.secondary, 0.25)
                        font.pixelSize: Config.small + 1
                        text: Agent.busy ? Agent.activity
                            : Agent.lastQuestion !== "" ? "“" + Agent.lastQuestion + "”"
                            : !Agent.ready ? "Starting"
                            : Agent.inUse === "" ? "No model yet"
                            : Agent.inUse + (Agent.loaded ? ", awake" : ", asleep")
                    }
                }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Config.spaceM }
                    height: 38
                    radius: height / 2
                    color: Config.mix(Config.secondary, agentCard.ink, 0.12)

                    Label {
                        anchors { left: parent.left; leftMargin: Config.spaceL; verticalCenter: parent.verticalCenter }
                        text: "Ask anything"
                        color: Config.mix(agentCard.ink, Config.secondary, 0.35)
                    }
                    Icon {
                        anchors { right: parent.right; rightMargin: Config.spaceM; verticalCenter: parent.verticalCenter }
                        name: "arrow_upward"
                        size: 18
                        color: agentCard.ink
                    }
                }
                ClickArea {
                    id: agentArea
                    onClicked: mouse => Engine.open(Engine.View.Agent, agentArea.sceneX(mouse))
                }
                FocusRing { on: agentCard.keyboardSelected }
                KeyBadge { key: agentCard.shortcut }
            }

            Repeater {
                model: root.small

                Small {
                    required property var modelData
                    x: root.cx(modelData.col)
                    y: root.cy(modelData.row)
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

        // More: the wallpaper as it is, two by two, beside its look and the places to go
        Item {
            visible: root.showMore
            width: parent.width
            height: root.ch(3)

            // not WallpaperThumb: its ring and tick say "applied", which this one always is
            ClippingRectangle {
                id: wallCard
                property bool keyboardSelected: activeFocus && Config.focusVisible
                function activate() { Engine.open(Engine.View.Wallpapers) }

                activeFocusOnTab: true
                x: root.cx(0); y: root.cy(0)
                width: root.cw(2); height: root.ch(2)
                radius: 28
                color: Config.container
                scale: wallArea.pressed ? 0.97 : 1
                Behavior on scale { NumberAnimation { duration: Config.durationFast; easing.type: Easing.OutCubic } }

                CoverImage {
                    source: Wallpaper.current ? Wallpaper.fileUrl(Wallpaper.current) : ""
                    sourceSize: Qt.size(384, 240)            // decode small: wallpapers are big
                }
                ClickArea {
                    id: wallArea
                    onClicked: mouse => Engine.open(Engine.View.Wallpapers, wallArea.sceneX(mouse))
                }
                FocusRing { on: wallCard.keyboardSelected }
            }
            Repeater {
                model: root.more

                Small {
                    required property var modelData
                    x: root.cx(modelData.col)
                    y: root.cy(modelData.row)
                    icon: root.val(modelData.icon)
                    caption: root.caption(modelData)
                    count: modelData.count?.() ?? 0
                    shortcut: modelData.letter ?? ""
                    enabled: root.usable(modelData)
                    onClicked: x => modelData.run(x)
                }
            }
        }

        // what the pointer is on, or what's on; and More, which unfolds the rest above
        Item {
            width: parent.width
            height: 32

            Label {
                anchors { left: parent.left; leftMargin: Config.spaceXs; right: more.left; rightMargin: Config.spaceM; verticalCenter: parent.verticalCenter }
                elide: Text.ElideRight
                color: root.pointed ? Config.text : Config.dim
                text: root.pointed ? root.pointed.caption : (() => {
                    const lit = root.small.filter(q => q.isOn?.()).map(q => q.title)
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
