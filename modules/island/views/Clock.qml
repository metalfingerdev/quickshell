import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.components
import qs.modules.services

Item {
    id: root

    readonly property int pad: 24

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // the month on show, as an offset from the current one
    property int shift: 0
    // the day whose events show under the date: today until one is clicked
    property var picked: null
    readonly property date day: picked ?? clock.date
    readonly property var dayEvents: {
        const start = new Date(day.getFullYear(), day.getMonth(), day.getDate()).getTime() / 1000
        const end = start + 86400
        return Calendar.events.filter(e => e.start < end && (e.end > start || e.start >= start))
    }
    // a dot under every day with something on; a long event marks two months at most
    readonly property var marked: {
        const m = {}
        for (const e of Calendar.events) {
            const d = new Date(e.start * 1000)
            d.setHours(0, 0, 0, 0)
            const last = new Date(Math.max(e.start, e.end - 1) * 1000)
            for (let n = 0; d <= last && n < 62; n++, d.setDate(d.getDate() + 1)) m[d.toDateString()] = true
        }
        return m
    }
    readonly property date shown: new Date(clock.date.getFullYear(), clock.date.getMonth() + shift, 1)
    readonly property int week: {
        const d = new Date(Date.UTC(clock.date.getFullYear(), clock.date.getMonth(), clock.date.getDate()))
        const day = d.getUTCDay() || 7
        d.setUTCDate(d.getUTCDate() + 4 - day)
        return Math.ceil(((d - new Date(Date.UTC(d.getUTCFullYear(), 0, 1))) / 86400000 + 1) / 7)
    }

    implicitWidth: 780
    implicitHeight: column.implicitHeight + 2 * pad

    Column {
        id: column
        x: root.pad; y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: Config.symbol.calendar
            title: "Calendar"
            onBack: Engine.back()

            Pill { visible: root.shift !== 0 || root.picked !== null; implicitHeight: 48; kind: "text"; text: "Today"; shortcut: "t"; onClicked: { root.shift = 0; root.picked = null } }
            Pill { icon: "chevron_left";  implicitHeight: 48; iconSize: 24; shortcut: "["; onClicked: root.shift-- }
            Pill { icon: "chevron_right"; implicitHeight: 48; iconSize: 24; shortcut: "]"; onClicked: root.shift++ }
        }

        Row {
            width: parent.width
            spacing: Config.spaceXl

            Column {
                width: parent.width - card.width - parent.spacing
                anchors.verticalCenter: card.verticalCenter
                spacing: Config.spaceS

                Row {
                    spacing: Config.spaceS

                    Label {
                        id: time
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        font.pixelSize: 88
                        font.weight: Font.Light
                        font.features: { "tnum": 1 }
                    }
                    Label {
                        anchors.baseline: time.baseline
                        text: Qt.formatDateTime(clock.date, "ss")
                        color: Config.primary
                        font.pixelSize: Config.headline
                        font.features: { "tnum": 1 }
                    }
                }
                Label {
                    text: Qt.formatDateTime(clock.date, "dddd")
                    font.pixelSize: Config.title
                }
                Label {
                    text: Qt.formatDateTime(clock.date, "d MMMM yyyy") + "  ·  week " + root.week
                    color: Config.dim
                    font.pixelSize: Config.large
                }

                // the picked day's events (today's at first), when there are calendars to have them
                Column {
                    visible: Calendar.any
                    width: parent.width
                    topPadding: Config.spaceM
                    spacing: Config.spaceXs

                    SectionLabel {
                        text: root.picked === null ? "Today" : Qt.formatDateTime(root.day, "dddd d MMMM")
                    }
                    Label {
                        visible: root.dayEvents.length === 0
                        text: "Nothing on"
                        color: Config.dim
                    }
                    Repeater {
                        model: root.dayEvents.slice(0, 3)

                        Label {
                            required property var modelData
                            width: parent.width
                            elide: Text.ElideRight
                            text: (modelData.allDay ? "All day" : Qt.formatDateTime(new Date(modelData.start * 1000), "HH:mm"))
                                  + "   " + Calendar.title(modelData)
                        }
                    }
                    Label {
                        visible: root.dayEvents.length > 3
                        text: "and " + (root.dayEvents.length - 3) + " more"
                        color: Config.dim
                    }
                }
            }

            Rectangle {
                id: card
                width: month.implicitWidth + 32
                height: month.implicitHeight + 32
                radius: Config.cardRadius
                color: Config.container

                Column {
                    id: month
                    x: 16; y: 16
                    spacing: Config.spaceS

                    Label {
                        leftPadding: Config.spaceS
                        text: Qt.formatDateTime(root.shown, "MMMM yyyy")
                        font.pixelSize: Config.large
                        font.weight: Font.Medium
                    }
                    CalendarGrid {
                        cell: 44
                        year: root.shown.getFullYear()
                        month: root.shown.getMonth()
                        today: clock.date
                        marked: root.marked
                        selected: root.picked
                        onPicked: d => root.picked = d
                    }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["[ ]", "month"], ["T", "today"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
