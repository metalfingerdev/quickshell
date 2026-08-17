import QtQuick
import Quickshell.Io
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

Row {
    id: root
    spacing: 4

    property var monitor: Hyprland.monitorFor(QsWindow.window?.screen)

    property var occupiedIds: {
        var ids = []
        for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
            var w = Hyprland.workspaces.values[i]
            if (w.monitor === root.monitor && w.toplevels.values.length > 0) {
                ids.push(w.id)
            }
        }
        return ids
    }

    property int focusedId: root.monitor?.activeWorkspace?.id ?? 0

    property int lowestEmptyId: {
        var n = 1
        while (root.occupiedIds.indexOf(n) !== -1) {
            n++
        }
        return n
    }

    property var visibleIds: {
        var set = {}
        for (var i = 0; i < root.occupiedIds.length; i++) set[root.occupiedIds[i]] = true
        if (root.focusedId > 0) set[root.focusedId] = true
        if (root.lowestEmptyId <= 9) set[root.lowestEmptyId] = true

        var ids = Object.keys(set).map(Number).filter(n => n >= 1 && n <= 9)
        ids.sort((a, b) => a - b)
        return ids.length > 0 ? ids : [1]
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            Hyprland.refreshWorkspaces()
            Hyprland.refreshMonitors()
            Hyprland.refreshToplevels()
        }
    }

    Repeater {
        model: root.visibleIds
        Rectangle {
            id: button
            property var ws: Hyprland.workspaces.values.find(w => w.id === modelData)
            property bool isActive: root.monitor?.activeWorkspace?.id === modelData

            implicitWidth: 28
            implicitHeight: 28
            radius: Config.radius
            color: Config.highlight

            Text {
                anchors.centerIn: button
                text: modelData
                color: button.isActive ? Config.accent : Config.foreground
                font.pixelSize: 14
            }

            MouseArea {
                anchors.fill: button
                onClicked: {
                    Hyprland.dispatch("hl.dsp.focus({monitor=\"" + root.monitor.name + "\"})")
                    Hyprland.dispatch("hl.dsp.focus({workspace=" + modelData + "})")
                }
            }
        }
    }
}