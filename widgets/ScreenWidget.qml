import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services

Item {
    property var close: function() {}

    MouseArea {
        anchors.fill: parent
        onClicked: close()
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 16
    
        Repeater {
            model: Screens.workspaceIds
    
            Rectangle {
                id: workspaceCard
                required property var modelData
                property int wsId: modelData
    
                Layout.preferredWidth: 220
                Layout.preferredHeight: 160
                color: Config.bgLight
                radius: 8
                border.color: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId ? Config.accent : "transparent"
                border.width: 2
    
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6
    
                    Text {
                        text: "Workspace " + wsId
                        color: Config.foreground
                        font.family: "Maple Mono"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }
    
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4
    
                        Repeater {
                            model: {
                                let ws = Hyprland.workspaces.values.find(w => w.id === wsId)
                                return ws ? ws.toplevels.values : []
                            }
    
                            Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                color: Config.highlight
                                radius: 4
    
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    text: modelData.title ?? modelData.appId ?? "?"
                                    color: Config.foreground
                                    font.family: "Maple Mono"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    width: parent.width - 16
                                }
                            }
                        }
    
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 16
                            text: "Empty"
                            color: Config.muted
                            font.family: "Maple Mono"
                            font.pixelSize: 11
                            visible: {
                                let ws = Hyprland.workspaces.values.find(w => w.id === wsId)
                                return !ws || ws.toplevels.values.length === 0
                            }
                        }
    
                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}