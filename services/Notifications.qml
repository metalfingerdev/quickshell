// config/quickshell/bo/Notifications.qml
pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

NotificationServer {
    id: server
    actionsSupported: true
    bodySupported: true
    imageSupported: true

    property ListModel history: ListModel {}

    onNotification: (notification) => {
        notification.tracked = true
        history.insert(0, {
            summary: notification.summary,
            body:    notification.body,
            appName: notification.appName,
            urgency: notification.urgency,
            time:    Qt.formatDateTime(new Date(), "HH:mm")
        })
    }
}