import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The weather at the chosen place (services/Weather, Open-Meteo): now and the next days. Named Forecast
// because a view can't share a singleton's name.
Item {
    id: root

    readonly property int pad: 24

    function dayName(date, index) {
        if (index === 0) return "Today"
        if (index === 1) return "Tomorrow"
        const [y, m, d] = date.split("-").map(Number)
        return Qt.formatDate(new Date(y, m - 1, d), "dddd")
    }

    implicitWidth: 520
    implicitHeight: column.implicitHeight + 2 * pad

    Column {
        id: column
        x: root.pad; y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: "partly_cloudy_day"
            title: "Weather"
            subtitle: Weather.placed ? Weather.label || Weather.name : ""
            onBack: Engine.back()

            Pill { visible: Weather.placed; implicitHeight: 48; icon: "refresh"; shortcut: "r"; onClicked: Weather.read() }
        }

        EmptyState {
            width: parent.width
            visible: !Weather.placed
            icon: "location_off"
            title: "No place set"
            hint: "Choose one in Settings, or run: qs ipc call weather place <name>"
        }

        EmptyState {
            width: parent.width
            visible: Weather.placed && !Weather.current
            icon: Weather.failed ? "cloud_off" : "cloud_sync"
            title: Weather.failed ? "Can't reach the forecast" : "Reading the forecast…"
            hint: Weather.failed ? "It tries again when the network changes." : ""
            actionText: Weather.failed ? "Try again" : ""
            actionIcon: "refresh"
            onAction: Weather.read()
        }

        Row {
            visible: Weather.current
            spacing: Config.spaceL

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: Weather.current ? Weather.icon(Weather.forecast.now.code, Weather.forecast.now.day) : ""
                size: 64
                color: Config.primary
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    text: Weather.current ? Weather.degrees(Weather.forecast.now.temp) : ""
                    font.pixelSize: Config.display
                    font.features: { "tnum": 1 }
                }
                Label {
                    text: Weather.current ? Weather.skyName(Weather.forecast.now.code) + "  ·  feels like " + Weather.degrees(Weather.forecast.now.feels) : ""
                    color: Config.dim
                }
            }
        }

        Column {
            visible: Weather.current
            width: parent.width
            spacing: Config.spaceXs

            Repeater {
                model: Weather.current ? Weather.forecast.days : []

                ListEntry {
                    required property var modelData
                    required property int index
                    width: parent.width
                    icon: Weather.icon(modelData.code, true)
                    title: root.dayName(modelData.date, index)
                    subtitle: Weather.skyName(modelData.code)
                    trailing: Weather.degrees(modelData.max) + " / " + Weather.degrees(modelData.min)
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["R", "refresh"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
