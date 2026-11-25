import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// What's coming up in the calendars (services/Calendar, read from iCal sources), grouped by day. Named
// Schedule because a view can't share a name with the Agenda library. Read only.
Item {
    id: root

    readonly property int pad: Config.spaceXl

    function dayLabel(seconds) {
        const d = new Date(seconds * 1000), t = new Date(Calendar.now * 1000)
        const key = x => Qt.formatDate(x, "yyyy-MM-dd")
        const tomorrow = new Date(t.getFullYear(), t.getMonth(), t.getDate() + 1)
        if (key(d) === key(t)) return "Today"
        if (key(d) === key(tomorrow)) return "Tomorrow"
        return Qt.formatDate(d, "dddd d MMMM")
    }

    // [{ day, events: [...] }], an event already under way counted as today
    readonly property var groups: {
        const out = []
        for (const e of Calendar.upcoming(40)) {
            const day = root.dayLabel(Math.max(e.start, Calendar.now))
            if (!out.length || out[out.length - 1].day !== day) out.push({ day: day, events: [] })
            out[out.length - 1].events.push(e)
        }
        return out
    }

    function span(e) {
        if (e.allDay) return "All day"
        if (e.start <= Calendar.now && Calendar.now < e.end) return "Now, until " + Qt.formatTime(new Date(e.end * 1000), "HH:mm")
        return Qt.formatTime(new Date(e.start * 1000), "HH:mm") + " – " + Qt.formatTime(new Date(e.end * 1000), "HH:mm")
    }

    implicitWidth: 560
    implicitHeight: column.implicitHeight + 2 * pad

    Column {
        id: column
        x: root.pad; y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceM

        Header {
            width: parent.width
            icon: "event_note"
            title: "Agenda"
            subtitle: Calendar.any ? Calendar.calendars.length + (Calendar.calendars.length === 1 ? " calendar" : " calendars") : ""
            onBack: Engine.back()

            Pill { visible: Calendar.any; implicitHeight: 48; icon: "sync"; shortcut: "r"; onClicked: Calendar.sync() }
            Pill { implicitHeight: 48; icon: Config.symbol.calendar; text: "Month"; shortcut: "m"; onClicked: Engine.open(Engine.View.Clock, -1) }
        }

        EmptyState {
            width: parent.width
            visible: !Calendar.any
            icon: "event_busy"
            title: "No calendar set up"
            hint: "List iCal sources in ~/.config/island/calendars.json and they show here."
        }

        EmptyState {
            width: parent.width
            visible: Calendar.any && root.groups.length === 0
            icon: Calendar.failed ? "sync_problem" : "event_available"
            title: Calendar.failed ? "Can't read a calendar" : "Nothing coming up"
            hint: Calendar.failed ? "It tries again when the network changes." : "No events in the calendars you added."
            actionText: Calendar.failed ? "Try again" : ""
            actionIcon: "sync"
            onAction: Calendar.sync()
        }

        ScrollList {
            width: parent.width
            visible: root.groups.length > 0
            maxHeight: 6 * 64 + 14

            Repeater {
                model: root.groups

                Column {
                    id: group
                    required property var modelData
                    width: parent.width
                    spacing: Config.spaceXs

                    SectionLabel { text: group.modelData.day }

                    Repeater {
                        model: group.modelData.events

                        ListEntry {
                            required property var modelData
                            width: group.width
                            filled: true
                            icon: modelData.allDay ? "today" : "schedule"
                            title: Calendar.title(modelData)
                            subtitle: root.span(modelData) + (modelData.where ? "  ·  " + modelData.where : "")
                        }
                    }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["R", "sync"], ["M", "month"], ["⌫", "back"]]
        }
    }
}
