// widgets/NetworkWidget.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.services

FocusScope {
    id: root

    property var close: function() {}
    property var pendingNetwork: null
    property bool showPasswordPrompt: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // ── Header ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: NetworkAdapter.isScanning ? "Scanning..." : "Wi-Fi Networks"
                font.pixelSize: 20
                font.family: "Maple Mono"
                color: Config.foreground
            }

            Text {
                text: "󰑐"
                font.pixelSize: 16
                font.family: "Maple Mono"
                color: Config.foreground
                opacity: rescanArea.containsMouse ? 1.0 : 0.7

                RotationAnimator on rotation {
                    running: NetworkAdapter.isScanning
                    from: 0; to: 360
                    duration: 900
                    loops: Animation.Infinite
                }

                MouseArea {
                    id: rescanArea
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NetworkAdapter.toggleScan()
                }
            }

            Text {
                text: NetworkAdapter.wifiEnabled ? "Disable" : "Enable"
                font.pixelSize: 16
                font.family: "Maple Mono"
                color: Config.foreground
                opacity: enableArea.containsMouse ? 1.0 : 0.7

                MouseArea {
                    id: enableArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NetworkAdapter.toggleWifi()
                }
            }
        }

        // ── Ethernet row ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            visible: NetworkAdapter.isWired
            radius: 8
            color: Config.accent

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                    text: "󰈀"
                    font.pixelSize: 16
                    color: Config.bgDark
                }

                Text {
                    Layout.fillWidth: true
                    text: "Ethernet" + (NetworkAdapter.wiredName !== "" ? " · " + NetworkAdapter.wiredName : "")
                          + (NetworkAdapter.ipv4 !== "" ? " · " + NetworkAdapter.ipv4 : "")
                    font.pixelSize: 13
                    font.family: "Maple Mono"
                    color: Config.bgDark
                    elide: Text.ElideRight
                }

                Text {
                    text: "✓"
                    font.pixelSize: 14
                    color: Config.bgDark
                }
            }
        }

        // ── Network list ──────────────────────────────────────────────────────
        ListView {
            id: netList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            focus: !root.showPasswordPrompt
            currentIndex: 0
            interactive: true
            visible: !root.showPasswordPrompt

            Keys.onUpPressed:   event => { if (currentIndex > 0) currentIndex--;            event.accepted = true }
            Keys.onDownPressed: event => { if (currentIndex < count - 1) currentIndex++;    event.accepted = true }
            Keys.onReturnPressed: event => {
                if (currentIndex >= 0 && currentItem)
                    root.handleNetworkClick(currentItem.modelData)
                event.accepted = true
            }
            Keys.onEscapePressed: event => { root.close(); event.accepted = true }

            model: NetworkAdapter.availableNetworks

            Text {
                anchors.centerIn: parent
                visible: netList.count === 0 && !NetworkAdapter.isScanning
                text: "No networks found"
                font.pixelSize: 14
                font.family: "Maple Mono"
                color: Config.foreground
                opacity: 0.5
            }

            delegate: Rectangle {
                id: delegateRoot
                required property var modelData
                required property int index
                readonly property bool isCurrent:   ListView.isCurrentItem
                readonly property bool isConnected: NetworkAdapter.activeNet === modelData

                width: ListView.view.width
                height: 48
                radius: 8
                color: isConnected
                    ? Config.accent
                    : (isCurrent || area.containsMouse ? Config.highlight : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    // Signal icon
                    Text {
                        text: {
                            var s = modelData.signalStrength
                            if (s >= 0.75) return "󰤨"
                            if (s >= 0.50) return "󰤥"
                            if (s >= 0.25) return "󰤢"
                            return "󰤟"
                        }
                        font.pixelSize: 16
                        color: isConnected ? Config.bgDark : Config.foreground
                    }

                    // SSID
                    Text {
                        Layout.fillWidth: true
                        text: modelData.name || "Hidden Network"
                        color: isConnected ? Config.bgDark : Config.foreground
                        font.bold: isCurrent
                        font.pixelSize: 15
                        font.family: "Maple Mono"
                        elide: Text.ElideRight
                    }

                    // Lock icon for secured networks
                    Text {
                        visible: !isConnected && (modelData.secured ?? false)
                        text: "󰌾"
                        font.pixelSize: 12
                        color: Config.foreground
                        opacity: 0.5
                    }

                    // Connected check
                    Text {
                        visible: isConnected
                        text: "✓"
                        font.pixelSize: 14
                        color: Config.bgDark
                    }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        netList.currentIndex = index
                        root.handleNetworkClick(modelData)
                    }
                    onEntered: netList.currentIndex = index
                }
            }
        }

        // ── Password prompt ───────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.showPasswordPrompt

            Text {
                Layout.fillWidth: true
                text: "Password for \"" + (root.pendingNetwork?.name ?? "") + "\""
                font.pixelSize: 13
                font.family: "Maple Mono"
                color: Config.foreground
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 6
                color: Config.highlight

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.margins: 10
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    font.pixelSize: 14
                    font.family: "Maple Mono"
                    color: Config.foreground
                    focus: root.showPasswordPrompt
                    selectionColor: Config.accent

                    Keys.onReturnPressed: root.submitPassword()
                    Keys.onEscapePressed: root.cancelPassword()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Show/hide password toggle
                Text {
                    text: passwordInput.echoMode === TextInput.Password ? "Show" : "Hide"
                    font.pixelSize: 13
                    font.family: "Maple Mono"
                    color: Config.foreground
                    opacity: showPassArea.containsMouse ? 1.0 : 0.6

                    MouseArea {
                        id: showPassArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: passwordInput.echoMode =
                            passwordInput.echoMode === TextInput.Password
                                ? TextInput.Normal
                                : TextInput.Password
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Cancel"
                    font.pixelSize: 13
                    font.family: "Maple Mono"
                    color: Config.foreground
                    opacity: cancelArea.containsMouse ? 1.0 : 0.6

                    MouseArea {
                        id: cancelArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancelPassword()
                    }
                }

                Rectangle {
                    implicitWidth: connectLabel.implicitWidth + 16
                    implicitHeight: 28
                    radius: 6
                    color: connectBtnArea.containsMouse ? Config.accent : Config.highlight

                    Text {
                        id: connectLabel
                        anchors.centerIn: parent
                        text: "Connect"
                        font.pixelSize: 13
                        font.family: "Maple Mono"
                        color: connectBtnArea.containsMouse ? Config.bgDark : Config.foreground
                    }

                    MouseArea {
                        id: connectBtnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submitPassword()
                    }
                }
            }
        }

        // ── Footer ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            visible: !root.showPasswordPrompt

            Text {
                text: NetworkAdapter.detailLabel
                font.pixelSize: 11
                font.family: "Maple Mono"
                color: Config.foreground
                opacity: 0.45
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Settings"
                font.pixelSize: 12
                font.family: "Maple Mono"
                color: Config.foreground
                opacity: settingsArea.containsMouse ? 1.0 : 0.5

                MouseArea {
                    id: settingsArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.close(); NetworkAdapter.openSettings() }
                }
            }
        }
    }

    // ── Logic ─────────────────────────────────────────────────────────────────

    function handleNetworkClick(net) {
        if (NetworkAdapter.activeNet === net) {
            NetworkAdapter.disconnectActive()
            return
        }
        if (net.secured ?? false) {
            root.pendingNetwork = net
            root.showPasswordPrompt = true
            passwordInput.text = ""
            passwordInput.forceActiveFocus()
        } else {
            NetworkAdapter.connectTo(net)
        }
    }

    function submitPassword() {
        if (root.pendingNetwork && passwordInput.text.length > 0) {
            root.pendingNetwork.connectWithPassword(passwordInput.text)
        }
        root.cancelPassword()
    }

    function cancelPassword() {
        root.showPasswordPrompt = false
        root.pendingNetwork = null
        passwordInput.text = ""
        netList.forceActiveFocus()
    }
}