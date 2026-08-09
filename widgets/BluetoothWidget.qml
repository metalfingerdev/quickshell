// widgets/BluetoothWidget.qml
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

FocusScope {
    id: root

    property var close: function() {}

    Component.onCompleted: deviceList.forceActiveFocus()

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

        // ── Global error banner ─────────────────────────────────────
        Text {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: BluetoothAdapter.lastError.length > 0
            text: BluetoothAdapter.lastError
            color: "#ff5555"
            font.family: "Maple Mono"
            font.pixelSize: 11
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 2

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: BluetoothAdapter.lastError = ""
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

        // ── Device list ───────────────────────────────────────────────
        ListView {
            id: deviceList

            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: BluetoothAdapter.powered
            clip: true
            model: BluetoothAdapter.devices
            spacing: 2
            currentIndex: -1
            focus: true
            highlightFollowsCurrentItem: true

            Keys.onUpPressed: (event) => {
                if (count === 0) return
                currentIndex = currentIndex <= 0 ? count - 1 : currentIndex - 1
                event.accepted = true
            }

            Keys.onDownPressed: (event) => {
                if (count === 0) return
                currentIndex = currentIndex >= count - 1 ? 0 : currentIndex + 1
                event.accepted = true
            }

            Keys.onReturnPressed: {
                if (currentIndex >= 0 && currentItem && !currentItem.modelData.busy) {
                    currentItem.modelData.connected
                        ? currentItem.modelData.disconnect()
                        : currentItem.modelData.connect()
                }
            }

            delegate: Item {
                id: delegateRoot
                width: deviceList.width
                height: 32
                property var modelData: model.modelData ?? modelData

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

                // Keyboard-selection highlight (distinct border so it's visible
                // even when hover highlight isn't active)
                Rectangle {
                    anchors.fill: parent
                    radius: Config.radius
                    color: "transparent"
                    border.width: 1
                    border.color: Config.accent
                    opacity: deviceList.currentIndex === index ? 0.9 : 0

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

                    // Battery level, when known
                    Text {
                        visible: modelData.connected && modelData.battery >= 0
                        text: modelData.battery + "%"
                        color: Config.foreground
                        opacity: 0.6
                        font.family: "Maple Mono"
                        font.pixelSize: 11
                    }

                    // Busy spinner (simple rotating glyph, no extra assets needed)
                    Text {
                        visible: modelData.busy
                        text: "󰑮"
                        color: Config.foreground
                        opacity: 0.75
                        font.family: "Maple Mono"
                        font.pixelSize: 13

                        RotationAnimation on rotation {
                            running: modelData.busy
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: 900
                        }
                    }

                    Text {
                        visible: !modelData.busy
                        text: modelData.connected ? "Disconnect" : "Connect"
                        color: modelData.connected ? Config.accent : Config.foreground
                        opacity: 0.75
                        font.family: "Maple Mono"
                        font.pixelSize: 11
                    }

                    // Forget device
                    Text {
                        visible: !modelData.busy
                        text: "Forget"
                        color: forgetArea.containsMouse ? "#ff5555" : Config.foreground
                        opacity: forgetArea.containsMouse ? 1 : 0.5
                        font.family: "Maple Mono"
                        font.pixelSize: 11

                        Behavior on color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            id: forgetArea

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: modelData.forget()
                        }
                    }
                }

                // Per-device error, shown briefly under the row
                Text {
                    visible: modelData.error.length > 0
                    anchors.top: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    text: modelData.error
                    color: "#ff5555"
                    font.family: "Maple Mono"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }

                MouseArea {
                    id: delegateArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: modelData.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: !modelData.busy
                    onClicked: {
                        deviceList.currentIndex = index
                        modelData.connected
                            ? modelData.disconnect()
                            : modelData.connect()
                    }
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