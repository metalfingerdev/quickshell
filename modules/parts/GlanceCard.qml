import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// At a glance: the weather and what's next in the calendars, when they're set up, over the
// processor, memory, temperature and the network's rates. The system is read only while this is
// shown. After Nihil-Shell's desktop cards and its dashboard's dials.
Rectangle {
    id: root

    readonly property bool weather: Weather.current
    readonly property bool event: Calendar.next !== null

    Component.onCompleted: SysStats.watch(true)
    Component.onDestruction: SysStats.watch(false)

    implicitWidth: 420
    implicitHeight: column.implicitHeight + 24
    radius: Config.cardRadius
    color: Config.tile

    // a reading: its icon, its value, and under them how full, when that says something
    component Meter: Column {
        id: meter
        property string icon: ""
        property string value: ""
        property real fraction: -1
        property color tone: Config.primary
        width: (column.width - 3 * 12) / 4
        spacing: Config.spaceS

        Row {
            spacing: Config.spaceS

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: meter.icon
                size: 16
                color: Config.dim
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: meter.value
                font.pixelSize: Config.small + 1
                font.weight: Font.Medium
                font.features: { "tnum": 1 }
            }
        }
        Rectangle {
            visible: meter.fraction >= 0
            width: parent.width
            height: 4
            radius: 2
            color: Config.raised

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, meter.fraction))
                height: parent.height
                radius: 2
                color: meter.tone
                Behavior on width { NumberAnimation { duration: Config.motionMs; easing.type: Easing.OutCubic } }
            }
        }
    }

    Column {
        id: column
        x: 16
        y: 12
        width: parent.width - 32
        spacing: Config.spaceM

        // the weather on the left (its sky is the icon; the place shows when there's room), what's
        // next on the right, cut short before it reaches the weather; the event opens the calendar
        Item {
            visible: root.weather || root.event
            width: parent.width
            height: 24

            Row {
                id: sky
                visible: root.weather
                anchors.verticalCenter: parent.verticalCenter
                spacing: Config.spaceS

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.weather ? Weather.icon(Weather.forecast.now.code, Weather.forecast.now.day) : ""
                    size: 22
                    color: Config.primary
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.weather ? Weather.degrees(Weather.forecast.now.temp) : ""
                    font.pixelSize: Config.body + 2
                    font.weight: Font.DemiBold
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    readonly property var today: root.weather ? Weather.forecast.days[0] ?? null : null
                    text: (today ? Weather.degrees(today.max) + " / " + Weather.degrees(today.min) : "")
                        + (root.event || Weather.name === "" ? "" : "  ·  " + Weather.name)
                    color: Config.dim
                    font.pixelSize: Config.small + 1
                }
            }
            Row {
                id: next
                visible: root.event
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: Config.spaceS

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: Config.symbol.calendar
                    size: 16
                    color: Config.dim
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, column.width - (root.weather ? sky.width + 24 : 0) - 22)
                    text: root.event ? Calendar.when(Calendar.next) + "  " + Calendar.title(Calendar.next) : ""
                    elide: Text.ElideRight
                    font.pixelSize: Config.small + 1
                }
            }
            ClickArea {
                anchors.fill: sky
                enabled: root.weather
                onClicked: mouse => Engine.open(Engine.View.Weather, sceneX(mouse))
            }
            ClickArea {
                anchors.fill: next
                enabled: root.event
                onClicked: mouse => Engine.open(Engine.View.Agenda, sceneX(mouse))
            }
        }

        // the readings open the System view
        Item {
            width: parent.width
            height: meters.height

            ClickArea {
                anchors.fill: parent
                z: 1
                onClicked: mouse => Engine.open(Engine.View.System, sceneX(mouse))
            }

            Row {
                id: meters
                width: parent.width
                spacing: Config.spaceM

                Meter { icon: "developer_board"; value: Math.round(SysStats.cpu * 100) + "%"; fraction: SysStats.cpu }
                Meter { icon: "memory"; value: SysStats.memGB.toFixed(1) + " GB"; fraction: SysStats.mem }
                Meter {
                    icon: "thermostat"
                    value: SysStats.temp > 0 ? Math.round(SysStats.temp) + " °C" : "—"
                    fraction: SysStats.temp > 0 ? SysStats.temp / 100 : -1
                    tone: SysStats.temp >= 85 ? Config.bad : SysStats.temp >= 70 ? Config.warn : Config.primary
                }
                Column {
                    width: (column.width - 3 * 12) / 4
                    spacing: 0

                    Label {
                        text: "↓ " + SysStats.rate(SysStats.rx)
                        font.pixelSize: Config.small
                        font.features: { "tnum": 1 }
                    }
                    Label {
                        text: "↑ " + SysStats.rate(SysStats.tx)
                        color: Config.dim
                        font.pixelSize: Config.small
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }
    }
}
