import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.lock
import qs.modules.activatelinux
import qs.modules.services
import qs.modules.components

ShellRoot {
    id: root

    // input adapters: exactly one of each, shared by every screen
    Ipc {}
    Triggers {}
    
    Debug {}

    Lock {}

    ActivateLinux {}

    // services that must exist from the start (their IPC targets, the downloads and clipboard
    // watchers, the Super key's state), not only once a view shows them
    readonly property var services: [Wallpaper, Notifier, Sounds, Activities, ClipHistory, Emoji, Held]

    // a theme generated from the wallpaper follows it, and the island is the same glass as the
    // windows, moving as they do: Hyprland's window opacity and animation (Config is plain QtQuick
    // and can't ask)
    Binding { target: Config; property: "wallpaperSeed"; value: Wallpaper.seed }
    // From the wallpaper the surfaces come too: its option's hue and tint go into Config's own when the
    // image or the option changes, or the colours start coming from it (the Surface row moves them after)
    function takeWallpaperSurface(force) {
        if (Config.source === "wallpaper")
            Config.takeSurface(Wallpaper.option, Wallpaper.optionKey, force)
    }
    Connections { target: Wallpaper; function onOptionChanged() { root.takeWallpaperSurface(false) } }
    Connections { target: Config; function onSourceChanged() { root.takeWallpaperSurface(true) } }
    Binding { target: Config; property: "windowOpacity"; value: Desktops.windowOpacity }
    Binding { target: Config; property: "curve"; value: Desktops.windowCurve; when: Desktops.windowCurve !== null }
    Binding { target: Config; property: "motionMs"; value: Desktops.windowMs; when: Desktops.windowMs > 0 }

    Variants {
        model: Quickshell.screens

        Bar {}
    }
}
