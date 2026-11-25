import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

Item {
    id: root

    readonly property int pad: 24
    readonly property int tileH: 72
    readonly property int maxRows: 4

    function glyph(d) {
        const i = d.icon || ""
        if (i.includes("headset") || i.includes("headphone")) return "headphones"
        if (i.startsWith("audio")) return "speaker"
        if (i.includes("mouse")) return "mouse"
        if (i.includes("keyboard")) return "keyboard"
        if (i.includes("gaming")) return "stadia_controller"
        if (i.includes("phone")) return "smartphone"
        if (i.includes("computer")) return "computer"
        if (i.includes("tablet")) return "tablet"
        if (i.includes("watch")) return "watch"
        return "bluetooth"
    }

    Component.onDestruction: Bluez.scan(false)

    implicitWidth: 720
    implicitHeight: column.implicitHeight + 2 * pad

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: "bluetooth"
            title: "Bluetooth"
            subtitle: Bluez.summary
            onBack: Engine.back()

            Pill {
                visible: Bluez.enabled
                implicitHeight: 48
                icon: "radar"
                text: Bluez.scanning ? "Stop" : "Search"
                active: Bluez.scanning
                shortcut: "s"
                onClicked: Bluez.scan(!Bluez.scanning)
            }
        }

        ListSection {
            ListEntry {
                flat: true
                focus: !Bluez.enabled || Bluez.devices.length === 0
                lit: Bluez.enabled
                icon: Bluez.icon
                title: "Bluetooth"
                subtitle: !Bluez.available ? "No adapter" : Bluez.blocked ? "Blocked by rfkill" : !Bluez.enabled ? "Off" : Bluez.summary
                shortcut: "b"
                enabled: Bluez.available && !Bluez.blocked
                onClicked: Bluez.setEnabled(!Bluez.enabled)
            }
        }

        Label {
            visible: text !== ""
            width: parent.width
            topPadding: Config.spaceS
            bottomPadding: Config.spaceS
            horizontalAlignment: Text.AlignHCenter
            text: !Bluez.available ? "No Bluetooth adapter"
                : !Bluez.enabled ? "Turn Bluetooth on to see devices"
                : Bluez.devices.length === 0 ? (Bluez.scanning ? "Searching…" : "No devices yet: Search to find some") : ""
            color: Config.dim
        }

        ScrollList {
            id: list
            visible: Bluez.enabled && Bluez.devices.length > 0
            width: parent.width
            maxHeight: Math.min(6 * 68 + 2 * 48 + 2 * inset, Engine.room - 300)

            Column {
                width: list.innerWidth
                spacing: Config.spaceM

                component DeviceRow: ListEntry {
                    required property var device
                    required property int number
                    flat: true
                    focus: number === 0                         // the keyboard starts on the list
                    lit: device.connected
                    icon: root.glyph(device)
                    title: device.name || device.address
                    subtitle: Bluez.status(device)
                    shortcut: number < 9 ? String(number + 1) : ""
                    onClicked: Bluez.activate(device)
                    Icon { visible: device.connected; name: "check"; size: 20; color: Config.primary }
                }

                ListSection {
                    title: "My devices"
                    visible: mine.count > 0
                    Repeater {
                        id: mine
                        model: Bluez.enabled ? Bluez.devices.filter(d => d.paired || d.connected) : []
                        DeviceRow { required property var modelData; required property int index; device: modelData; number: index }
                    }
                }
                ListSection {
                    title: "Other devices"
                    visible: other.count > 0
                    Repeater {
                        id: other
                        model: Bluez.enabled ? Bluez.devices.filter(d => !(d.paired || d.connected)) : []
                        DeviceRow { required property var modelData; required property int index; device: modelData; number: index + mine.count }
                    }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["1–9", "a device"], ["B", "Bluetooth on/off"], ["S", "search"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
