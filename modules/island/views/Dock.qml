import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// Favourite apps (Pins), big and in their order; a digit starts the one in that place. They're pinned
// in the launcher (Ctrl+P), where they also come first.
Item {
    id: root

    readonly property int pad: 24
    readonly property int cell: 96
    readonly property int perRow: 6
    // Reordering rebuilds the tiles, which drops focus: the app to give it back to
    property string refocus: ""

    implicitWidth: Math.max(480, Math.min(Pins.apps.length, perRow) * (cell + Config.spaceS) - Config.spaceS + 2 * pad)
    implicitHeight: column.implicitHeight + 2 * pad

    function run(app) {
        Pins.run(app)
        Engine.close()
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceM

        Header {
            width: parent.width
            icon: "keep"
            title: "Favourites"
            subtitle: Pins.apps.length === 0 ? "Apps you pin" : Pins.apps.length === 1 ? "1 app" : Pins.apps.length + " apps"
            onBack: Engine.back()

            Pill {
                implicitHeight: 48
                kind: "text"
                icon: Config.symbol.launcher
                shortcut: "d"
                onClicked: Engine.open(Engine.View.Launcher)
            }
        }

        Grid {
            visible: Pins.apps.length > 0
            columns: root.perRow
            spacing: Config.spaceS

            Repeater {
                model: Pins.apps

                Rectangle {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool keyboardSelected: activeFocus && Config.focusVisible
                    readonly property string shortcut: index < 9 ? String(index + 1) : ""

                    width: root.cell
                    height: root.cell
                    radius: Config.cardRadius
                    color: Config.state(Config.container, Config.text, area.containsMouse || keyboardSelected, area.pressed)
                    Behavior on color { ColorAnimation { duration: Config.durationFast } }

                    focus: index === 0
                    activeFocusOnTab: true
                    function activate() { root.run(modelData) }
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.name
                    Accessible.onPressAction: activate()
                    Component.onCompleted: if (modelData.id === root.refocus) { root.refocus = ""; forceActiveFocus() }

                    Keys.onPressed: event => {
                        const app = modelData, shift = event.modifiers & Qt.ShiftModifier
                        if (shift && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
                            root.refocus = app.id
                            Pins.shift(app, event.key === Qt.Key_Left ? -1 : 1)
                        } else if (event.key === Qt.Key_Delete) Pins.toggle(app)
                        else { event.accepted = false; return }
                        Engine.key()
                        event.accepted = true
                    }

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 2 * Config.spaceS
                        spacing: Config.spaceS

                        IconImage {
                            anchors.horizontalCenter: parent.horizontalCenter
                            implicitSize: 44
                            asynchronous: true
                            source: Quickshell.iconPath(tile.modelData.icon ?? "", "application-x-executable")
                        }
                        Label {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: tile.modelData.name
                            font.pixelSize: Config.small + 1
                        }
                    }

                    ClickArea {
                        id: area
                        onClicked: root.run(tile.modelData)
                    }
                    FocusRing { on: tile.keyboardSelected }
                    KeyBadge { key: tile.shortcut }
                }
            }
        }

        EmptyState {
            width: parent.width
            visible: Pins.apps.length === 0
            icon: "keep"
            title: "No favourites yet"
            hint: "In the launcher, Ctrl+P pins the app that's selected, and again unpins it."
            actionText: "Open the launcher"
            actionIcon: Config.symbol.launcher
            onAction: Engine.open(Engine.View.Launcher)
        }

        KeyHints {
            width: parent.width
            keys: [["1–9", "start"], ["⇧ ← →", "move"], ["Del", "unpin"]]
        }
    }
}
