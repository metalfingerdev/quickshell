pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// The island as the session's polkit agent: an app that needs root (pkexec, a GUI installer, the
// Generations cleanup) asks here instead of getting no prompt at all. views/Auth.qml shows the request;
// the password goes straight to the flow's responder and is never kept.
Singleton {
    id: root

    readonly property var flow: agent.flow
    readonly property bool active: agent.isActive
    signal asked()          // a request began: Triggers brings the view up
    signal ended()          // it was answered or withdrawn: the view goes

    function submit(text) { if (flow) flow.submit(text) }
    function cancel() { if (flow && !flow.isCompleted) flow.cancelAuthenticationRequest() }

    PolkitAgent {
        id: agent
        onAuthenticationRequestStarted: {
            // with no identity chosen the flow never asks anything; the first one is the usual admin
            const f = agent.flow
            if (f && !f.selectedIdentity && f.identities.length > 0) f.selectedIdentity = f.identities[0]
            root.asked()
        }
    }
    Connections {
        target: agent.flow
        ignoreUnknownSignals: true
        function onIsCompletedChanged() { if (agent.flow?.isCompleted) root.ended() }
    }
}
