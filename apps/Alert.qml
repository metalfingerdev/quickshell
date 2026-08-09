import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Scope {
    id: root
    
    //NotificationServer {
    //    id: server
    //    actionsSupported: true
    //    bodySupported: true
    //    imageSupported: true
    //
    //    onNotification: (notification) => {
    //        notification.tracked = true;
    //        history.insert(0, {
    //            summary: notification.summary,
    //            body: notification.body,
    //            appName: notification.appName,
    //            urgency: notification.urgency,
    //            time: Qt.formatDataTime(new Date(), "HH:mm")
    //        })
    //    }
    //}

    PanelWindow {
        id: window

        anchors { top: true; right: true }
        margins { top: 8; right: 8 }

        implicitWidth: 400
        implicitHeight: Math.max(1, column.implicitHeight)
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:widgets"

        ColumnLayout {
            id: column

            width: parent.width
            spacing: 8

            Repeater {
                model: Notifications.trackedNotifications

                delegate: Rectangle {
                    id: card
                    required property var modelData

                    radius: 8
                    Layout.fillWidth: true
                    Layout.preferredHeight: layout.implicitHeight + 20

                    // Helper function to pick the color dynamically
                    function getUrgencyColor(urgency) {
                        switch(urgency) {
                            case NotificationUrgency.Critical: return Config.danger;
                            case NotificationUrgency.Normal:   return Config.accent;
                            case NotificationUrgency.Low:      return Config.warning;
                            default:                           return Config.highlight;
                        }
                    }
                    // Assign the color using the function
                    color: getUrgencyColor(modelData.urgency)

                    Timer {
                        running: card.modelData.urgency !== NotificationUrgency.Critical
                        interval: 5000
                        onTriggered: {
                            console.log("Auto-dismiss notification:", card.modelData.id);
                            card.modelData.dismiss();
                        }
                    }
                    
                    // MOVED ROWLAYOUT INSIDE THE RECTANGLE
                    RowLayout {
                        id: layout
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Image {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignLeft
                            visible: source.toString() !== ""
                            fillMode: Image.PreserveAspectFit
                            source: card.modelData.image || card.modelData.appIcon || ""
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                Layout.fillWidth: true
                                text: card.modelData.summary || card.modelData.appName || ""
                                color: Config.bgDark
                                font.family: "Maple Mono"
                                font.bold: true
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: card.modelData.body || ""
                                color: Config.bgDark
                                font.family: "Maple Mono"
                                font.bold: false
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    // Uncomment when ready - this also belongs inside the Rectangle
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            console.log("Notification clicked:", card.modelData.id, card.modelData.actions);
                            card.modelData.dismiss();
                        }
                    }

                } // <--- RECTANGLE NOW CLOSES HERE
            }
        }
    }
}