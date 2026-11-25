import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The machine at a glance: processor, memory, temperature, the disk and the network, read only while this
// is open (SysStats.watch), and the local model's state from the agent. The GPU is never polled: asking the
// GTX 1650 would wake it.
Item {
    id: root

    readonly property int pad: 24

    Component.onCompleted: SysStats.watch(true)
    Component.onDestruction: SysStats.watch(false)

    implicitWidth: 560
    implicitHeight: column.implicitHeight + 2 * pad

    // one reading: what it is, its value, how full, and a reason when there is no value
    component Reading: Column {
        id: reading
        property string icon: ""
        property string name: ""
        property string value: ""
        property string note: ""          // why there is no value, when there isn't
        property real fraction: -1
        property color tone: Config.primary

        width: parent.width
        spacing: Config.spaceS

        Row {
            spacing: Config.spaceS
            Icon { anchors.verticalCenter: parent.verticalCenter; name: reading.icon; size: 20; color: Config.dim }
            Label { anchors.verticalCenter: parent.verticalCenter; text: reading.name; color: Config.dim }
        }
        Label {
            text: reading.value !== "" ? reading.value : reading.note
            color: reading.value !== "" ? Config.text : Config.dim
            font.pixelSize: reading.value !== "" ? Config.title : Config.body
            font.features: { "tnum": 1 }
        }
        Progress {
            visible: reading.fraction >= 0
            width: parent.width
            thickness: 8
            fraction: reading.fraction
            color: reading.tone
        }
    }

    Column {
        id: column
        x: root.pad; y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: "monitor_heart"
            title: "System"
            subtitle: "Live while this is open"
            onBack: Engine.back()
        }

        Grid {
            width: parent.width
            columns: 2
            columnSpacing: Config.spaceXl
            rowSpacing: Config.spaceL
            readonly property real cell: (width - columnSpacing) / 2

            Item {
                width: parent.cell; height: cpu.implicitHeight
                Reading { id: cpu; icon: "developer_board"; name: "Processor"; value: Math.round(SysStats.cpu * 100) + " %"; fraction: SysStats.cpu }
            }
            Item {
                width: parent.cell; height: mem.implicitHeight
                Reading {
                    id: mem
                    icon: "memory"; name: "Memory"
                    value: SysStats.mem > 0 ? SysStats.memGB.toFixed(1) + " of " + (SysStats.memGB / SysStats.mem).toFixed(1) + " GB" : ""
                    note: "Reading…"
                    fraction: SysStats.mem
                }
            }
            Item {
                width: parent.cell; height: temp.implicitHeight
                Reading {
                    id: temp
                    icon: "thermostat"; name: "Temperature"
                    value: SysStats.temp > 0 ? Math.round(SysStats.temp) + " °C" : ""
                    note: "No sensor found"
                    fraction: SysStats.temp > 0 ? SysStats.temp / 100 : -1
                    tone: SysStats.temp >= 85 ? Config.bad : SysStats.temp >= 70 ? Config.warn : Config.primary
                }
            }
            Item {
                width: parent.cell; height: disk.implicitHeight
                Reading {
                    id: disk
                    icon: "hard_drive"; name: "Disk (/)"
                    value: SysStats.diskTotalGB > 0 ? SysStats.diskUsedGB.toFixed(0) + " of " + SysStats.diskTotalGB.toFixed(0) + " GB" : ""
                    note: "Reading…"
                    fraction: SysStats.diskTotalGB > 0 ? SysStats.diskUsedGB / SysStats.diskTotalGB : -1
                    tone: SysStats.diskUsedGB / Math.max(1, SysStats.diskTotalGB) >= 0.9 ? Config.bad : Config.primary
                }
            }
        }

        Row {
            spacing: Config.spaceXl
            Label { text: "↓ " + SysStats.rate(SysStats.rx); font.features: { "tnum": 1 } }
            Label { text: "↑ " + SysStats.rate(SysStats.tx); color: Config.dim; font.features: { "tnum": 1 } }
            Label { visible: SysStats.iface === ""; text: "No network route"; color: Config.dim }
        }

        ListEntry {
            width: parent.width
            icon: "psychology"
            title: !Agent.reachable ? "Local model: Ollama isn't running"
                 : Agent.inUse === "" ? "Local model: none installed"
                 : "Local model: " + Agent.inUse
            subtitle: !Agent.reachable ? "The assistant can't answer until it is started."
                    : Agent.inUse === "" ? "Models are managed in the flake's ollama module."
                    : Agent.loaded ? "In memory, ready" : "Not loaded: the first answer is slower"
        }

        KeyHints {
            width: parent.width
            keys: [["⌫", "back"], ["Esc", "close"]]
        }
    }
}
