import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import qs.config

Repeater {
    id: trayRepeater

    required property var panelWindow  // pass your PanelWindow id in from Bar.qml

    model: SystemTray.items

    delegate: Rectangle {
        id: trayButton

        required property var modelData

        width: 28
        height: 28
        radius: Config.radius
        color: area.containsMouse ? Config.accent : Config.highlight

        QsMenuAnchor {
            id: menuAnchor
            anchor.window: trayRepeater.panelWindow
            // Map the button's exact position to the absolute window coordinates
            anchor.rect: Qt.rect(
                trayButton.mapToItem(null, 0, 0).x,
                trayButton.mapToItem(null, 0, 0).y,
                trayButton.width,
                trayButton.height
            )
            menu: trayButton.modelData.menu
        }

        Image {
            id: trayIcon
            anchors.centerIn: parent
            width: 16
            height: 16
            source: trayButton.modelData.icon
            sourceSize.width: width
            sourceSize.height: height
            visible: status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            text: (trayButton.modelData.title || "?").charAt(0).toUpperCase()
            color: area.containsMouse ? Config.bgDark : Config.foreground
            font.pixelSize: Config.fontSize
            visible: trayIcon.status !== Image.Ready
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    if (trayButton.modelData.hasMenu)
                        menuAnchor.open()
                } else if (mouse.button === Qt.MiddleButton) {
                    trayButton.modelData.secondaryActivate()
                } else {
                    if (trayButton.modelData.onlyMenu)
                        menuAnchor.open()
                    else
                        trayButton.modelData.activate()
                }
            }

            onWheel: (wheel) => {
                trayButton.modelData.scroll(
                    wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : wheel.angleDelta.y,
                    wheel.angleDelta.x !== 0
                )
            }
        }

        ToolTip.visible: area.containsMouse && (trayButton.modelData.tooltipTitle !== "" || trayButton.modelData.title !== "")
        ToolTip.text: trayButton.modelData.tooltipTitle || trayButton.modelData.title
        ToolTip.delay: 600
    }
}