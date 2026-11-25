import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.parts
import qs.modules.lock
import qs.modules.services

// Settings: what happens when there's no input: dim, lock, screens off, suspend.
Item {
    id: root

    readonly property int pad: 24
    readonly property int colW: 520

    implicitWidth: colW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

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


    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.colW
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: "bolt"
            title: "Energy"
            subtitle: !Idle.enabled ? "Stays on" : Toggles.caffeine ? "Caffeine: stays on"
                      : Idle.mediaPlaying ? "Media playing: stays on" : "Locks after " + root.spoken(Idle.lockAfter)
            onBack: Engine.back()
        }

        Column {
            width: parent.width
            spacing: Config.spaceL

            SettingTile {
                width: parent.width
                title: "When there's no input"
                icon: "timer"
                checked: Idle.enabled
                onFlipped: on => Idle.enabled = on
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
            SettingTile {
                width: parent.width
                visible: Toggles.has("systemd-inhibit")
                title: "Caffeine: stay awake for now"
                icon: "coffee"
                checked: Toggles.caffeine
                onFlipped: on => Toggles.caffeine = on
            }
        }

        KeyHints {
            width: parent.width
            keys: [["← →", "wait"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
