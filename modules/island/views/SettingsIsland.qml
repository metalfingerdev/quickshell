import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.parts
import qs.modules.lock
import qs.modules.services

// Settings: the island's size, shape, hiding and clock.
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
            icon: "dock_to_bottom"
            title: "Island"
            subtitle: (Config.style === "notch" ? "Notch" : "Floating") + "  ·  " + Math.round(Config.scale * 100) + " %"
                      + (Engine.autoHide ? "  ·  Hides when not in use" : "")
            onBack: Engine.back()
        }

        Column {
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

            SettingTile {
                width: parent.width
                title: "Hide when not in use"
                icon: "visibility_off"
                checked: Engine.autoHide
                onFlipped: on => Engine.setAutoHide(on)
            }
            Segmented {
                visible: Engine.autoHide
                width: parent.width
                options: [{ key: "strip", label: "Handle when hidden" }, { key: "none", label: "No handle" }]
                current: Config.handle
                onPicked: key => Config.handle = key
            }

            SectionLabel { text: "Clock"; topPadding: Config.spaceXs }
            SettingTile {
                width: parent.width
                title: "24-hour clock"
                icon: "schedule"
                checked: Config.clock24
                onFlipped: on => Config.clock24 = on
            }
            Segmented {
                width: parent.width
                options: [{ key: "-1", label: "Week as the locale" }, { key: "1", label: "Monday" }, { key: "0", label: "Sunday" }]
                current: String(Config.firstDay)
                onPicked: key => Config.firstDay = Number(key)
            }

            SectionLabel { text: "Desktop"; topPadding: Config.spaceXs }
            SettingTile {
                width: parent.width
                title: "\"Activate Linux\""
                icon: "verified"
                checked: Config.activateLinux
                onFlipped: on => Config.activateLinux = on
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

        KeyHints {
            width: parent.width
            keys: [["← →", "size"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
