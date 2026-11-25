import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The task board (Tasks): to do, doing, done.
Item {
    id: root

    readonly property int pad: 24
    readonly property var titles: ["To do", "Doing", "Done"]
    readonly property real laneW: (width - 2 * pad - 2 * Config.spaceM) / 3
    property string editing: ""
    property string dragged: ""
    // Every change rebuilds the cards, which drops focus: the one to give it back to
    property string refocus: ""

    implicitWidth: 960
    implicitHeight: column.implicitHeight + 2 * pad

    function act(change, keep) {
        Engine.key()
        const before = Tasks.cards
        refocus = keep
        change()
        // nothing moved (Enter in Done, Shift+Up on the top card): the cards weren't rebuilt, focus stays
        if (Tasks.cards === before) { refocus = ""; return }
        Qt.callLater(() => { if (refocus !== "") { refocus = ""; field.field.forceActiveFocus() } })
    }
    function submit() {
        if (editing !== "") { const id = editing; editing = ""; act(() => Tasks.edit(id, field.text), id) }
        else Tasks.add(field.text)
        field.text = ""
    }
    function startEdit(card) {
        Engine.key()
        editing = card.id
        field.text = card.text
        field.field.forceActiveFocus()
    }
    // a removed card hands focus to the one below it, or above
    function neighbour(card) {
        const lane = Tasks.columns[card.column], i = lane.findIndex(c => c.id === card.id)
        return (lane[i + 1] ?? lane[i - 1])?.id ?? ""
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceM

        Header {
            width: parent.width
            icon: "checklist"
            title: "Tasks"
            subtitle: Tasks.cards.length === 0 ? "Kept in ~/.local/state/quickshell/tasks.json"
                    : root.titles.map((t, i) => Tasks.columns[i].length + " " + t.toLowerCase()).join(", ")
            onBack: Engine.back()

            Pill {
                visible: Tasks.columns[2].length > 0
                implicitHeight: 48
                kind: "text"
                icon: "cleaning_services"
                text: "Clear done"
                onClicked: Tasks.clearDone()
            }
        }

        SearchBar {
            id: field
            width: parent.width
            implicitHeight: 52
            fieldSize: Config.body + 1
            icon: root.editing !== "" ? "edit" : "add_task"
            placeholder: root.editing !== "" ? "The task, written again" : "A task: Enter adds it to To do"
            focus: true
            onKey: Engine.key()
            onAccepted: root.submit()
            onEscaped: if (root.editing !== "") { root.editing = ""; field.text = "" } else Engine.close()
            onBackspaceEmpty: Engine.back()
        }

        Row {
            id: lanes
            visible: Tasks.cards.length > 0
            spacing: Config.spaceM

            Repeater {
                model: 3

                Column {
                    id: lane
                    required property int index
                    width: root.laneW
                    spacing: Config.spaceS

                    SectionLabel { text: root.titles[lane.index] + "  ·  " + Tasks.columns[lane.index].length }

                    Label {
                        visible: Tasks.columns[lane.index].length === 0
                        leftPadding: Config.spaceXs
                        text: root.dragged !== "" ? "Drop it here" : "Nothing here"
                        color: Config.dim
                    }

                    ScrollList {
                        width: parent.width
                        maxHeight: 6 * 60
                        spacing: Config.spaceS

                        Repeater {
                            model: Tasks.columns[lane.index]

                            Rectangle {
                                id: card
                                required property var modelData
                                readonly property bool keyboardSelected: activeFocus && Config.focusVisible
                                readonly property bool tools: area.containsMouse || keyboardSelected

                                width: parent.width
                                height: Math.max(52, words.implicitHeight + 2 * Config.spaceM)
                                radius: Config.innerRadius
                                color: Config.state(root.editing === modelData.id ? Config.secondary : Config.container,
                                                    Config.text, area.containsMouse, area.pressed)
                                opacity: root.dragged === modelData.id ? 0.4 : 1
                                Behavior on color { ColorAnimation { duration: Config.durationFast } }

                                activeFocusOnTab: true
                                function activate() { root.act(() => Tasks.move(modelData.id, lane.index + 1), modelData.id) }
                                Accessible.role: Accessible.Button
                                Accessible.name: modelData.text
                                Accessible.description: root.titles[lane.index]
                                Accessible.onPressAction: activate()
                                Component.onCompleted: if (modelData.id === root.refocus) { root.refocus = ""; forceActiveFocus() }

                                // Shift with the arrows, as the plain arrows move between cards
                                Keys.onPressed: event => {
                                    const id = modelData.id, by = lane.index, shift = event.modifiers & Qt.ShiftModifier
                                    if (shift && event.key === Qt.Key_Left) root.act(() => Tasks.move(id, by - 1), id)
                                    else if (shift && event.key === Qt.Key_Right) root.act(() => Tasks.move(id, by + 1), id)
                                    else if (shift && event.key === Qt.Key_Up) root.act(() => Tasks.shift(id, -1), id)
                                    else if (shift && event.key === Qt.Key_Down) root.act(() => Tasks.shift(id, 1), id)
                                    else if (event.key === Qt.Key_Delete) root.act(() => Tasks.remove(id), root.neighbour(modelData))
                                    else if (event.key === Qt.Key_E || event.key === Qt.Key_F2) root.startEdit(modelData)
                                    else { event.accepted = false; return }
                                    event.accepted = true
                                }

                                Label {
                                    id: words
                                    x: Config.spaceM
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 2 * Config.spaceM
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                    text: card.modelData.text
                                    color: lane.index === 2 ? Config.dim : Config.text
                                    font.strikeout: lane.index === 2
                                }

                                ClickArea {
                                    id: area
                                    property point from
                                    property bool moved: false
                                    // inside a ScrollList: without this the list takes the drag to scroll
                                    preventStealing: true
                                    onPressed: mouse => { from = Qt.point(mouse.x, mouse.y); moved = false }
                                    onPositionChanged: mouse => {
                                        if (!pressed || (!moved && Math.hypot(mouse.x - from.x, mouse.y - from.y) < 8)) return
                                        moved = true
                                        root.dragged = card.modelData.id
                                        ghost.text = card.modelData.text
                                        const p = mapToItem(root, mouse.x, mouse.y)
                                        ghost.x = p.x - ghost.width / 2
                                        ghost.y = p.y - ghost.height / 2
                                    }
                                    onReleased: mouse => {
                                        if (!moved) return
                                        const to = Math.floor(mapToItem(lanes, mouse.x, mouse.y).x / (root.laneW + lanes.spacing))
                                        const id = root.dragged
                                        root.dragged = ""
                                        Tasks.move(id, Math.max(0, Math.min(2, to)))
                                    }
                                    onClicked: if (!moved) card.forceActiveFocus()
                                    onDoubleClicked: root.startEdit(card.modelData)
                                }

                                // over the end of the text, on the card's own colour
                                Rectangle {
                                    visible: card.tools
                                    anchors { right: parent.right; rightMargin: Config.spaceXs; top: parent.top; topMargin: Config.spaceXs }
                                    width: buttons.width
                                    height: buttons.height
                                    radius: height / 2
                                    color: card.color

                                    Row {
                                        id: buttons
                                        Repeater {
                                            model: [{ icon: "chevron_left", on: lane.index > 0, run: () => Tasks.move(card.modelData.id, lane.index - 1) },
                                                    { icon: "chevron_right", on: lane.index < 2, run: () => Tasks.move(card.modelData.id, lane.index + 1) },
                                                    { icon: "edit", on: true, run: () => root.startEdit(card.modelData) },
                                                    { icon: "delete", on: true, run: () => Tasks.remove(card.modelData.id) }]

                                            Pill {
                                                required property var modelData
                                                visible: modelData.on
                                                activeFocusOnTab: false
                                                kind: "text"
                                                implicitHeight: 28
                                                iconSize: 16
                                                icon: modelData.icon
                                                onClicked: modelData.run()
                                            }
                                        }
                                    }
                                }

                                FocusRing { on: card.keyboardSelected }
                            }
                        }
                    }
                }
            }
        }

        EmptyState {
            width: parent.width
            visible: Tasks.cards.length === 0
            icon: "checklist"
            title: "Nothing to do yet"
            hint: "Type a task above and press Enter. It stays until you clear it."
        }

        KeyHints {
            width: parent.width
            keys: [["⏎", "move on"], ["⇧ ← →", "column"], ["⇧ ↑ ↓", "order"], ["E", "edit"], ["Del", "remove"]]
        }
    }

    Rectangle {
        id: ghost
        property alias text: ghostText.text
        visible: root.dragged !== ""
        width: root.laneW
        height: 52
        radius: Config.innerRadius
        color: Config.high
        z: 10

        Label {
            id: ghostText
            anchors { fill: parent; margins: Config.spaceM }
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
