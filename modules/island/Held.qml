pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Going through a view with its key while Super is held, as Alt+Tab does: Super+Tab opens the
// workspaces, Tab again with Super still down moves to the next one (Shift+Tab: the one before), and
// letting go of Super goes there. Let go before moving, and the view stays open for the arrows,
// Enter or a click. The keys come as IPC (`island cycle <view> <delta>`); Hyprland reports Super
// going down and up as the global shortcut quickshell:island-super (hypr/modules/binds.lua).
// A view takes part by answering stepped(view, delta) and chosen(view) for its own Engine.View.
Singleton {
    id: root

    property bool superDown: false
    property int view: -1                // the view being gone through while Super is held
    property bool moved: false

    signal stepped(int view, int delta)
    signal chosen(int view)

    function cycle(v, delta) {
        if (!(Engine.pinned && Engine.view === v)) {
            Engine.open(v)
            view = superDown ? v : -1
            moved = false
            return
        }
        Engine.key()                     // a keystroke: the countdown starts again
        if (superDown) view = v
        moved = true
        stepped(v, delta)
    }

    onSuperDownChanged: {
        if (superDown) return
        const v = view
        view = -1
        if (v >= 0 && moved && Engine.pinned && Engine.view === v) chosen(v)
        moved = false
    }

    GlobalShortcut {
        name: "island-super"
        description: "Super down and up, for the views gone through with their key held"
        onPressed: root.superDown = true
        onReleased: root.superDown = false
    }
}
