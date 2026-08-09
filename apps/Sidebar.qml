import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland


PanelWindow {
    id: sidebar

    focusable: true
    color: "blue"
    exclusionMode: ExclusionMode.Ignore
    visible: false
    WlrLayershell.namespace: "quickshell:widgets"

    anchors {
        top: true
        bottom: true
        left: true
    }

    MouseArea {
        anchors.fill: parent
        // onClicked: 
    }

   

}
