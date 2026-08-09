// config/quickshell/bo/Screens.qml
pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root
    property string time
    property var acknowledgedUrgent: ({})

// Clear acknowledgment when the workspace is actually focused by the user
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            let focusedId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1;
            if (focusedId > 0 && root.acknowledgedUrgent[focusedId]) {
                let copy = Object.assign({}, root.acknowledgedUrgent);
                delete copy[focusedId];
                root.acknowledgedUrgent = copy;
            }
        }
    }

    function acknowledgeWorkspace(id) {
        let copy = Object.assign({}, root.acknowledgedUrgent);
        copy[id] = true;
        root.acknowledgedUrgent = copy;
    }

    // Move the logic here as a pure data property
    property var workspaceIds: {
        // 1 and 2 are always present
        let ids = [1, 2];
        let activeWorkspaces = Hyprland.workspaces.values;
        
        for (let i = 0; i < activeWorkspaces.length; i++) {
            let id = activeWorkspaces[i].id;
            // Add other active workspaces (ignoring negative IDs for named workspaces)
            if (id > 0 && !ids.includes(id)) {
                ids.push(id);
            }
        }
        
        // Sort them numerically so the buttons appear in order
        ids.sort((a, b) => {
            return a - b;
        });

        // Get the highest workspace ID currently in the list
        let lastId = ids[ids.length - 1];
        
        // Find if that specific workspace currently exists and has windows
        let lastWs = activeWorkspaces.find(w => w.id === lastId);
        if (lastWs && lastWs.toplevels.values.length > 0) {
            ids.push(lastId + 1);
        }

        return ids;
    }
}