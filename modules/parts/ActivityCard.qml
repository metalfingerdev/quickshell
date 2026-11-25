import QtQuick
import qs.modules.components
import qs.modules.services

// Every activity under way (a download, or any `qs ipc call activity …`), each with how far it is:
// Compact has room for the first one's name alone. After Nihil-Shell's downloads in the dashboard.
Rectangle {
    id: root

    implicitWidth: 420
    implicitHeight: list.implicitHeight + 24
    radius: Config.cardRadius
    color: Config.container

    Column {
        id: list
        x: 16
        y: 12
        width: parent.width - 32
        spacing: Config.spaceM

        Repeater {
            model: Activities.shared

            Column {
                id: job
                required property var modelData
                readonly property bool known: modelData.fraction >= 0
                width: list.width
                spacing: Config.spaceS

                Item {
                    width: parent.width
                    height: 20

                    Icon {
                        id: glyph
                        anchors.verticalCenter: parent.verticalCenter
                        name: /download|\.part$|\.crdownload$/i.test(job.modelData.id) ? "downloading" : "progress_activity"
                        size: 18
                        color: Config.primary
                    }
                    Label {
                        anchors { left: glyph.right; leftMargin: Config.spaceS; right: percent.left; rightMargin: Config.spaceS; verticalCenter: parent.verticalCenter }
                        text: job.modelData.label
                        elide: Text.ElideMiddle
                    }
                    Label {
                        id: percent
                        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                        text: job.known ? Math.round(job.modelData.fraction * 100) + "%" : ""
                        color: Config.dim
                        font.features: { "tnum": 1 }
                    }
                }
                // how far, or a stripe going back and forth while it doesn't say
                Item {
                    width: parent.width
                    height: 4
                    clip: true

                    Rectangle { anchors.fill: parent; radius: 2; color: Config.high }
                    Rectangle {
                        visible: job.known
                        width: parent.width * Math.max(0, Math.min(1, job.modelData.fraction))
                        height: parent.height
                        radius: 2
                        color: Config.primary
                    }
                    Rectangle {
                        id: stripe
                        visible: !job.known
                        width: parent.width / 3
                        height: parent.height
                        radius: 2
                        color: Config.primary
                        SequentialAnimation on x {
                            running: !job.known
                            loops: Animation.Infinite
                            NumberAnimation { from: -stripe.width; to: list.width; duration: Config.durationSweep; easing.type: Easing.InOutQuad }
                        }
                    }
                }
            }
        }
    }
}
