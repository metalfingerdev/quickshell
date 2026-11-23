pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.components

// Short cues from the freedesktop sound theme (message-new-instant, dialog-warning, power-plug...),
// played with pw-play. Who plays what is Triggers' business; Do not disturb already keeps a quiet
// notification from arriving at all. Commands: docs/ipc.md.
Singleton {
    id: root

    property bool enabled: true
    property real volume: 0.5               // 0..1, pw-play's own scale
    property Store store: Store {
        category: "sounds"
        property alias enabled: root.enabled
        property alias volume: root.volume
    }

    // The first theme folder that has it, then the system's (a service may get a short XDG_DATA_DIRS).
    readonly property string script: "IFS=:; for d in ${XDG_DATA_DIRS:-} /run/current-system/sw/share /usr/share; do "
        + "f=\"$d/sounds/freedesktop/stereo/$1.oga\"; [ -f \"$f\" ] && exec pw-play --volume \"$2\" \"$f\"; done"

    function play(name) {
        if (enabled && name && Toggles.has("pw-play"))
            Quickshell.execDetached(["sh", "-c", script, "sh", name, String(Math.max(0, Math.min(1, volume)))])
    }

    IpcHandler {
        target: "sounds"

        function enable(on: bool): void   { root.enabled = on }
        function toggle(): void           { root.enabled = !root.enabled }
        function volume(percent: int): void { root.volume = Math.max(0, Math.min(100, percent)) / 100 }
        function play(name: string): void { root.play(name) }
    }
}
