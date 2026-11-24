import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The agent while it works, when it waits on a yes, or with an answer not yet seen, the size of
// MediaCard's compact form: Stop, Allow and Don't, or a click into the conversation. After Nilo's
// panel out of the bar (Nihil-Shell).
Rectangle {
    id: root

    readonly property bool asking: Agent.asking !== null
    readonly property bool active: Agent.busy || asking || Agent.fresh
    readonly property color ink: Config.secondaryInk

    implicitWidth: 420
    implicitHeight: 84
    radius: Config.cardRadius
    color: Config.container

    Rectangle {
        id: badge
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        height: 56
        radius: Config.smallRadius
        color: Config.secondary

        Icon {
            id: face
            anchors.centerIn: parent
            name: root.asking ? "help" : "smart_toy"
            size: 26
            color: root.ink
            SequentialAnimation on opacity {
                running: Agent.busy && !root.asking
                loops: Animation.Infinite
                onRunningChanged: if (!running) face.opacity = 1
                NumberAnimation { to: 0.45; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }
    }

    Column {
        anchors { left: badge.right; leftMargin: 12; right: controls.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 2

        Label {
            width: parent.width
            text: root.asking ? "The agent asks" : Agent.busy ? Agent.activity : "Agent answered"
            elide: Text.ElideRight
            font.pixelSize: Config.body + 1
            font.weight: Font.DemiBold
        }
        Label {
            width: parent.width
            text: root.asking ? Agent.describe(Agent.asking)
                : Agent.busy ? Agent.lastQuestion
                : Agent.lastAnswer.replace(/```[\s\S]*?```/g, " … ").replace(/[*_`#>\[\]]/g, "").replace(/\s+/g, " ").trim()
            wrapMode: Text.Wrap
            maximumLineCount: root.asking ? 2 : 1
            elide: Text.ElideRight
            color: Config.dim
            font.pixelSize: Config.small + 1
        }
    }
    // the card itself opens the conversation; the buttons sit over it
    MouseArea {
        anchors { left: parent.left; right: controls.left; top: parent.top; bottom: parent.bottom }
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => Engine.open(Engine.View.Agent, mapToItem(null, mouse.x, mouse.y).x)
    }

    Row {
        id: controls
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 2

        Pill { visible: root.asking; kind: "text"; icon: "close"; iconSize: 22; onClicked: Agent.answer(false) }
        Pill { visible: root.asking; kind: "filled"; icon: "check"; iconSize: 22; onClicked: Agent.answer(true) }
        Pill { visible: Agent.busy && !root.asking; kind: "text"; icon: "stop_circle"; iconSize: 24; onClicked: Agent.stop() }
        Pill { visible: !Agent.busy && !root.asking; kind: "text"; icon: Config.symbol.open; iconSize: 22
               onClicked: x => Engine.open(Engine.View.Agent, x) }
    }
}
