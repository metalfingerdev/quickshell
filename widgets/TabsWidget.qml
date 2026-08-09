import QtQuick
import QtQuick.Layouts
import qs.config
import qs.buttons

Item {
    id: root

    signal requestSurface(string name, real anchorX)

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
