import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services
import qs.modules.parts

// The keybinds, by category (Super + Shift + / opens it). Written by hand from hypr's modules/binds.lua and
// nixos-dotfiles' docs/desktop.md: when a bind is added, moved or removed there, change it here too, or this
// view lies. Nothing reads Hyprland's live binds, so it also shows the ones only some machines have (the agent).
Panel {
    id: root

    property string section: "windows"

    readonly property var groups: [
        { key: "windows", label: "Windows", shortcut: "w", rows: [
            ["Close window", "Super Q"], ["Force-close window", "Super Shift Q"], ["Fullscreen", "Super F"],
            ["Toggle floating", "Super Shift Space"], ["Focus tiled / floating", "Super Space"],
            ["Pseudo-tile", "Super Ctrl Space"], ["Toggle split direction", "Super Alt Space"], ["Pin window", "Super A"],
            ["Move focus", "Super ←↑↓→ / HJKL"], ["Move window", "Super Shift ←↑↓→ / HJKL"],
            ["Resize (hold)", "Super Alt ←↑↓→ / HJKL"], ["Nudge a floating window (hold)", "Super Ctrl ←↑↓→ / HJKL"],
            ["Move / resize with the mouse", "Super drag"], ["Scratchpad", "Super Esc"], ["Window to the scratchpad", "Super Shift Esc"],
            ["Terminal", "Super Return"], ["Terminal with fastfetch", "Super Shift Return"], ["Coding agent", "Super Alt Return"],
            ["Files (yazi)", "Super E"], ["Launcher", "Super D"], ["Browser", "Super W"],
            ["Lock the screen", "Super Z"], ["Reload Hyprland and the island", "Super R"], ["Log out", "Super Shift Ctrl Q"]] },
        { key: "workspaces", label: "Workspaces", shortcut: "s", rows: [
            ["Go to workspace 1–10", "Super 1…0"], ["Move window to workspace 1–10", "Super Shift 1…0"],
            ["Previous / next workspace", "Super [ ]"], ["Move window there too", "Super Shift [ ]"],
            ["The last workspace", "Super `"], ["Scroll through workspaces", "Super scroll"],
            ["Workspaces overview (hold Super)", "Super Tab"], ["Overview, backwards", "Super Shift Tab"]] },
        { key: "island", label: "Island", shortcut: "i", rows: [
            ["Peek the island", "Super A"], ["Toggle auto-hide", "Super Shift A"], ["The hub", "Super Alt A"], ["The expanded view", "Super Ctrl A"],
            ["Dashboard", "Super G"], ["Edit the Control Centre", "Super Shift G"], ["Background apps", "Super Alt G"],
            ["Settings", "Super I"], ["Every setting", "Super Shift I"],
            ["Bluetooth", "Super B"], ["Network", "Super Y"], ["Notifications", "Super N"], ["What's running", "Super Ctrl N"],
            ["Volume mixer", "Super V"], ["Media", "Super M"], ["Battery", "Super U"],
            ["Theme and wallpaper", "Super T"], ["Colours", "Super Shift T"], ["Wallpapers: cycle / pick", "Super P / Super Ctrl P"],
            ["Colour from the screen, copied", "Super Shift U"], ["Clock", "Super C"], ["Agenda", "Super Shift C"], ["Tasks", "Super Alt C"], ["Power", "Super X"],
            ["System", "Super S"], ["NixOS generations", "Super Shift S"], ["Weather", "Super O"],
            ["Clipboard: cycle / browse", "Super Shift V / Super Ctrl V"], ["Emoji", "Super ."], ["Files in the launcher", "Super Ctrl D"],
            ["Launcher actions", "Super Shift D"], ["Favourites", "Super Alt D"], ["Ask the local model", "Super /"],
            ["These shortcuts", "Super Shift /"]] },
        { key: "media", label: "Media and screenshots", shortcut: "m", rows: [
            ["Screenshot an area (copied)", "Print"], ["Screenshot the screen (copied)", "Super Print"],
            ["Save an area to Pictures", "Super Shift Print"],
            ["Volume", "Volume keys"], ["Mute / mute the microphone", "Mute keys"], ["Brightness", "Brightness keys"],
            ["Play / pause", "Play key"], ["Next / previous track", "Next / Previous keys"]] }
    ]
    readonly property var group: groups.find(g => g.key === section) ?? groups[0]

    implicitWidth: 640
    icon: "keyboard"
    title: "Shortcuts"
    subtitle: group.label
    keys: [["W S I M", "category"], ["⌫", "back"], ["Esc", "close"]]

    Segmented {
        width: parent.width
        options: root.groups.map(g => ({ key: g.key, label: g.label, shortcut: g.shortcut }))
        current: root.section
        onPicked: key => root.section = key
    }

    ScrollList {
        id: list
        width: parent.width
        maxHeight: Math.min(8 * 56 + 2 * inset, Engine.room - 300)

        ListSection {
            width: list.innerWidth

            Repeater {
                model: root.group.rows

                ListEntry {
                    required property var modelData

                    flat: true
                    width: parent.width
                    title: modelData[0]
                    trailing: modelData[1]
                }
            }
        }
    }
}
