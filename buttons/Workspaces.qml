import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

Repeater {
    id: wsRepeater

    property var switchView: function() { }

    model: Screens.workspaceIds

    Rectangle {
        id: wsButton

        // 'modelData' holds the actual ID from the array (e.g., 1, 2, 4...)
        property int wsId: modelData
        property var ws: Hyprland.workspaces.values.find((w) => {
            return w.id === wsId;
        })
        property bool isActive: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === wsId
        property bool hasWindows: wsButton.ws ? wsButton.ws.toplevels.values.length > 0 : false
        property bool isUrgent: wsButton.ws ? (wsButton.ws.urgent && !Screens.acknowledgedUrgent[wsId]) : false

        width: 28
        height: 28
        radius: Config.radius
        color: area.containsMouse ? Config.accent : (isUrgent ? flashBgColor : Config.highlight)
        
        property color flashColor: Config.highlight
        property color flashBgColor: Config.highlight
        property color flashTextColor: Config.foreground
        
        // 2. Animate both in parallel
        SequentialAnimation {
            running: wsButton.isUrgent
            loops: Animation.Infinite
            
            ParallelAnimation {
                ColorAnimation { target: wsButton; property: "flashBgColor"; to: Config.accent; duration: 400 }
                ColorAnimation { target: wsButton; property: "flashTextColor"; to: Config.bgDark; duration: 400 }
            }
            ParallelAnimation {
                ColorAnimation { target: wsButton; property: "flashBgColor"; to: Config.highlight; duration: 400 }
                ColorAnimation { target: wsButton; property: "flashTextColor"; to: Config.foreground; duration: 400 }
            }
        }

        Text {
            anchors.centerIn: parent
            text: wsId
            
            // 4. Update the text color with a clean ternary chain that checks isUrgent first
            color: area.containsMouse ? Config.bgDark : 
                   (isActive ? Config.accent : 
                   (isUrgent ? wsButton.flashTextColor : 
                   (hasWindows ? Config.foreground : Config.muted)))
                   
            font.pixelSize: Config.fontSize
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    if (typeof wsRepeater.switchView === "function")
                        wsRepeater.switchView("screen", 800, 400, 64, 8)
                } else {
                    // 1. Acknowledge the alert so it stops flashing
                    Screens.acknowledgeWorkspace(wsId);

                    // 2. Focus the workspace
                    if (wsButton.ws)
                        wsButton.ws.activate();
                    else
                        Hyprland.dispatch("hl.dsp.focus({workspace=" + wsId + "})")
                }
            }
        }
    }
}