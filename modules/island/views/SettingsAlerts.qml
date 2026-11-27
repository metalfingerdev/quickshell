import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.parts
import qs.modules.lock
import qs.modules.services

// Settings: how notifications pop up and sound, and which toasts show.
Item {
    id: root

    readonly property int pad: 24
    readonly property int colW: 520

    implicitWidth: colW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.colW
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: "notifications"
            title: "Notifications"
            subtitle: (Notifier.dnd ? "Do not disturb is on" : "Popups: " + Notifier.popupLength) + (Sounds.enabled ? "  ·  sounds" : "")
            onBack: Engine.back()
        }

        Column {
            width: parent.width
            spacing: Config.spaceL

            // for a notification that doesn't say how long it should stay; a critical one stays
            SectionLabel { text: "Popups stay"; topPadding: Config.spaceS }
            Segmented {
                width: parent.width
                options: [{ key: "short", label: "5 s", shortcut: "1" }, { key: "normal", label: "10 s", shortcut: "2" }, { key: "long", label: "20 s", shortcut: "3" }]
                current: Notifier.popupLength
                onPicked: key => Notifier.popupLength = key
            }
            SettingTile {
                width: parent.width
                title: "Do not disturb"
                shortcut: "d"
                icon: "do_not_disturb_on"
                checked: Notifier.dnd
                onFlipped: on => Notifier.dnd = on
            }
            SettingTile {
                width: parent.width
                title: "Sounds"
                shortcut: "s"
                icon: "volume_up"
                checked: Sounds.enabled
                onFlipped: on => Sounds.enabled = on
            }

            SectionLabel { text: "Toasts"; topPadding: Config.spaceXs }
            SettingTile {
                width: parent.width
                title: "Volume, brightness, microphone"
                shortcut: "l"
                icon: "tune"
                checked: Config.levelToasts
                onFlipped: on => Config.levelToasts = on
            }
            SettingTile {
                width: parent.width
                title: "Switching workspace"
                shortcut: "w"
                icon: "view_carousel"
                checked: Config.switcherToasts
                onFlipped: on => Config.switcherToasts = on
            }
        }

        KeyHints {
            width: parent.width
            keys: [["⏎", "switch"], ["1–3", "popup time"], ["D S L W", "a switch"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
