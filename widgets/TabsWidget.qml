// config/quickshell/widgets/TabsWidget.qml
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.buttons
import qs.services

Item {
    id: root

    signal requestSurface(string name, real anchorX)

    Row {
        anchors.right: parent.horizontalCenter
        anchors.rightMargin: 16
        anchors.leftMargin: Config.margin
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: 32
            delegate: Item {
                required property int index
                readonly property real value: Cava.leftBars.length > index ? Cava.leftBars[index] : 0
                width: 3
                height: 32
                Rectangle {
                    width: parent.width
                    height: Math.max(0, parent.value * 28)
                    radius: 1
                    color: Config.foreground
                    anchors.centerIn: parent
                    Behavior on height {
                        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }

    Row {
        anchors.left: parent.horizontalCenter
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: 32
            delegate: Item {
                required property int index
                readonly property real value: Cava.rightBars.length > index ? Cava.rightBars[index] : 0
                width: 3
                height: 32
                Rectangle {
                    width: parent.width
                    height: Math.max(0, parent.value * 28)
                    radius: 1
                    color: Config.foreground
                    anchors.centerIn: parent
                    Behavior on height {
                        NumberAnimation { duration: 80; easing.type: Easing.OutCubic }
                    }
                }
            }
        }
    }

    Launcher {
        id: launcher
        onRequestSurface: (name, anchorX) => root.requestSurface(name, anchorX)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Config.margin
        anchors.rightMargin: Config.margin
        spacing: Config.spacing

        Workspaces { id: workspaces }

        Background {
            panelWindow: bar
        }

        Item { Layout.fillWidth: true }

        Battery {
            id: batteryBtn
            onClicked: {
                var pos = batteryBtn.mapToItem(null, batteryBtn.width / 2, 0)
                requestSurface("battery", pos.x)
            }
        }

        Network {
            id: networkBtn
            onClicked: {
                var pos = networkBtn.mapToItem(null, networkBtn.width / 2, 0)
                requestSurface("network", pos.x)
            }
        }

        Bluetooth {
            id: btBtn
            onClicked: {
                var pos = btBtn.mapToItem(null, btBtn.width / 2, 0)
                requestSurface("bluetooth", pos.x)
            }
        }

        Clock {
            id: clockBtn
            onClicked: {
                var pos = clockBtn.mapToItem(null, clockBtn.width / 2, 0)
                requestSurface("clock", pos.x)
            }
        }

        Bell {
            id: bellBtn
            onClicked: {
                var pos = bellBtn.mapToItem(null, bellBtn.width / 2, 0)
                root.requestSurface("notif", pos.x)
            }
        }
    }
}