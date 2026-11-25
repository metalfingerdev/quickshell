import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The ones that end the session ask first, as macOS's shut-down sheet does: it counts down
// (Config.powerCountdown seconds, 0 asks nothing) and runs by itself, or at once from the button.
Item {
    id: root

    property var pending: null
    property int remaining: 0
    function press(a) {
        if (a.confirm && Config.powerCountdown > 0) { pending = a; remaining = Config.powerCountdown; ask.open = true; count.restart(); return }
        run(a)
    }
    function run(a) {
        count.stop()
        ask.open = false
        Engine.close()                       // gone before the screen locks or the session ends
        Session.run(a.id)
    }
    Timer {
        id: count
        interval: 1000
        repeat: true
        onTriggered: { root.remaining--; Engine.key(); if (root.remaining <= 0) root.run(root.pending) }
    }
    Component.onCompleted: Session.refresh()

    implicitWidth: tiles.implicitWidth + 48
    implicitHeight: column.implicitHeight + 48

    Column {
        id: column
        x: 24; y: 24
        width: parent.width - 48
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: Config.symbol.power
            title: "Power"
            subtitle: Session.uptimeText
            onBack: Engine.back()

            Pill {
                visible: Session.restarts.length > 0
                icon: "expand_more"
                text: "Restart into…"
                shortcut: "i"
                onClicked: menu.open = !menu.open
            }
        }

        Row {
            id: tiles
            spacing: Config.spaceM

            Repeater {
                model: Session.actions

                Tile {
                    id: tile
                    required property var modelData

                    width: 128
                    height: 128
                    radius: Config.cardRadius + 4
                    shortcut: modelData.key
                    
                    onClicked: root.press(modelData)

                    Column {
                        anchors.centerIn: parent
                        spacing: Config.spaceM

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 56; height: 56; radius: 28
                            color: Config.fill2

                            Icon {
                                anchors.centerIn: parent
                                name: tile.modelData.icon
                                size: 28
                                color: Config.text
                            }
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.label
                            color: Config.text
                            font.weight: tile.waiting ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["↵", "run (ending the session asks first)"], ["⌫", "back"]]
        }
    }

    // under the header's button, at the right edge: a child of the header would be laid out in its row
    Menu {
        id: menu
        x: parent.width - width - 24
        y: 24 + 56 + Config.spaceXs
        width: 240
        items: Session.restarts.map(r => ({ key: r.id, label: r.label, icon: r.icon }))
        onChosen: key => root.press(Session.restarts.find(r => r.id === key))
    }

    Sheet {
        id: ask
        title: root.pending ? root.pending.label + " in " + root.remaining + " s" : ""
        onDismissed: count.stop()

        Label {
            width: parent.width
            wrapMode: Text.WordWrap
            text: "The session ends when the countdown does."
            color: Config.label2
        }
        Row {
            spacing: Config.spaceM
            Pill {
                kind: "filled"
                text: root.pending ? root.pending.label + " now" : ""
                focus: ask.open
                onClicked: root.run(root.pending)
            }
            Pill { kind: "text"; text: "Cancel"; onClicked: ask.close() }
        }
    }
}
