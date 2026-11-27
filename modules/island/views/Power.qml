import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The ones that end the session ask first: the first press arms the tile ("Again?"), a second within
// `confirmMs` runs it. A countdown sheet was tried and put back: a second press is quicker and can't run by itself.
Item {
    id: root

    readonly property int confirmMs: 3000
    property string armed: ""

    function press(a) {
        if (a.confirm && armed !== a.id) { armed = a.id; disarm.restart(); return }
        armed = ""
        Engine.close()                       // gone before the screen locks or the session ends
        Session.run(a.id)
    }
    Timer { id: disarm; interval: root.confirmMs; onTriggered: root.armed = "" }
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
                readonly property var armedEntry: Session.restarts.find(r => r.id === root.armed)
                text: armedEntry ? armedEntry.label + ": again?" : "Restart into…"
                active: armedEntry !== undefined
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
                    readonly property bool waiting: root.armed === modelData.id
                    shortcut: modelData.key
                    tint: waiting ? Config.bad : "transparent"
                    onClicked: root.press(modelData)

                    Column {
                        anchors.centerIn: parent
                        spacing: Config.spaceM

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 56; height: 56; radius: 28
                            color: tile.waiting ? Qt.rgba(0, 0, 0, 0.15) : Config.raised

                            Icon {
                                anchors.centerIn: parent
                                name: tile.modelData.icon
                                size: 28
                                color: tile.waiting ? Config.surface : Config.text
                            }
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.waiting ? "Again?" : tile.modelData.label
                            color: tile.waiting ? Config.surface : Config.text
                            font.weight: tile.waiting ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["↵", "run (twice to end the session)"], ["⌫", "back"]]
        }
    }

    // under the header's button, at the right edge: a child of the header would be laid out in its row
    Menu {
        id: menu
        x: parent.width - width - 24
        y: 24 + 56 + Config.spaceXs
        width: 240
        items: Session.restarts.map(r => ({ key: r.id, label: r.label, icon: r.icon }))
        // choosing an entry arms it too: the menu closes, and the entry's own pill asks again below
        onChosen: key => root.press(Session.restarts.find(r => r.id === key))
    }
}
