import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services
import qs.modules.parts

// The weather at the chosen place (services/Weather, Open-Meteo): now and the next days. Named Forecast
// because a view can't share a singleton's name.
Panel {
    id: root

    function dayName(date, index) {
        if (index === 0) return "Today"
        if (index === 1) return "Tomorrow"
        const [y, m, d] = date.split("-").map(Number)
        return Qt.formatDate(new Date(y, m - 1, d), "dddd")
    }

    implicitWidth: 520

    icon: "partly_cloudy_day"
    title: "Weather"
    subtitle: Weather.placed ? Weather.label || Weather.name : ""
    actions: Pill { visible: Weather.placed; implicitHeight: 48; icon: "refresh"; shortcut: "r"; onClicked: Weather.read() }
    spacing: Config.spaceL
    keys: [["R", "refresh"], ["⌫", "back"], ["Esc", "close"]]

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
                filled: true
                icon: Weather.icon(modelData.code, true)
                title: root.dayName(modelData.date, index)
                subtitle: Weather.skyName(modelData.code)
                trailing: Weather.degrees(modelData.max) + " / " + Weather.degrees(modelData.min)
            }
        }
    }
}
