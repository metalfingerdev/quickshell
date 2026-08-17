// config/quickshell/bo/SystemTray.qml
pragma Singleton

import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

Singleton {
    id: root

    // Expose the live list of tray items for consumers to iterate over.
    // Referencing SystemTray here is what causes Quickshell to start
    // tracking tray contents — items updates as apps come and go.
    property var items: SystemTray.items
}