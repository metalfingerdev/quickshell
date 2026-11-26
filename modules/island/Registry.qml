pragma Singleton

import QtQuick

QtObject {
    id: registry

    readonly property var entries: [
        { name: "compact",    priority: 0, timeout: 0,    view: Engine.View.Compact,    url: Qt.resolvedUrl("views/Compact.qml") },
        { name: "expanded",   priority: 2, timeout: 6000, view: Engine.View.Expanded,   url: Qt.resolvedUrl("views/Expanded.qml") },
        { name: "tabs",       priority: 2, timeout: 8000, view: Engine.View.Tabs,       url: Qt.resolvedUrl("views/Tabs.qml") },
        { name: "dashboard",  priority: 2, timeout: 12000, view: Engine.View.Dashboard, url: Qt.resolvedUrl("views/Dashboard.qml") },
        { name: "network",    priority: 2, timeout: 5000, view: Engine.View.Network,    url: Qt.resolvedUrl("views/Network.qml") },
        { name: "launcher",   priority: 2, timeout: 8000, view: Engine.View.Launcher,   url: Qt.resolvedUrl("views/Launcher.qml") },
        { name: "bluetooth",  priority: 2, timeout: 5000, view: Engine.View.Bluetooth,  url: Qt.resolvedUrl("views/Bluetooth.qml") },
        { name: "volume",     priority: 1, timeout: 1500, view: Engine.View.Volume,     url: Qt.resolvedUrl("views/Volume.qml"),     queue: false,
          opens: Engine.View.Dashboard },
        { name: "brightness", priority: 1, timeout: 1500, view: Engine.View.Brightness, url: Qt.resolvedUrl("views/Brightness.qml"), queue: false,
          opens: Engine.View.Dashboard },
        { name: "mic",        aliases: ["microphone"], priority: 1, timeout: 1500, view: Engine.View.Mic, url: Qt.resolvedUrl("views/Mic.qml"), queue: false,
          opens: Engine.View.Mixer },
        // timeout 0: Notifier times each popup, and Triggers closes the view when the last one goes.
        // `critical`: the priority a critical one alerts with.
        { name: "notifications", priority: 2, critical: 3, timeout: 0, view: Engine.View.Notifications, url: Qt.resolvedUrl("views/Notification.qml"), queue: true },
        { name: "media",      priority: 2, timeout: 8000, view: Engine.View.Media,      url: Qt.resolvedUrl("views/Media.qml") },
        { name: "mixer",      priority: 2, timeout: 8000, view: Engine.View.Mixer,      url: Qt.resolvedUrl("views/Mixer.qml") },
        { name: "battery",    priority: 2, critical: 3, timeout: 4000, view: Engine.View.Battery, url: Qt.resolvedUrl("views/Battery.qml"), queue: true },
        // an activity that ended (a toast), or, pinned, those still running (Activities)
        { name: "activity",   aliases: ["activities"], priority: 2, timeout: 5000, view: Engine.View.Activity, url: Qt.resolvedUrl("views/Activity.qml"), queue: true },
        { name: "clock",      priority: 2, timeout: 8000, view: Engine.View.Clock,      url: Qt.resolvedUrl("views/Clock.qml") },
        { name: "power",      priority: 2, timeout: 8000, view: Engine.View.Power,      url: Qt.resolvedUrl("views/Power.qml") },
        { name: "theme",      priority: 2, timeout: 8000, view: Engine.View.Theme,      url: Qt.resolvedUrl("views/Theme.qml") },
        { name: "colours",    aliases: ["colors"],    priority: 2, timeout: 8000, view: Engine.View.Colours,    url: Qt.resolvedUrl("views/Colours.qml") },
        { name: "wallpapers", aliases: ["wallpaper"], priority: 2, timeout: 8000, view: Engine.View.Wallpapers, url: Qt.resolvedUrl("views/Wallpapers.qml") },
        { name: "settings",   priority: 2, timeout: 8000, view: Engine.View.Settings,   url: Qt.resolvedUrl("views/Settings.qml") },
        { name: "island", priority: 2, timeout: 8000, view: Engine.View.SettingsIsland, url: Qt.resolvedUrl("views/SettingsIsland.qml") },
        { name: "glass", priority: 2, timeout: 8000, view: Engine.View.SettingsGlass, url: Qt.resolvedUrl("views/SettingsGlass.qml") },
        { name: "alerts", priority: 2, timeout: 8000, view: Engine.View.SettingsAlerts, url: Qt.resolvedUrl("views/SettingsAlerts.qml") },
        { name: "energy", priority: 2, timeout: 8000, view: Engine.View.SettingsEnergy, url: Qt.resolvedUrl("views/SettingsEnergy.qml") },
        { name: "lockscreen", priority: 2, timeout: 8000, view: Engine.View.SettingsLock, url: Qt.resolvedUrl("views/SettingsLock.qml") },
        { name: "wallpaper-settings", priority: 2, timeout: 8000, view: Engine.View.SettingsWallpaper, url: Qt.resolvedUrl("views/SettingsWallpaper.qml") },
        { name: "workspaces", priority: 2, timeout: 8000, view: Engine.View.Workspaces, url: Qt.resolvedUrl("views/Workspaces.qml") },
        { name: "clipboard",  aliases: ["history"], priority: 2, timeout: 10000, view: Engine.View.Clipboard, url: Qt.resolvedUrl("views/Clipboard.qml") },
        // timeout 0: a conversation stays until Escape or a click outside; as a toast (an answer that
        // ended with the view closed) Triggers times it, longer for a longer answer
        { name: "agent",      aliases: ["ai", "ask", "chat"], priority: 2, timeout: 0, view: Engine.View.Agent, url: Qt.resolvedUrl("views/Conversation.qml"), queue: true },
        { name: "system",     aliases: ["stats"],    priority: 2, timeout: 8000, view: Engine.View.System,   url: Qt.resolvedUrl("views/System.qml") },
        { name: "weather",    aliases: ["forecast"], priority: 2, timeout: 8000, view: Engine.View.Weather,  url: Qt.resolvedUrl("views/Forecast.qml") },
        { name: "agenda",     aliases: ["events", "schedule"], priority: 2, timeout: 8000, view: Engine.View.Agenda, url: Qt.resolvedUrl("views/Schedule.qml") },
        { name: "tray",       aliases: ["systray"], priority: 2, timeout: 8000, view: Engine.View.Tray, url: Qt.resolvedUrl("views/TrayMenu.qml") },
        { name: "generations", aliases: ["updates", "nixos"], priority: 2, timeout: 12000, view: Engine.View.Generations, url: Qt.resolvedUrl("views/History.qml") },
        // timeout 0: a board being sorted stays until Escape or a click outside, as the agent does
        { name: "tasks",      aliases: ["todo", "kanban", "board"], priority: 2, timeout: 0, view: Engine.View.Tasks, url: Qt.resolvedUrl("views/Board.qml") },
        { name: "dock",       aliases: ["favourites", "favorites", "apps"], priority: 2, timeout: 6000, view: Engine.View.Dock, url: Qt.resolvedUrl("views/Dock.qml") },
        { name: "advanced",   aliases: ["prefs"], priority: 2, timeout: 0, view: Engine.View.Advanced, url: Qt.resolvedUrl("views/Advanced.qml") },
        // `opens`: a click on the toast opens this instead of pinning the toast
        { name: "switcher",   priority: 1, timeout: 1200, view: Engine.View.Switcher,   url: Qt.resolvedUrl("views/Switcher.qml"), queue: false,
          opens: Engine.View.Tabs }
    ]

    // A non-number (e.g. an enum name that doesn't exist yet: Qt keeps a singleton's old enum across a
    // hot reload) must never match an entry, or the machine would accept a view nothing can show or end.
    function get(view) { return typeof view === "number" ? entries.find(e => e.view === view) || null : null }
    function byName(name)    { return entries.find(e => e.name === name || (e.aliases ?? []).includes(name)) || null }
    function priority(view, critical) {
        const e = get(view)
        if (!e) return -1
        return critical && e.critical !== undefined ? e.critical : e.priority
    }
    function timeout(view)   { return get(view)?.timeout ?? 0 }
    function queues(view)    { return !!get(view)?.queue }
    function name(view)      { return get(view)?.name ?? "?" }
}