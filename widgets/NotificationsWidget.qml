// widgets/NotificationsWidget.qml
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Item {
    property var close: function() {}

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: close()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // ── Header ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            Text {
                Layout.fillWidth: true
                text: "Notifications"
                font.pixelSize: 20
                font.family: "Maple Mono"
                color: Config.foreground
            }

            Text {
                visible: Notifications.history.count > 0
                text: "Clear all"
                font.pixelSize: 13
                font.family: "Maple Mono"
                color: Config.foreground
                opacity: clearArea.containsMouse ? 1.0 : 0.5

                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.history.clear()
                }
            }
        }

        // ── Empty state ───────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Notifications.history.count === 0

            Text {
                anchors.centerIn: parent
                text: "No notifications"
                font.family: "Maple Mono"
                font.pixelSize: 13
                color: Config.foreground
                opacity: 0.35
            }
        }

        // ── List ──────────────────────────────────────────────────────────────
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: Notifications.history.count > 0
            clip: true
            spacing: 6
            model: Notifications.history

            delegate: Rectangle {
                required property var modelData
                required property int index

                width: ListView.view.width
                height: notifCol.implicitHeight + 16
                radius: 8
                color: Config.highlight

                // Urgency accent strip
                Rectangle {
                    width: 3
                    height: parent.height - 8
                    anchors.left: parent.left
                    anchors.leftMargin: 0
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: {
                        switch (modelData.urgency) {
                            case 2:  return "#ff5555"   // critical
                            case 1:  return Config.accent // normal
                            default: return Config.foreground // low
                        }
                    }
                    opacity: 0.8
                }

                ColumnLayout {
                    id: notifCol
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 8
                        leftMargin: 14
                    }
                    spacing: 2

                    // App + time row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: modelData.appName || "Unknown"
                            font.family: "Maple Mono"
                            font.pixelSize: 10
                            color: Config.foreground
                            opacity: 0.45
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: modelData.time || ""
                            font.family: "Maple Mono"
                            font.pixelSize: 10
                            color: Config.foreground
                            opacity: 0.35
                        }

                        // Dismiss button
                        Text {
                            text: "✕"
                            font.family: "Maple Mono"
                            font.pixelSize: 10
                            color: Config.foreground
                            opacity: dismissArea.containsMouse ? 1.0 : 0.35

                            MouseArea {
                                id: dismissArea
                                anchors.fill: parent
                                anchors.margins: -4
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifications.history.remove(index)
                            }
                        }
                    }

                    // Summary
                    Text {
                        Layout.fillWidth: true
                        visible: modelData.summary !== ""
                        text: modelData.summary || ""
                        font.family: "Maple Mono"
                        font.pixelSize: 13
                        font.bold: true
                        color: Config.foreground
                        wrapMode: Text.WordWrap
                    }

                    // Body
                    Text {
                        Layout.fillWidth: true
                        visible: (modelData.body || "") !== ""
                        text: modelData.body || ""
                        font.family: "Maple Mono"
                        font.pixelSize: 12
                        color: Config.foreground
                        opacity: 0.7
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}