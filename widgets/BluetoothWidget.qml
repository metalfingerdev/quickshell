// widgets/BluetoothWidget.qml
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Item {
    property var close: function() {}

    // Dismiss on background click
    MouseArea {
        anchors.fill: parent
        onClicked: close()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 0

        // ── Header row ───────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 32

            Text {
                text: "Bluetooth"
                color: Config.foreground
                font.family: "Maple Mono"
                font.pixelSize: 14
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }

            // Power toggle pill
            Rectangle {
                id: powerPill

                implicitWidth: powerLabel.implicitWidth + 16
                implicitHeight: 22
                radius: Config.radius
                color: powerPillArea.containsMouse ? Config.accent : Config.highlight

                Text {
                    id: powerLabel

                    anchors.centerIn: parent
                    text: BluetoothAdapter.powered ? "On" : "Off"
                    color: powerPillArea.containsMouse ? Config.bgDark : Config.accent
                    font.family: "Maple Mono"
                    font.pixelSize: 12
                }

                MouseArea {
                    id: powerPillArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothAdapter.togglePower()
                }
            }
        }

        // ── No adapter warning ────────────────────────────────────────
        Text {
            Layout.fillWidth: true
            visible: !BluetoothAdapter.available
            text: "No adapter found"
            color: "#ff5555"
            font.family: "Maple Mono"
            font.pixelSize: 12
        }

        // ── Divider ───────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            height: 1
            color: Config.foreground
            opacity: 0.15
            visible: BluetoothAdapter.powered
        }

        // ── Device list ───────────────────────────────────────────────
        ListView {
            id: deviceList

            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: BluetoothAdapter.powered
            clip: true
            model: BluetoothAdapter.devices
            spacing: 2

            delegate: Item {
                width: deviceList.width
                height: 32

                // Hover highlight
                Rectangle {
                    anchors.fill: parent
                    radius: Config.radius
                    color: Config.highlight
                    opacity: delegateArea.containsMouse ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation { duration: 120 }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    // BT device icon
                    Text {
                        text: modelData.connected ? "󰂱" : "󰂯"
                        color: modelData.connected ? Config.accent : Config.foreground
                        font.pixelSize: 14
                        font.family: "Maple Mono"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name || modelData.address
                        color: Config.foreground
                        font.family: "Maple Mono"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Text {
                        text: modelData.connected ? "Disconnect" : "Connect"
                        color: modelData.connected ? Config.accent : Config.foreground
                        opacity: 0.75
                        font.family: "Maple Mono"
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    id: delegateArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.connected
                        ? modelData.disconnect()
                        : modelData.connect()
                }
            }

            // Empty state
            Text {
                anchors.centerIn: parent
                visible: deviceList.count === 0 && BluetoothAdapter.powered
                text: BluetoothAdapter.isScanning ? "Scanning…" : "No devices found"
                color: Config.foreground
                opacity: 0.4
                font.family: "Maple Mono"
                font.pixelSize: 12
            }
        }

        // ── Divider ───────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            height: 1
            color: Config.foreground
            opacity: 0.15
            visible: BluetoothAdapter.powered
        }

        // ── Footer: scan + settings ───────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            visible: BluetoothAdapter.powered

            Text {
                text: BluetoothAdapter.isScanning ? "Stop Scan" : "Scan"
                color: scanArea.containsMouse ? Config.accent : Config.foreground
                font.family: "Maple Mono"
                font.pixelSize: 12

                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: scanArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothAdapter.toggleDiscovery()
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Settings"
                color: settingsArea.containsMouse ? Config.accent : Config.foreground
                font.family: "Maple Mono"
                font.pixelSize: 12

                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: settingsArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        close()
                        BluetoothAdapter.openSettings()
                    }
                }
            }
        }
    }
}