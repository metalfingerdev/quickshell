// Time.qml
import QtQuick
import Quickshell
pragma Singleton

Singleton {
    id: root

    readonly property string time: Qt.formatDateTime(clock.date, "ddd HH:mm:ss")
    readonly property date date: clock.date

    SystemClock {
        id: clock

        precision: SystemClock.Seconds
    }

}
