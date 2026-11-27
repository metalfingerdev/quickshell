import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.services
import qs.modules.components

// System events -> alerts. Knows nothing about priority, timing or queueing: the machine decides.
Scope {
    id: root

    property bool followFocus: true
    readonly property bool switcherToasts: Config.switcherToasts

    // services report their initial values at startup; don't toast those
    property bool armed: false
    Timer { interval: 2000; running: true; onTriggered: root.armed = true }

    function alert(view) { if (armed) Engine.alert(view) }

    // the toasts that only echo a key can be turned off (Settings' Alerts)
    Connections {
        target: Audio
        enabled: Config.levelToasts
        function onVolumeChanged() { root.alert(Engine.View.Volume) }
        function onMutedChanged()  { root.alert(Engine.View.Volume) }
        // only muting: apps with automatic gain move the mic's level all the time
        function onMicMutedChanged() { if (Audio.hasMic) root.alert(Engine.View.Mic) }
    }

    Connections {
        target: Backlight
        enabled: Config.levelToasts
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

    // A fullscreen window on the island's screen turns auto-hide on, and its end turns it back off, so
    // the island isn't drawn over a game or a video (it's on the overlay layer). Only undone if it was
    // turned on here: auto-hide chosen in Settings stays.
    readonly property bool fullscreen: (Engine.screen ? Hyprland.monitorFor(Engine.screen) : null)?.activeWorkspace?.hasFullscreen ?? false
    property bool hidForFullscreen: false
    onFullscreenChanged: {
        if (fullscreen && !Engine.autoHide) { hidForFullscreen = true; Engine.setAutoHide(true) }
        else if (!fullscreen && hidForFullscreen) { hidForFullscreen = false; Engine.setAutoHide(false) }
    }
    // hasFullscreen is a cached copy of Hyprland's workspace, which Quickshell doesn't refresh when a window
    // goes fullscreen or leaves (or is closed or moved while it is): without this the island kept showing.
    // Hyprland's own events are the trigger, coalesced since a window change sends several.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["fullscreen", "workspacev2", "focusedmonv2", "openwindow", "closewindow", "movewindowv2"].includes(event.name))
                fullscreenRefresh.restart()
        }
    }
    // the agent is about to use the screen: the island steps aside first
    Connections {
        target: Agent
        function onAside() { Engine.close() }
    }
    Timer {
        id: fullscreenRefresh
        interval: 40
        onTriggered: { Hyprland.refreshWorkspaces(); Hyprland.refreshMonitors() }
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
            if (!root.armed) return
            Sounds.play(Energy.plugged ? "power-plug" : "power-unplug")
        }
        function onWarn(critical) {
            const v = Engine.View.Battery
            Engine.alert(v, Registry.priority(v, critical))         // a warning skips the startup guard
            Sounds.play("dialog-warning")
        }
    }

    // The eyedropper: the colour picked goes where Toggles.pickTarget says, and the view that asked comes
    // back (Escape, and it comes back as it was).
    function place(target, colour) {
        const p = target.split(":"), alpha = (old, key) => key === "tint_color" ? String(old).slice(7, 9) || "ff" : "ff"
        if (p[0] === "copy") Quickshell.clipboardText = colour
        else if (p[0] === "accent") { Config.accent = colour; Config.source = "accent"; Config.remember(colour) }
        else if (p[0] === "role") {
            const all = Object.assign({}, p[1] === "dark" ? Config.rolesDark : Config.rolesLight)
            all[p[2]] = Config.argb(Qt.color(colour))
            if (p[1] === "dark") Config.rolesDark = all; else Config.rolesLight = all
        }
        else if (p[0] === "hg") Glass.setIn("hg", p[1], p[2], p[3], colour + alpha(Glass.glassValue(p[1], p[3]), p[3]))
        else if (p[0] === "hl") Glass.setIn("hl", "", p[1], p.slice(2).join(":"), colour + "ff")
        else if (p[0] === "pref") { const e = Prefs.entries.find(e => e.key === p[1]); if (e) Prefs.set(e, e.p.startsWith("roles") ? Config.argb(Qt.color(colour)) : colour) }
    }
    Connections {
        target: Toggles
        function onColourPicked(colour) {
            if (colour !== "") root.place(Toggles.pickTarget, colour)
            if (Toggles.pickTarget === "copy") return              // nothing to come back to
            Toggles.pickBack = Toggles.pickTarget
            Engine.open(Toggles.pickView >= 0 ? Toggles.pickView : Engine.View.Colours)
        }
    }

    Connections {
        target: Activities
        function onEnded(ok) {
            root.alert(Engine.View.Activity)
            Sounds.play(ok ? "complete" : "dialog-error")
        }
    }

    // The agent's answer, when it ends with the conversation closed (Escape while it answered): a peek
    // with the question and how the answer starts; a click opens the conversation. As Nilo's: longer
    // for a longer answer (7 to 20 s), held while the pointer is on it; Do not disturb leaves it in the
    // conversation alone. A question the agent waits on peeks the same way, for half a minute: without
    // it, the answer would sit unasked for the five minutes the agent gives it.
    Connections {
        target: Agent
        function onAnswered(question, answer, ok) {
            if (!ok || answer === "") return
            root.agentAlert()
        }
        function onAskingChanged() { if (Agent.asking) root.agentAlert() }
    }
    function agentAlert() {
        if (Notifier.dnd || (Engine.pinned && Engine.view === Engine.View.Agent)) return
        root.alert(Engine.View.Agent)
        Sounds.play("message-new-instant")
    }
    readonly property bool agentPeek: Engine.toast && Engine.view === Engine.View.Agent
    Timer {
        interval: Agent.asking ? 30000 : Math.min(20000, 7000 + Math.ceil(Agent.lastAnswer.length / 45) * 1000)
        running: root.agentPeek && !Engine.hovered
        onTriggered: Engine.close()
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
            if (!fresh) return
            Sounds.play(critical ? "dialog-warning" : "message-new-instant")
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