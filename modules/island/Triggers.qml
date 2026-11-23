import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.services
import qs.modules.components

// System events -> alerts. Knows nothing about priority, timing or queueing: the machine decides.
Scope {
    id: root

    property bool followFocus: true
    property bool switcherToasts: true

    // services report their initial values at startup; don't toast those
    property bool armed: false
    Timer { interval: 2000; running: true; onTriggered: root.armed = true }

    function alert(view) { if (armed) Engine.alert(view) }

    Connections {
        target: Audio
        function onVolumeChanged() { root.alert(Engine.View.Volume) }
        function onMutedChanged()  { root.alert(Engine.View.Volume) }
        // only muting: apps with automatic gain move the mic's level all the time
        function onMicMutedChanged() { if (Audio.hasMic) root.alert(Engine.View.Mic) }
    }

    Connections {
        target: Backlight
        function onPercentChanged() { root.alert(Engine.View.Brightness) }
    }

    Connections {
        target: Hyprland
        enabled: root.followFocus
        function onFocusedMonitorChanged() {
            const name = Hyprland.focusedMonitor?.name
            if (name && Engine.idle) Engine.setScreen(name)
        }
    }

    // Priority 1 and queue: false (Registry), so it never interrupts a view and is never kept. Not over
    // Expanded either: at Peek any alert would replace it under the pointer.
    Connections {
        target: Hyprland
        enabled: root.switcherToasts
        function onFocusedWorkspaceChanged() {
            const id = Hyprland.focusedWorkspace?.id ?? -1
            if (id > 0 && !Engine.peeked) root.alert(Engine.View.Switcher)
        }
    }

    Connections {
        target: Energy
        function onPluggedChanged() {
            if (!Energy.present) return
            root.alert(Engine.View.Battery)
            if (root.armed) Sounds.play(Energy.plugged ? "power-plug" : "power-unplug")
        }
        function onWarn(critical) {
            const v = Engine.View.Battery
            Engine.alert(v, Registry.priority(v, critical))         // a warning skips the startup guard
            Sounds.play("dialog-warning")
        }
    }

    // The Colours view's eyedropper: the colour picked becomes the accent, and the view comes back
    // (Escape, and it comes back as it was).
    Connections {
        target: Toggles
        function onColourPicked(colour) {
            if (colour !== "") {
                Config.accent = colour
                Config.source = "accent"
                Config.remember(colour)
            }
            Engine.open(Engine.View.Colours)
        }
    }

    Connections {
        target: Activities
        function onEnded(ok) {
            root.alert(Engine.View.Activity)
            Sounds.play(ok ? "complete" : "dialog-error")
        }
    }

    // As a toast the view lives exactly as long as there are popups; pinned it is the center.
    readonly property bool notifications: Engine.view === Engine.View.Notifications
    readonly property bool popupShown: notifications && Engine.toast
    readonly property bool centerShown: notifications && Engine.pinned

    // Popups count down only while on screen and not under the pointer.
    Binding { target: Notifier; property: "held"; value: !root.popupShown || Engine.hovered }

    // Called later, never from inside Engine.send(): the center has seen everything, so nothing
    // is left to pop up; an emptied (or delivered-but-already-empty) popup view closes.
    function settle() {
        if (centerShown) Notifier.closeAll()
        else if (popupShown && Notifier.popups.length === 0) Engine.close()
    }

    // Notifications skip the startup guard: one arriving in the first 2 s should show.
    Connections {
        target: Notifier
        // Do not disturb: a quiet one never gets here, so it makes no sound either
        function onReceived(critical, fresh) {
            const v = Engine.View.Notifications
            if (!root.centerShown) Engine.alert(v, Registry.priority(v, critical))
            if (fresh) Sounds.play(critical ? "dialog-warning" : "message-new-instant")
        }
        function onPopupsChanged() { Qt.callLater(root.settle) }
    }

    Connections {
        target: Engine
        function onViewChanged()  { Qt.callLater(root.settle) }
        function onPhaseChanged() { Qt.callLater(root.settle) }     // popups -> center keeps the view
        // Pinned is when the island holds the keyboard. This fires before the release reaches Hyprland.
        function onPinnedChanged() { Desktops.keyboardHeld(Engine.pinned) }
    }
}