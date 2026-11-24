import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// The Control Center, on one grid: everything is a half, a third, a quarter or a fifth of the same
// width with the same gap, so the columns line up from top to bottom. Large tiles two a row
// (connections, then sound and power), toggles three a row, the levels side by side, the launcher's
// actions five a row, and the session along the foot. What lacks its tool stays, dimmed, so no row
// comes up short. No media card or notification list: Audio opens Media, Do not disturb the
// notification center.
Item {
    id: root

    readonly property int pad: 20
    readonly property int contentW: 600
    readonly property int gap: 10
    readonly property real half: (contentW - gap) / 2
    readonly property real third: (contentW - 2 * gap) / 3
    readonly property real quarter: (contentW - 3 * gap) / 4
    readonly property real fifth: (contentW - 4 * gap) / 5
    readonly property int tileH: 62
    readonly property int tileRadius: 24

    implicitWidth: contentW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function val(x) { return typeof x === "function" ? x() : x }
    function usable(item) { return (item.usable?.() ?? true) && (!item.tool || Toggles.has(item.tool)) }
    function open(view) { return x => Engine.open(view, x) }

    // Functions, not values: the list itself stays put when a setting flips, so the tile with the
    // keyboard focus isn't rebuilt under it. `opens` makes it an Android large tile.
    readonly property var toggles: [
        { letter: "d", title: "Do not disturb", opens: Engine.View.Notifications,
          isOn: () => Notifier.dnd, icon: () => Notifier.dnd ? Config.symbol.dnd : "do_not_disturb_off",
          status: () => Notifier.dnd ? "On" : Notifier.count > 0 ? Notifier.count + " notifications" : "Off",
          flip: () => Notifier.dnd = !Notifier.dnd },
        { letter: "m", title: "Microphone",
          isOn: () => Audio.hasMic && !Audio.micMuted, icon: () => Audio.hasMic && !Audio.micMuted ? "mic" : "mic_off",
          status: () => !Audio.hasMic ? "No microphone" : Audio.micMuted ? "Muted" : "On", flip: () => Audio.toggleMic() },
        { letter: "a", title: "Airplane mode",
          isOn: () => Toggles.airplane, icon: () => "flight", flip: () => Toggles.setAirplane(!Toggles.airplane) },
        { letter: "l", title: "Night light", tool: "hyprsunset",
          isOn: () => Toggles.nightLight, icon: () => "nightlight", status: () => Toggles.nightLight ? Toggles.warmth + " K" : "Off",
          flip: () => Toggles.nightLight = !Toggles.nightLight },
        { letter: "c", title: "Caffeine", tool: "systemd-inhibit",
          isOn: () => Toggles.caffeine, icon: () => "coffee", flip: () => Toggles.caffeine = !Toggles.caffeine },
        { letter: "k", title: "Dark theme", opens: Engine.View.Colours,
          isOn: () => Config.dark, icon: () => "dark_mode", flip: () => { Config.setDark(!Config.dark); Toggles.colorScheme(Config.dark) } }
    ]

    // The launcher's actions that have no tile above, in rows of a kind: capture and sound, asking and
    // typing, the desktop and its look. Either recording button stops whichever recording is on.
    readonly property var actions: [
        { letter: "s", title: "Screenshot", tool: "grimblast", icon: Config.symbol.screenshot,
          run: () => { Engine.close(); Toggles.screenshot() } },
        { letter: "r", title: () => Toggles.recording && !Toggles.recordingMic ? Toggles.recordTime : "Record", tool: "wf-recorder",
          icon: () => Toggles.recording && !Toggles.recordingMic ? "stop_circle" : Config.symbol.record,
          isOn: () => Toggles.recording && !Toggles.recordingMic, run: () => root.record(false) },
        { title: () => Toggles.recording && Toggles.recordingMic ? Toggles.recordTime : "With mic", tool: "wf-recorder",
          icon: () => Toggles.recording && Toggles.recordingMic ? "stop_circle" : "record_voice_over",
          isOn: () => Toggles.recording && Toggles.recordingMic, run: () => root.record(true) },
        { letter: "n", title: () => Toggles.memoRecording ? Toggles.memoTime : "Voice memo",
          icon: () => Toggles.memoRecording ? "stop_circle" : "graphic_eq",
          isOn: () => Toggles.memoRecording, run: () => Toggles.voiceMemo(!Toggles.memoRecording) },
        { letter: "x", title: "Mixer", icon: Config.symbol.mixer, run: root.open(Engine.View.Mixer) },

        { letter: "/", title: "Agent", icon: "smart_toy", run: root.open(Engine.View.Agent) },
        // as the launcher's Coding agent: Crush in kitty
        { title: "Coding agent", icon: "terminal", run: () => { Engine.close(); Toggles.launch(["kitty", "-e", "crush"]) } },
        { letter: "v", title: "Clipboard", icon: "content_paste", run: root.open(Engine.View.Clipboard) },
        { letter: ".", title: "Emoji", icon: "mood", run: () => { Engine.launcherFilter = "emoji"; Engine.open(Engine.View.Launcher) } },
        { title: "Calendar", icon: Config.symbol.calendar, run: root.open(Engine.View.Clock) },

        { letter: "g", title: "Workspaces", icon: Config.symbol.overview, run: root.open(Engine.View.Workspaces) },
        { letter: "h", title: "Tabs", icon: Config.symbol.hub, run: root.open(Engine.View.Tabs) },
        { title: "Theme", icon: Config.symbol.theme, run: root.open(Engine.View.Theme) },
        { title: "Wallpaper", icon: Config.symbol.wallpaper, run: root.open(Engine.View.Wallpapers) },
        { title: "Shuffle", icon: "shuffle", run: () => Wallpaper.random() }
    ]
    // record the screen, not the Control Center
    function record(mic) {
        if (Toggles.recording) return Toggles.record(false, false)
        Engine.close()
        Toggles.record(true, mic)
    }

    readonly property var session: [
        { title: "Lock", icon: "lock", run: () => { Engine.close(); Session.run("lock") } },
        { title: "Suspend", icon: "bedtime", run: () => { Engine.close(); Session.run("suspend") } },
        { title: "Hibernate", icon: "ac_unit", run: () => { Engine.close(); Session.run("hibernate") } },
        { letter: "p", title: "Power", icon: Config.symbol.power, run: root.open(Engine.View.Power) }
    ]

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

    // An action: its icon over its name, in a circle as the tiles' are.
    component Action: Rectangle {
        id: action
        property string icon: ""
        property string title: ""
        property bool on: false
        property string shortcut: ""
        property bool keyboardSelected: activeFocus && Config.focusVisible
        readonly property color ink: on ? Config.primaryInk : Config.text
        signal clicked(real sceneX)
        function activate() { clicked(-1) }

        activeFocusOnTab: true
        width: root.fifth
        height: 76
        radius: root.tileRadius
        color: Config.state(on ? Config.primary : Config.container, ink, area.containsMouse, area.pressed || keyboardSelected)
        opacity: enabled ? 1 : 0.38
        Behavior on color { ColorAnimation { duration: 160 } }

        Column {
            anchors.centerIn: parent
            width: parent.width - 16
            spacing: 6

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 36
                height: 36
                radius: 18
                color: action.on ? Config.primaryDeep : Config.high

                Icon {
                    anchors.centerIn: parent
                    name: action.icon
                    size: 20
                    filled: action.on
                    color: action.ink
                }
            }
            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: action.title
                elide: Text.ElideRight
                color: action.ink
                font.pixelSize: Config.small + 1
                font.weight: Font.Medium
            }
        }
        ClickArea {
            id: area
            onClicked: mouse => action.clicked(area.sceneX(mouse))
        }
        FocusRing { on: action.keyboardSelected }
        KeyBadge { key: action.shortcut }
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.contentW
        spacing: 14

        Header {
            width: parent.width
            title: "Control Center"
            subtitle: Qt.formatDateTime(clock.date, "dddd, d MMMM  ·  HH:mm")
            onBack: Engine.back()

            Pill { kind: "text"; icon: Config.symbol.settings; iconSize: 22; shortcut: "i"; onClicked: Engine.open(Engine.View.Settings) }
        }

        Grid {
            columns: 2
            spacing: root.gap

            QuickTile {
                width: root.half
                implicitHeight: root.tileH
                radius: root.tileRadius
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
                implicitHeight: root.tileH
                radius: root.tileRadius
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
                implicitHeight: root.tileH
                radius: root.tileRadius
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
            // nothing to switch: lit while the charger is in, and both halves open Battery
            QuickTile {
                width: root.half
                implicitHeight: root.tileH
                radius: root.tileRadius
                icon: Energy.glyph
                title: "Battery"
                subtitle: !Energy.present ? "No battery" : Energy.percent < 0 ? "…"
                    : Energy.percent + "%" + (Energy.charging ? "  ·  Charging" : Energy.plugged ? "  ·  Plugged in"
                    : Energy.minutesLeft >= 0 ? "  ·  " + Energy.duration(Energy.minutesLeft) + " left" : "")
                on: Energy.plugged
                split: true
                shortcut: "e"
                enabled: Energy.present
                onToggled: Engine.open(Engine.View.Battery)
                onClicked: x => Engine.open(Engine.View.Battery, x)
            }
        }

        Grid {
            columns: 3
            spacing: root.gap

            Repeater {
                model: root.toggles

                QuickTile {
                    required property var modelData
                    width: root.third
                    implicitHeight: root.tileH
                    radius: root.tileRadius
                    icon: modelData.icon()
                    title: modelData.title
                    on: modelData.isOn()
                    subtitle: modelData.status?.() ?? (on ? "On" : "Off")
                    split: modelData.opens !== undefined
                    shortcut: modelData.letter
                    enabled: root.usable(modelData)
                    onToggled: modelData.flip()
                    onClicked: x => Engine.open(modelData.opens, x)
                }
            }
        }

        Row {
            spacing: root.gap

            VolumeSlider {
                width: Backlight.available ? root.half : root.contentW
                implicitHeight: 48
                enabled: Audio.sink !== null
            }
            BrightnessSlider {
                visible: Backlight.available
                width: root.half
                implicitHeight: 48
            }
        }

        // the power profile in thirds, lit as the tiles are (not the outlined Segmented of other views)
        Row {
            visible: Toggles.profile !== ""
            spacing: root.gap

            Repeater {
                model: Toggles.profiles

                Pill {
                    required property var modelData
                    width: root.third
                    implicitHeight: 48
                    icon: modelData.icon
                    text: modelData.label
                    active: Toggles.profile === modelData.key
                    onClicked: Toggles.setProfile(modelData.key)
                }
            }
        }

        Grid {
            columns: 5
            spacing: root.gap

            Repeater {
                model: root.actions

                Action {
                    required property var modelData
                    icon: root.val(modelData.icon)
                    title: root.val(modelData.title)
                    on: modelData.isOn?.() ?? false
                    shortcut: modelData.letter ?? ""
                    enabled: root.usable(modelData)
                    onClicked: x => modelData.run(x)
                }
            }
        }

        Row {
            spacing: root.gap

            Repeater {
                model: root.session

                Pill {
                    required property var modelData
                    width: root.quarter
                    implicitHeight: 48
                    icon: modelData.icon
                    text: modelData.title
                    shortcut: modelData.letter ?? ""
                    onClicked: x => modelData.run(x)
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["Space", "switch"], ["Enter", "open"], ["+ −", "volume"], ["[ ]", "brightness"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
