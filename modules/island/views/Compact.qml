import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The island grows to fit, so it's a capsule of whatever is there.
Item {
    id: root

    implicitWidth: Math.max(120, row.implicitWidth + 32)
    implicitHeight: 36

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 8

        // an activity running (Activities): how far it has got, or a stretch going back and forth
        // while it doesn't say, and what it is
        Row {
            visible: Activities.working
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 28; height: 4; radius: 2
                color: Config.container
                clip: true

                Rectangle {
                    property real sweep: 0
                    height: parent.height
                    radius: 2
                    color: Config.primary
                    width: Activities.level >= 0 ? Math.max(height, parent.width * Activities.level) : parent.width * 0.4
                    x: Activities.level >= 0 ? 0 : sweep
                    NumberAnimation on sweep {
                        running: Activities.working && Activities.level < 0
                        loops: Animation.Infinite
                        from: -12; to: 28; duration: 1100
                    }
                }
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 160)
                elide: Text.ElideRight
                text: Activities.label
                color: Config.dim
            }
        }

        Row {
            visible: Toggles.recording
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8; height: 8; radius: 4
                color: Config.recording
                SequentialAnimation on opacity {
                    running: Toggles.recording
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 700 }
                    NumberAnimation { to: 1; duration: 700 }
                }
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: Toggles.recordTime
                color: Config.recording
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
        }

        ClippingRectangle {
            visible: Players.hasTrack
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22
            radius: 11
            color: Config.container

            CoverImage {
                id: cover
                source: Players.active?.trackArtUrl ?? ""
                sourceSize: Qt.size(44, 44)
                visible: status === Image.Ready
                opacity: Players.playing ? 1 : 0.5
            }
            Equalizer {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                running: Players.playing
                barWidth: 2
                height: 12
                color: Config.primary
            }
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.pixelSize: Config.body + 1
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }

        // bars beside a cover too, so "playing" reads at a glance
        Equalizer {
            visible: Players.hasTrack && Players.playing && cover.status === Image.Ready
            anchors.verticalCenter: parent.verticalCenter
            running: Players.playing
            barWidth: 2
            height: 12
            color: Config.primary
        }

        Icon {
            visible: Notifier.dnd
            anchors.verticalCenter: parent.verticalCenter
            name: "do_not_disturb_on"
            size: 16
            filled: true
            color: Config.dim
        }

        Icon {
            visible: Energy.charging
            anchors.verticalCenter: parent.verticalCenter
            name: "bolt"
            size: 16
            filled: true
            color: Config.good
        }
    }
}
