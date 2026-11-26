import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services
import qs.modules.parts

// The machine at a glance: processor, memory, temperature, the disk and the network, read only while this
// is open (SysStats.watch), and the local model's state from the agent. The GPU is never polled: asking the
// GTX 1650 would wake it.
Panel {
    id: root

    Component.onCompleted: SysStats.watch(true)
    Component.onDestruction: SysStats.watch(false)

    implicitWidth: 560

    // One reading on a card of its own: its value and its last minute as a graph; a bar instead for
    // what barely moves in a minute (the disk). A second graph, dimmer, shares the first one's scale.
    component Reading: Rectangle {
        id: reading
        property string icon: ""
        property string name: ""
        property string value: ""
        property string aside: ""         // after the value, dimmer: "of 15.0 GB"
        property string note: ""          // why there is no value, when there isn't
        property var history: []
        property var history2: []
        property real max: 1
        property real fraction: -1
        property color tone: Config.primary

        implicitHeight: 136
        radius: Config.cardRadius
        color: Config.tile

        Row {
            id: label
            x: Config.spaceL
            y: Config.spaceL
            spacing: Config.spaceS
            Icon { anchors.verticalCenter: parent.verticalCenter; name: reading.icon; size: 18; color: reading.tone }
            Label { anchors.verticalCenter: parent.verticalCenter; text: reading.name; color: Config.dim }
        }
        Row {
            anchors { left: label.left; top: label.bottom; topMargin: Config.spaceXs }
            spacing: Config.spaceS
            Label {
                id: shown
                text: reading.value !== "" ? reading.value : reading.note
                color: reading.value !== "" ? Config.text : Config.dim
                font.pixelSize: reading.value !== "" ? Config.title : Config.body
                font.features: { "tnum": 1 }
            }
            Label {
                visible: reading.value !== ""
                anchors.baseline: shown.baseline
                text: reading.aside
                color: Config.dim
                font.features: { "tnum": 1 }
            }
        }
        Item {
            visible: reading.value !== ""
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Config.spaceL }
            height: 44

            Sparkline { anchors.fill: parent; visible: reading.fraction < 0; values: reading.history2; max: reading.max; color: Config.dim }
            Sparkline { anchors.fill: parent; visible: reading.fraction < 0; values: reading.history; max: reading.max; color: reading.tone }
            Progress {
                visible: reading.fraction >= 0
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                thickness: 8
                fraction: reading.fraction
                color: reading.tone
            }
        }
    }

    icon: "monitor_heart"
    title: "System"
    subtitle: "The last minute, live while this is open"
    spacing: Config.spaceL
    keys: [["⌫", "back"], ["Esc", "close"]]

    Grid {
        id: grid
        width: parent.width
        columns: 2
        spacing: Config.spaceM
        readonly property real cell: (width - spacing) / 2

        Reading {
            width: grid.cell
            icon: "developer_board"; name: "Processor"
            value: Math.round(SysStats.cpu * 100) + " %"
            history: SysStats.history.cpu
        }
        Reading {
            width: grid.cell
            icon: "memory"; name: "Memory"
            value: SysStats.mem > 0 ? SysStats.memGB.toFixed(1) + " GB" : ""
            aside: SysStats.mem > 0 ? "of " + (SysStats.memGB / SysStats.mem).toFixed(1) + " GB" : ""
            note: "Reading…"
            history: SysStats.history.mem
        }
        Reading {
            width: grid.cell
            icon: "thermostat"; name: "Temperature"
            value: SysStats.temp > 0 ? Math.round(SysStats.temp) + " °C" : ""
            note: "No sensor found"
            history: SysStats.history.temp
            max: 100
            tone: SysStats.temp >= 85 ? Config.bad : SysStats.temp >= 70 ? Config.warn : Config.primary
        }
        Reading {
            width: grid.cell
            icon: "hard_drive"; name: "Disk (/)"
            value: SysStats.diskTotalGB > 0 ? SysStats.diskUsedGB.toFixed(0) + " GB" : ""
            aside: "of " + SysStats.diskTotalGB.toFixed(0) + " GB"
            note: "Reading…"
            fraction: SysStats.diskTotalGB > 0 ? SysStats.diskUsedGB / SysStats.diskTotalGB : 0
            tone: SysStats.diskUsedGB / Math.max(1, SysStats.diskTotalGB) >= 0.9 ? Config.bad : Config.primary
        }
    }

    // down in the primary colour, up dimmer, on one scale so the two compare
    Reading {
        width: parent.width
        icon: "swap_vert"; name: "Network" + (SysStats.iface !== "" ? "  ·  " + SysStats.iface : "")
        value: SysStats.iface !== "" ? "↓ " + SysStats.rate(SysStats.rx) : ""
        aside: "↑ " + SysStats.rate(SysStats.tx)
        note: "No network route"
        history: SysStats.history.rx
        history2: SysStats.history.tx
        max: Math.max(1, ...SysStats.history.rx, ...SysStats.history.tx)
    }

    ListEntry {
        width: parent.width
        filled: true
        icon: "psychology"
        title: !Agent.ready ? "Local model: checking…"
             : !Agent.reachable ? "Local model: Ollama isn't running"
             : Agent.inUse === "" ? "Local model: none installed"
             : "Local model: " + Agent.inUse
        subtitle: !Agent.ready ? ""
                : !Agent.reachable ? "The assistant can't answer until it is started."
                : Agent.inUse === "" ? "Models are managed in the flake's ollama module."
                : Agent.loaded ? "In memory, ready" : "Not loaded: the first answer is slower"
    }
}
