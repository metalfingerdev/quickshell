import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services
import "../../services/ControlLayout.js" as ControlLayout

// The Control Center as a bento grid, after Android 16's quick settings (Material 3 Expressive): six
// columns of tiles one to six cells wide. What is on it, and in what order, is a list of module names
// (ControlLayout.js packs it; Config.controlLayout keeps it, empty meaning the default): Edit puts
// the grid in your hands: drag a module to where you want it, or Shift+arrows, Delete takes one off, and
// the ones not on it are added from below. Tiles round out to a pill when on and give a little when
// pressed; the line under the grid names the small tile you point at, or says what's on.
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

    // ── what is on the grid ──────────────────────────────────────────────────────────────────────────
    property bool editing: false
    readonly property var ids: { const c = ControlLayout.clean(Config.controlLayout); return c.length > 0 ? c : ControlLayout.defaults }
    // a power mode the machine doesn't have leaves no hole, except while editing, where it can be taken off
    readonly property var shownIds: editing ? ids : ids.filter(id => id !== "profile" || Toggles.profile !== "")
    readonly property var packed: ControlLayout.pack(shownIds, 6)
    function setIds(next) { Config.controlLayout = next }
    function remove(id) { setIds(ControlLayout.without(ids, id)) }
    function add(id) { setIds(ids.concat([id])) }
    function moveTo(id, target) {
        const from = ids.indexOf(id), to = ids.indexOf(target)
        if (from >= 0 && to >= 0 && from !== to) setIds(ControlLayout.move(ids, from, to))
        Qt.callLater(() => focusSlot(id))
    }
    // the module under a point of the grid, for the pointer and for the arrows
    function slotAt(x, y) {
        return packed.items.find(m => x >= cx(m.col) && x < cx(m.col) + cw(m.w) && y >= cy(m.row) && y < cy(m.row) + ch(m.h)) ?? null
    }
    function focusSlot(id) {
        for (let i = 0; i < slots.count; i++) if (slots.itemAt(i)?.mod.id === id) { slots.itemAt(i).forceActiveFocus(); return }
    }
    // Shift+arrow: the module takes the place of its neighbour that way (by cells, so up and down work too)
    function shove(dx, dy) {
        const here = Window.activeFocusItem?.mod
        if (!editing || !here) return false
        const to = slotAt(cx(here.col) + (dx > 0 ? cw(here.w) + gap / 2 : dx < 0 ? -gap / 2 : 1),
                          cy(here.row) + (dy > 0 ? ch(here.h) + gap / 2 : dy < 0 ? -gap / 2 : 1))
        if (to) moveTo(here.id, to.id)
        return true
    }
    function edit(on) { editing = on; if (!on) pointed = null }

    // ── the modules ──────────────────────────────────────────────────────────────────────────────────
    // `kind` says how it is drawn; the rest is what a small tile or a catalogue entry needs. Functions, not
    // values: the lists stay put when a setting flips, so the tile with the keyboard focus isn't rebuilt under it.
    readonly property var defs: ({
        wifi: { kind: "wifi", title: "Wi-Fi", icon: "wifi" },
        bluetooth: { kind: "bluetooth", title: "Bluetooth", icon: "bluetooth" },
        volume: { kind: "volume", title: "Volume", icon: "volume_up" },
        brightness: { kind: "brightness", title: "Brightness", icon: "brightness_high" },
        dnd: { kind: "dnd", title: "Do not disturb", icon: "do_not_disturb_on" },
        battery: { kind: "battery", title: "Battery", icon: "battery_full" },
        agent: { kind: "agent", title: "Agent", icon: "smart_toy" },
        profile: { kind: "profile", title: "Power mode", icon: "speed" },
        session: { kind: "session", title: "Lock, suspend, restart", icon: "power_settings_new" },
        wallpaper: { kind: "wallpaper", title: "Wallpaper", icon: "wallpaper" },
        weather: { kind: "weather", title: "Weather", icon: "partly_cloudy_day" },
        event: { kind: "event", title: "Next event", icon: "event" },
        system: { kind: "system", title: "Processor and memory", icon: "monitor_heart" },
        nowplaying: { kind: "nowplaying", title: "Now playing", icon: "music_note" },
        airplane: { kind: "small", title: "Airplane mode", icon: "flight", isOn: () => Toggles.airplane,
                    run: () => Toggles.setAirplane(!Toggles.airplane) },
        mic: { kind: "small", letter: "m", title: "Microphone", usable: () => Audio.hasMic,
               icon: () => Audio.hasMic && !Audio.micMuted ? "mic" : "mic_off", isOn: () => Audio.hasMic && !Audio.micMuted,
               status: () => !Audio.hasMic ? "No microphone" : Audio.micMuted ? "Muted" : "On", run: () => Audio.toggleMic() },
        mixer: { kind: "small", letter: "x", title: "Mixer", icon: Config.symbol.mixer, status: "Volume for each app",
                 run: root.open(Engine.View.Mixer) },
        nightlight: { kind: "small", letter: "l", title: "Night light", tool: "hyprsunset", icon: "nightlight", isOn: () => Toggles.nightLight,
                      status: () => Toggles.nightLight ? Toggles.warmth + " K" : "Off", run: () => Toggles.nightLight = !Toggles.nightLight },
        dark: { kind: "small", letter: "k", title: "Dark theme", icon: "dark_mode", isOn: () => Config.dark,
                run: () => Config.setDark(!Config.dark) },
        notifications: { kind: "small", title: "Notifications", icon: Config.symbol.notifications, count: () => Notifier.count,
                         status: () => Notifier.count > 0 ? Notifier.count + " waiting" : "None", run: root.open(Engine.View.Notifications) },
        caffeine: { kind: "small", letter: "c", title: "Caffeine", tool: "systemd-inhibit", icon: "coffee", isOn: () => Toggles.caffeine,
                    status: () => Toggles.caffeine ? "Staying awake" : "Off", run: () => Toggles.caffeine = !Toggles.caffeine },
        screenshot: { kind: "small", letter: "s", title: "Screenshot", tool: "grimblast", icon: Config.symbol.screenshot,
                      status: "Select an area", run: () => { Engine.close(); Toggles.screenshot() } },
        record: { kind: "small", letter: "r", title: "Record the screen", tool: "wf-recorder",
                  icon: () => Toggles.recording && !Toggles.recordingMic ? "stop_circle" : Config.symbol.record,
                  isOn: () => Toggles.recording && !Toggles.recordingMic,
                  status: () => Toggles.recording && !Toggles.recordingMic ? Toggles.recordTime : "", run: () => root.record(false) },
        recordmic: { kind: "small", title: "Record with the microphone", tool: "wf-recorder",
                     icon: () => Toggles.recording && Toggles.recordingMic ? "stop_circle" : "record_voice_over",
                     isOn: () => Toggles.recording && Toggles.recordingMic,
                     status: () => Toggles.recording && Toggles.recordingMic ? Toggles.recordTime : "", run: () => root.record(true) },
        memo: { kind: "small", letter: "n", title: "Voice memo", icon: () => Toggles.memoRecording ? "stop_circle" : "graphic_eq",
                isOn: () => Toggles.memoRecording, status: () => Toggles.memoRecording ? Toggles.memoTime : "",
                run: () => Toggles.voiceMemo(!Toggles.memoRecording) },
        clipboard: { kind: "small", letter: "v", title: "Clipboard", icon: "content_paste", status: "Everything copied",
                     run: root.open(Engine.View.Clipboard) },
        emoji: { kind: "small", letter: ".", title: "Emoji", icon: "mood", status: "And symbols, kaomoji",
                 run: () => { Engine.launcherFilter = "emoji"; Engine.open(Engine.View.Launcher) } },
        codeagent: { kind: "small", title: "Coding agent", icon: "code", status: "Crush, in kitty", run: root.launch(["kitty", "-e", "crush"]) },
        picker: { kind: "small", letter: "u", title: "Colour picker", tool: "hyprpicker", icon: "colorize",
                  status: "A colour from anywhere, copied", run: () => { Engine.close(); Toggles.pickColour("copy") } },
        shuffle: { kind: "small", title: "Shuffle the wallpaper", icon: "shuffle", run: () => Wallpaper.random() },
        colours: { kind: "small", title: "Colours", icon: Config.symbol.colours, status: "Palettes, an accent", run: root.open(Engine.View.Colours) },
        theme: { kind: "small", title: "Theme", icon: Config.symbol.theme, run: root.open(Engine.View.Theme) },
        workspaces: { kind: "small", letter: "g", title: "Workspaces", icon: Config.symbol.overview, run: root.open(Engine.View.Workspaces) },
        media: { kind: "small", title: "Media", icon: Config.symbol.media, status: "What's playing", run: root.open(Engine.View.Media) },
        calendar: { kind: "small", title: "Calendar", icon: Config.symbol.calendar, run: root.open(Engine.View.Clock) },
        files: { kind: "small", letter: "f", title: "Files", icon: "folder", status: "Yazi, in kitty", run: root.launch(["kitty", "-e", "yazi"]) },
        terminal: { kind: "small", letter: "t", title: "Terminal", icon: "terminal", status: "Kitty", run: root.launch(["kitty"]) },
        tasks: { kind: "small", letter: "o", title: "Tasks", icon: "checklist", count: () => Tasks.open,
                 status: () => Tasks.open > 0 ? Tasks.open + " not done" : "None", run: root.open(Engine.View.Tasks) },
        nixos: { kind: "small", letter: "h", title: "NixOS", icon: "history", status: "Generations, updates", run: root.open(Engine.View.Generations) },
        favourites: { kind: "small", title: "Favourites", icon: "keep", status: () => Pins.apps.length + " pinned", run: root.open(Engine.View.Dock) },
        tray: { kind: "small", title: "Tray", icon: "widgets", status: () => Tray.items.length + " apps", run: root.open(Engine.View.Tray) },
        lock: { kind: "small", title: "Lock", icon: "lock", run: () => { Engine.close(); Session.run("lock") } },
        settings: { kind: "small", letter: "i", title: "Settings", icon: Config.symbol.settings, run: root.open(Engine.View.Settings) }
    })
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

    Component.onCompleted: { Toggles.readProfile(); if (Engine.editControls) { Engine.editControls = false; editing = true } }

    // levels from anywhere in the view (the tiles' letters are their shortcuts); in Edit, Shift+arrows move
    // the module with the focus and Delete takes it off
    Keys.onPressed: event => {
        const t = event.text
        if (editing && (event.modifiers & Qt.ShiftModifier) && [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down].includes(event.key)) {
            event.accepted = shove(event.key === Qt.Key_Right ? 1 : event.key === Qt.Key_Left ? -1 : 0, event.key === Qt.Key_Down ? 1 : event.key === Qt.Key_Up ? -1 : 0)
            return
        }
        if (editing && event.key === Qt.Key_Backspace) { edit(false); event.accepted = true; return }
        if (editing && event.key === Qt.Key_Delete) {
            const m = Window.activeFocusItem?.mod
            if (m) { remove(m.id); event.accepted = true }
            return
        }
        if (editing) { event.accepted = false; return }
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
        radius: on ? height / 2 : 18
        Behavior on radius { Motion {} }
        scale: area.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: Config.durationFast; easing.type: Easing.OutCubic } }
        color: Config.state(on ? Config.primary : Config.tile, ink, area.containsMouse, area.pressed || keyboardSelected)
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

    // A wide tile: Android's large tile, rounding out the same way.
    component Wide: QuickTile {
        anchors.fill: parent
        split: true
        radius: on ? height / 2 : 22
        Behavior on radius { Motion {} }
    }

    // A card of its own: an icon, a title, one line under it, and optionally a button at the end.
    component Info: Rectangle {
        id: card
        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property string action: ""
        property bool keyboardSelected: activeFocus && Config.focusVisible
        signal clicked(real sceneX)
        signal acted()
        function activate() { clicked(-1) }
        Accessible.role: Accessible.Button
        Accessible.name: title
        Accessible.description: subtitle
        Accessible.onPressAction: activate()

        activeFocusOnTab: true
        anchors.fill: parent
        radius: 22
        color: Config.state(Config.tile, Config.text, area.containsMouse, area.pressed || keyboardSelected)
        Behavior on color { ColorAnimation { duration: Config.durationFast } }
        scale: area.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: Config.durationFast; easing.type: Easing.OutCubic } }

        ClickArea { id: area; onClicked: mouse => card.clicked(area.sceneX(mouse)) }
        Icon { id: glyph; x: Config.spaceL; anchors.verticalCenter: parent.verticalCenter; name: card.icon; size: 24; color: Config.primary }
        Column {
            anchors { left: glyph.right; leftMargin: Config.spaceM; right: act.left; rightMargin: Config.spaceS; verticalCenter: parent.verticalCenter }
            Label { width: parent.width; text: card.title; elide: Text.ElideRight; font.weight: Font.DemiBold }
            Label { width: parent.width; text: card.subtitle; elide: Text.ElideRight; color: Config.dim; font.pixelSize: Config.small + 1; visible: text !== "" }
        }
        Item {
            id: act
            visible: card.action !== ""
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: visible ? 52 : 0
            height: parent.height
            Icon { anchors.centerIn: parent; name: card.action; size: 26; filled: true; color: Config.text }
            ClickArea { onClicked: card.acted() }
        }
        FocusRing { on: card.keyboardSelected }
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
        color: Config.state(selected ? Config.primary : Config.tile, ink, area.containsMouse, area.pressed || keyboardSelected)
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

    // one place on the grid: the module in its cells, and in Edit a ring, a badge to take it off, and
    // the keyboard focus (the module itself takes none then)
    component Slot: Item {
        id: slot
        required property var mod
        readonly property var def: root.defs[mod.id] ?? ({ kind: "small", title: mod.id, icon: "help" })
        readonly property bool ring: root.editing && activeFocus && Config.focusVisible

        x: root.cx(mod.col); y: root.cy(mod.row)
        width: root.cw(mod.w); height: root.ch(mod.h)
        activeFocusOnTab: root.editing

        Loader {
            anchors.fill: parent
            enabled: !root.editing
            opacity: root.editing && root.drag.id === slot.mod.id ? 0.35 : 1
            sourceComponent: ({ small: cSmall, wifi: cWifi, bluetooth: cBluetooth, volume: cVolume, brightness: cBrightness,
                                dnd: cDnd, battery: cBattery, agent: cAgent, profile: cProfile, session: cSession,
                                wallpaper: cWallpaper, weather: cWeather, event: cEvent, system: cSystem, nowplaying: cNowPlaying })[def.kind]
        }
        Rectangle {
            visible: root.editing
            anchors.fill: parent
            radius: 22
            color: "transparent"
            border.width: slot.ring ? 3 : 2
            border.color: slot.ring ? Config.primary : Config.outline
        }
        Rectangle {
            visible: root.editing
            x: parent.width - width + 6; y: -6
            width: 24; height: 24; radius: 12
            color: Config.primary
            Icon { anchors.centerIn: parent; name: "remove"; size: 16; color: Config.primaryInk }
        }
        FocusRing { on: slot.ring }

        Component { id: cSmall; Small {
            anchors.fill: parent
            icon: root.val(slot.def.icon)
            on: slot.def.isOn?.() ?? false
            count: slot.def.count?.() ?? 0
            caption: root.caption(slot.def)
            shortcut: slot.def.letter ?? ""
            enabled: root.usable(slot.def)
            onClicked: x => slot.def.run(x)
        } }
        Component { id: cWifi; Wide {
            focus: slot.mod.id === "wifi"
            icon: Net.icon
            title: Net.ethernet && !Net.current ? "Ethernet" : "Wi-Fi"
            subtitle: Net.attempt ? "Connecting…" : Net.current ? Net.current.name
                    : Net.ethernet ? "Connected" : Net.summary
            on: Net.wifiEnabled || Net.ethernet
            shortcut: "w"
            enabled: Net.available
            onToggled: Net.setWifi(!Net.wifiEnabled)
            onClicked: x => Engine.open(Engine.View.Network, x)
        } }
        Component { id: cBluetooth; Wide {
            icon: Bluez.icon
            title: "Bluetooth"
            subtitle: Bluez.summary
            on: Bluez.enabled
            shortcut: "b"
            enabled: Bluez.available && !Bluez.blocked
            onToggled: Bluez.setEnabled(!Bluez.enabled)
            onClicked: x => Engine.open(Engine.View.Bluetooth, x)
        } }
        // the icon mutes, as the Audio tile's did; outputs are in Mixer
        Component { id: cVolume; VolumeSlider { anchors.fill: parent; enabled: Audio.sink !== null } }
        Component { id: cBrightness; BrightnessSlider { anchors.fill: parent; enabled: Backlight.available } }
        Component { id: cDnd; Wide {
            icon: Notifier.dnd ? Config.symbol.dnd : "do_not_disturb_off"
            title: "Do not disturb"
            subtitle: Notifier.dnd ? "On" : "Off"
            on: Notifier.dnd
            shortcut: "d"
            onToggled: Notifier.dnd = !Notifier.dnd
            onClicked: x => Engine.open(Engine.View.Notifications, x)
        } }
        // nothing to switch: lit while the charger is in, and both halves open Battery
        Component { id: cBattery; Wide {
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
        } }
        Component {
            id: cAgent
            Rectangle {
                id: agentCard
                readonly property string shortcut: "/"
                property bool keyboardSelected: activeFocus && Config.focusVisible
                readonly property color ink: Config.secondaryInk
                function activate() { Engine.open(Engine.View.Agent) }

                activeFocusOnTab: true
                anchors.fill: parent
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
        }
        Component {
            id: cWallpaper
            ClippingRectangle {
                id: wallCard
                property bool keyboardSelected: activeFocus && Config.focusVisible
                function activate() { Engine.open(Engine.View.Wallpapers) }

                activeFocusOnTab: true
                anchors.fill: parent
                radius: 28
                color: Config.tile
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
        }

        Component { id: cProfile; Row {
            anchors.verticalCenter: parent.verticalCenter
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
        } }
        Component { id: cSession; Row {
            anchors.verticalCenter: parent.verticalCenter
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
        } }
        Component { id: cWeather; Info {
            readonly property var today: Weather.current ? Weather.forecast.days[0] ?? null : null
            icon: Weather.current ? Weather.icon(Weather.forecast.now.code, Weather.forecast.now.day) : "partly_cloudy_day"
            title: Weather.current ? Weather.degrees(Weather.forecast.now.temp) : "Weather"
            subtitle: !Weather.current ? "Set a place" : today ? Weather.degrees(today.max) + " / " + Weather.degrees(today.min) : ""
            onClicked: x => Engine.open(Engine.View.Weather, x)
        } }
        Component { id: cEvent; Info {
            icon: Config.symbol.calendar
            title: Calendar.next !== null ? Calendar.title(Calendar.next) : "Calendar"
            subtitle: Calendar.next !== null ? Calendar.when(Calendar.next) : "Nothing next"
            onClicked: x => Engine.open(Calendar.next !== null ? Engine.View.Agenda : Engine.View.Clock, x)
        } }
        // read only while it is on the grid and this is open
        Component { id: cSystem; Info {
            icon: "monitor_heart"
            title: Math.round(SysStats.cpu * 100) + " %"
            subtitle: SysStats.mem > 0 ? "Memory " + Math.round(SysStats.mem * 100) + " %" : "Processor"
            Component.onCompleted: SysStats.watch(true)
            Component.onDestruction: SysStats.watch(false)
            onClicked: x => Engine.open(Engine.View.System, x)
        } }
        Component { id: cNowPlaying; Info {
            icon: Config.symbol.media
            title: Players.hasTrack ? Players.active.trackTitle : "Nothing playing"
            subtitle: Players.hasTrack ? Players.active.trackArtist ?? "" : ""
            action: Players.hasTrack && Players.canToggle ? (Players.playing ? "pause" : "play_arrow") : ""
            onActed: Players.toggle()
            onClicked: x => Engine.open(Engine.View.Media, x)
        } }
    }

    // The grid in Edit: one pointer handler for all of it. A press on a module's badge takes it off; a press
    // anywhere else picks it up, and where it's let go it takes the place of the module there.
    property var drag: ({ id: "", x: 0, y: 0 })
    function over(m, x, y) { return x >= cx(m.col) + cw(m.w) - 18 && y < cy(m.row) + 18 }

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
                onClicked: root.editing ? root.edit(false) : Engine.back()
            }
            Column {
                anchors { left: back.right; leftMargin: Config.spaceL; verticalCenter: parent.verticalCenter }

                Text {
                    text: root.editing ? "Edit" : Qt.formatDateTime(clock.date, Config.timeFormat)
                    color: Config.text
                    font.family: Config.font
                    font.pixelSize: 42
                    font.weight: Font.Normal
                }
                Label {
                    text: root.editing ? "Drag, or Shift+arrows. Delete takes one off." : Qt.formatDateTime(clock.date, "dddd, d MMMM")
                    color: Config.dim
                }
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: Config.spaceS

                Pill {
                    visible: root.editing
                    kind: "text"
                    text: "Reset"
                    shortcut: "r"
                    onClicked: root.setIds([])
                }
                Pill {
                    kind: root.editing ? "filled" : "text"
                    icon: root.editing ? "check" : "edit"
                    text: root.editing ? "Done" : ""
                    iconSize: 22
                    shortcut: "e"
                    onClicked: root.edit(!root.editing)
                }
                Pill {
                    visible: !root.editing
                    kind: "text"
                    icon: Config.symbol.settings
                    iconSize: 22
                    shortcut: "i"
                    onClicked: Engine.open(Engine.View.Settings)
                }
            }
        }

        Item {
            id: grid
            width: parent.width
            height: Math.max(0, root.cy(root.packed.rows) - root.gap)

            Repeater {
                id: slots
                model: root.packed.items
                Slot { required property var modelData; mod: modelData }
            }

            // the module being carried
            Rectangle {
                visible: root.drag.id !== ""
                readonly property var m: root.packed.items.find(i => i.id === root.drag.id) ?? ({ w: 1, h: 1 })
                x: root.drag.x - width / 2; y: root.drag.y - height / 2
                width: root.cw(m.w); height: root.ch(m.h)
                radius: 22
                color: Config.primary
                opacity: 0.6
                z: 20
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.editing
                visible: root.editing
                z: 10
                onPressed: mouse => {
                    const m = root.slotAt(mouse.x, mouse.y)
                    if (!m) return
                    if (root.over(m, mouse.x, mouse.y)) { root.remove(m.id); return }
                    root.drag = { id: m.id, x: mouse.x, y: mouse.y }
                }
                onPositionChanged: mouse => { if (root.drag.id !== "") root.drag = { id: root.drag.id, x: mouse.x, y: mouse.y } }
                onReleased: mouse => {
                    const target = root.slotAt(mouse.x, mouse.y), id = root.drag.id
                    root.drag = { id: "", x: 0, y: 0 }
                    if (id !== "" && target) root.moveTo(id, target.id)
                }
            }
        }

        // what can be added: everything that isn't on the grid
        Flow {
            visible: root.editing
            width: parent.width
            spacing: Config.spaceS

            Repeater {
                model: ControlLayout.missing(root.ids)
                Pill {
                    required property string modelData
                    icon: "add"
                    text: root.defs[modelData]?.title ?? modelData
                    onClicked: root.add(modelData)
                }
            }
        }

        // what the pointer is on, or what's on
        Label {
            visible: !root.editing
            width: parent.width
            leftPadding: Config.spaceXs
            elide: Text.ElideRight
            color: root.pointed ? Config.text : Config.dim
            text: root.pointed ? root.pointed.caption : (() => {
                const lit = root.ids.map(id => root.defs[id]).filter(q => q?.isOn?.()).map(q => q.title)
                return lit.length > 0 ? "On: " + lit.join(", ") : "Point at a tile for its name"
            })()
        }

        KeyHints {
            width: parent.width
            keys: root.editing ? [["⇧ ←↑↓→", "move"], ["Del", "take off"], ["R", "reset"], ["E ⌫", "done"]]
                               : [["Space", "switch"], ["Enter", "open"], ["+ −", "volume"], ["[ ]", "brightness"], ["E", "edit"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
