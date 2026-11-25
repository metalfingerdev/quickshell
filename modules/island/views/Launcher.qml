import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

Item {
    id: root

    readonly property int maxRows: 7
    readonly property int maxResults: 24     // per source
    readonly property int rowH: 64
    readonly property string terminal: "kitty"
    readonly property string agent: "crush"      // the terminal coding agent: the Coding agent action starts it
    readonly property var filters: [
        { key: "all",     label: "All" },
        { key: "apps",    label: "Apps" },
        { key: "files",   label: "Files" },
        { key: "actions", label: "Actions" },
        { key: "clipboard", label: "Clipboard" },
        { key: "emoji",   label: "Emoji" }
    ]
    // the filter it opens on: IPC `launch <filter>` sets it just before (Super+. opens Emoji)
    property string filter: Engine.launcherFilter
    Component.onCompleted: { Engine.launcherFilter = "all"; ClipHistory.refresh() }
    property int selected: 0
    readonly property string query: bar.text.trim().toLowerCase()

    property string usesJson: "{}"
    property Store store: Store {
        category: "launcher"
        property alias uses: root.usesJson
    }
    readonly property var uses: { try { return JSON.parse(usesJson) } catch (e) { return {} } }
    function used(app) { return uses[app.id] ?? 0 }
    function count(app) {
        const u = Object.assign({}, uses)
        u[app.id] = (u[app.id] ?? 0) + 1
        usesJson = JSON.stringify(u)
    }

    // 0 = no match; higher = better
    function score(app, q) {
        const name = app.name.toLowerCase()
        if (name.startsWith(q)) return 500
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 400
        if (name.includes(q)) return 300
        const extra = [app.genericName ?? "", String(app.keywords ?? ""), app.id ?? ""].join(" ").toLowerCase()
        if (extra.includes(q)) return 200
        let i = 0
        for (const c of name) if (c === q[i]) i++
        return i === q.length ? 100 : 0
    }
    readonly property var apps: {
        const q = query
        const all = Array.from(DesktopEntries.applications.values).filter(a => !a.noDisplay)
        const ranked = q === ""
            ? all.map(a => ({ app: a, score: used(a) > 0 ? 1 : 0 }))
            : all.map(a => ({ app: a, score: score(a, q) })).filter(m => m.score > 0)
        return ranked
            .sort((a, b) => (b.score - a.score) || (used(b.app) - used(a.app)) || (a.app.name.length - b.app.name.length)
                            || a.app.name.localeCompare(b.app.name))
            .slice(0, maxResults)
            .map(m => ({ kind: "app", app: m.app, name: m.app.name,
                         description: m.app.comment || m.app.genericName || "" }))
    }

    function view(v) { return () => Engine.open(v) }
    function quit(f) { return () => { Engine.close(); f() } }
    readonly property var actions: [
        { name: "Tabs", description: "Every view, and the workspaces", icon: Config.symbol.hub, keys: "hub all views", run: view(Engine.View.Tabs) },
        { name: "Dashboard", description: "Quick settings, volume and brightness", icon: Config.symbol.dashboard, run: view(Engine.View.Dashboard) },
        { name: "Wi-Fi", description: "Networks and connections", icon: "wifi", keys: "network internet wlan ethernet", run: view(Engine.View.Network) },
        { name: "Bluetooth", description: "Devices", icon: "bluetooth", keys: "headphones pair", run: view(Engine.View.Bluetooth) },
        { name: "Notifications", description: "Everything that arrived", icon: Config.symbol.notifications, run: view(Engine.View.Notifications) },
        { name: "Media", description: "What's playing", icon: Config.symbol.media, keys: "music player song", run: view(Engine.View.Media) },
        { name: "Mixer", description: "Volume for each app", icon: Config.symbol.mixer, keys: "volume sound audio apps", run: view(Engine.View.Mixer) },
        { name: "Workspaces", description: "Overview of every workspace", icon: Config.symbol.overview, keys: "overview windows", run: view(Engine.View.Workspaces) },
        { name: "Calendar", description: "The month, with today", icon: Config.symbol.calendar, keys: "clock date time", run: view(Engine.View.Clock) },
        { name: "Battery", description: "Charge, time left and health", icon: Config.symbol.battery, keys: "power energy", run: view(Engine.View.Battery) },
        { name: "Theme", description: "Colours and the wallpaper", icon: Config.symbol.theme, keys: "appearance look", run: view(Engine.View.Theme) },
        { name: "Colours", description: "Palettes, an accent, dark or light", icon: Config.symbol.colours, keys: "color palette accent dark light mode", run: view(Engine.View.Colours) },
        { name: "Wallpaper", description: "Pick from every image", icon: Config.symbol.wallpaper, keys: "wallpapers background image", run: view(Engine.View.Wallpapers) },
        { name: "Settings", description: "The island's size, shape and hiding", icon: Config.symbol.settings, keys: "preferences options size notch autohide", run: view(Engine.View.Settings) },
        { name: "Random wallpaper", description: "From ~/Pictures/Wallpapers", icon: "wallpaper", keys: "background", run: () => Wallpaper.random() },
        { name: "Do not disturb", description: Notifier.dnd ? "On: turn it off" : "Off: turn it on", icon: Config.symbol.dnd, keys: "dnd quiet silence", run: quit(() => Notifier.dnd = !Notifier.dnd) },
        { name: "Screenshot", description: "Select an area; saved and copied", icon: Config.symbol.screenshot, keys: "capture grab", run: quit(() => Toggles.screenshot()) },
        { name: Toggles.recording ? "Stop recording the screen" : "Record the screen",
          description: Toggles.recording ? "Recording " + Toggles.recordTime + ": stop and save it" : "The screen you're on, into Videos/Recordings",
          icon: Toggles.recording ? "stop_circle" : "screen_record", keys: "record video capture screencast", run: quit(() => Toggles.record(!Toggles.recording, false)) },
        { name: "Record the screen with the microphone", description: "The screen you're on and your voice", icon: "mic",
          keys: "record video capture screencast audio voice mic", hidden: Toggles.recording, run: quit(() => Toggles.record(true, true)) },
        { name: Toggles.memoRecording ? "Stop the voice memo" : "Voice memo",
          description: Toggles.memoRecording ? "Recording " + Toggles.memoTime + ": stop and save it" : "Record the microphone into Music/Voice memos",
          icon: Toggles.memoRecording ? "stop_circle" : "mic", keys: "record audio voice memo note microphone dictaphone", run: quit(() => Toggles.voiceMemo(!Toggles.memoRecording)) },
        { name: "Clipboard", description: "Everything copied this session", icon: "content_paste", keys: "history paste copied", run: () => { bar.text = ""; root.filter = "clipboard" } },
        { name: "Emoji", description: "Emoji, symbols and kaomoji", icon: "mood", keys: "smiley symbols kaomoji characters", run: () => { bar.text = ""; root.filter = "emoji" } },
        { name: "Agent", description: "Ask the local model; ? before a question does it from here", icon: "smart_toy", keys: "ai assistant llm chat ask ollama", run: view(Engine.View.Agent) },
        { name: "Coding agent", description: "Crush, in a terminal, for work in a repository", icon: "terminal", keys: "ai crush code agent repository", run: quit(() => Toggles.launch([terminal, "-e", agent])) },
        { name: "Lock", description: "Lock the session", icon: "lock", run: quit(() => Session.run("lock")) },
        { name: "Suspend", description: "Sleep", icon: "bedtime", keys: "sleep", run: quit(() => Session.run("suspend")) },
        { name: "Hibernate", description: "Save the session to disk and power off", icon: "ac_unit", keys: "sleep disk", run: quit(() => Session.run("hibernate")) },
        { name: "Power", description: "Log out, restart, shut down", icon: Config.symbol.power, keys: "logout reboot restart shutdown poweroff", run: view(Engine.View.Power) }
    ]
    readonly property var actionRows: {
        const q = query
        return actions
            .filter(a => !a.hidden)
            .filter(a => q === "" || (a.name + " " + (a.keys ?? "")).toLowerCase().split(/\s+/).some(w => w.startsWith(q))
                                  || a.name.toLowerCase().includes(q))
            .map(a => ({ kind: "action", name: a.name, description: a.description, icon: a.icon, run: a.run }))
    }

    // Emoji, symbols and kaomoji (Emoji.qml), in a grid: the Emoji filter, or ":" before the words from
    // any filter, as in a chat. Picked, one is typed into the window you were in, and copied.
    readonly property bool emojiMode: filter === "emoji" || query.startsWith(":")
    readonly property var emojiRows: emojiMode
        ? Emoji.search(query.startsWith(":") ? query.slice(1) : query).map(e => ({ kind: "emoji", glyph: e.glyph, name: e.name, group: e.group }))
        : []

    // The clipboard history (ClipHistory): the Clipboard filter, and the few best in All once there are
    // two letters. Picked, one is pasted into the window you were in (ClipHistory.paste).
    readonly property var clipRows: {
        if (filter !== "clipboard" && !(filter === "all" && query.length >= 2)) return []
        const q = query
        return ClipHistory.items
            .filter(i => q === "" || (i.picture === "" ? i.text.toLowerCase().includes(q) : ("picture image " + i.info).toLowerCase().includes(q)))
            .map(i => ({ kind: "clip", item: i, picture: i.picture, icon: "content_paste",
                         name: i.picture !== "" ? "Picture" : i.text.replace(/\s+/g, " ").trim(),
                         description: i.picture !== "" ? i.info : filter === "all" ? "Copied" : "" }))
    }

    readonly property var calc: {
        const q = bar.text.trim()
        if (!/^[\d\s+\-*/%^().,]+$/.test(q) || !/\d/.test(q) || !/[+\-*/%^]/.test(q)) return null
        try {
            // digits and operators only (checked above), so this can't run anything else
            const v = Function('"use strict"; return (' + q.replace(/\^/g, "**").replace(/,/g, ".") + ")")()
            if (typeof v !== "number" || !isFinite(v)) return null
            const shown = String(Math.round(v * 1e10) / 1e10)
            return { kind: "calc", name: "= " + shown, value: shown, description: "Enter copies it", icon: "calculate" }
        } catch (e) { return null }
    }

    // "?why is the sky blue" asks the agent (views/Conversation.qml), which loads its model while you type.
    onAskChanged: if (ask) Agent.warm()
    readonly property var ask: {
        const q = bar.text.trim()
        if (!q.startsWith("?")) return null
        const prompt = q.slice(1).trim()
        if (prompt === "") return null
        return { kind: "ask", name: "Ask: " + prompt, prompt: prompt, description: "Enter asks the agent", icon: "smart_toy" }
    }

    property var files: []
    property string searched: ""
    property bool pending: false
    readonly property bool wantFiles: (filter === "all" || filter === "files") && query.length >= 2
    onQueryChanged: {
        selected = 0
        files = []
        if (wantFiles) debounce.restart()
    }
    onFilterChanged: {
        selected = 0
        if (filter === "clipboard") ClipHistory.refresh()
        if (wantFiles && searched !== query) debounce.restart()
    }

    Timer {
        id: debounce
        interval: 180
        onTriggered: root.find()
    }
    function find() {
        if (finder.running) { pending = true; return }
        searched = query
        finder.command = ["sh", "-c", "find \"$HOME\" -mindepth 1 -maxdepth 5 \\( -name '.*' -o -name node_modules -o -name target -o -name __pycache__ \\) -prune "
                                   + "-o -iname \"*$1*\" -print 2>/dev/null | head -n 60", "sh", searched]
        finder.running = true
    }
    Process {
        id: finder
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.searched !== root.query) return
                const home = Quickshell.env("HOME")
                const q = root.query
                root.files = text.split("\n").filter(p => p !== "")
                    .map(p => ({ path: p, base: p.split("/").pop() }))
                    .sort((a, b) => (b.base.toLowerCase().startsWith(q) - a.base.toLowerCase().startsWith(q))
                                    || (a.path.split("/").length - b.path.split("/").length) || a.base.localeCompare(b.base))
                    .slice(0, root.maxResults)
                    .map(f => ({ kind: "file", name: f.base, path: f.path, icon: root.fileGlyph(f.base),
                                 description: "~" + f.path.slice(home.length, f.path.length - f.base.length - 1) }))
            }
        }
        onExited: if (root.pending) { root.pending = false; root.find() }
    }
    function fileGlyph(name) {
        const ext = name.includes(".") ? name.split(".").pop().toLowerCase() : ""
        if (ext === "") return "folder"
        if (["png", "jpg", "jpeg", "webp", "gif", "svg", "bmp"].includes(ext)) return "image"
        if (["mp4", "mkv", "webm", "mov", "avi"].includes(ext)) return "movie"
        if (["mp3", "flac", "ogg", "wav", "m4a", "opus"].includes(ext)) return "music_note"
        if (["pdf"].includes(ext)) return "picture_as_pdf"
        if (["zip", "tar", "gz", "xz", "7z", "zst", "rar"].includes(ext)) return "folder_zip"
        if (["nix", "qml", "js", "ts", "py", "rs", "go", "c", "h", "lua", "sh", "json", "toml"].includes(ext)) return "code"
        return "description"
    }

    readonly property var results: {
        if (ask) return [ask]
        if (emojiMode) return emojiRows
        if (filter === "clipboard") return clipRows
        const out = []
        if (calc) out.push(calc)
        if (filter === "all" || filter === "apps") out.push(...apps)
        if (filter === "actions" || (filter === "all" && query !== "")) out.push(...actionRows)
        if (filter === "all" && query.length >= 2) out.push(...clipRows.slice(0, 3))
        if (filter === "all" || filter === "files") out.push(...files)
        return out
    }
    onResultsChanged: selected = Math.min(selected, Math.max(0, results.length - 1))
    onSelectedChanged: emojiMode ? grid.positionViewAtIndex(selected, GridView.Contain) : list.positionViewAtIndex(selected, ListView.Contain)

    // the arrows: a list goes up and down, the grid by rows and, from the field, sideways too
    function step(by) {
        const n = results.length
        if (n === 0) { selected = 0; return }
        if (!emojiMode) { selected = (selected + Math.sign(by) + n) % n; return }
        const next = selected + by
        selected = Math.abs(by) === 1 ? (next + n) % n : Math.max(0, Math.min(n - 1, next))
    }

    readonly property string hint: results.length > 0 ? ""
        : emojiMode && !Emoji.ready ? "The emoji list needs unicode-emoji"
        : filter === "clipboard" && !ClipHistory.enabled ? "The clipboard history needs cliphist and wl-clipboard"
        : filter === "clipboard" && query === "" ? "What you copy shows here, until the session ends"
        : filter === "files" && query.length < 2 ? "Type at least two letters to search your files"
        : finder.running || debounce.running ? "Searching…"
        : query !== "" ? "Nothing matches “" + bar.text.trim() + "”" : "Nothing here"

    function run(row) {
        if (!row) return
        switch (row.kind) {
        case "app":
            count(row.app)
            // in a scope of their own (Toggles.launch), so restarting the shell leaves them open
            if (row.app.runInTerminal)
                Toggles.launch([terminal, "-e"].concat(row.app.command), row.app.workingDirectory)
            else if (Toggles.has("uwsm"))
                Toggles.launch([row.app.id + ".desktop"])
            else
                row.app.execute()
            Engine.close()
            break
        case "file":   Toggles.open(row.path); Engine.close(); break
        case "calc":   Quickshell.clipboardText = row.value; Engine.close(); break
        case "ask":    Agent.ask(row.prompt); Engine.open(Engine.View.Agent); break
        case "action": row.run(); break
        case "clip":   Engine.closeThen(() => ClipHistory.paste(row.item)); break
        case "emoji":
            Emoji.remember(row.glyph)
            Quickshell.clipboardText = row.glyph
            Engine.closeThen(() => Toggles.typeText(row.glyph))
            break
        }
    }
    function cycle(step) {
        const i = filters.findIndex(f => f.key === filter)
        filter = filters[(i + step + filters.length) % filters.length].key
    }

    implicitWidth: 880
    implicitHeight: 20 + bar.height + 12 + (results.length === 0 ? 56 : emojiMode ? grid.height + 44 : list.height) + 18

    BackButton {
        id: back
        x: 20
        anchors.verticalCenter: bar.verticalCenter
        onClicked: Engine.back()
    }

    SearchBar {
        id: bar
        x: back.x + back.width + 8; y: 20
        width: parent.width - x - 20
        implicitHeight: 60
        fieldSize: 18
        placeholder: "Search, or ? to ask"
        takesTab: true
        takesArrows: true
        takesSides: root.emojiMode
        focus: true

        onKey: Engine.key()
        onDown: root.step(root.emojiMode ? grid.columns : 1)
        onUp: root.step(root.emojiMode ? -grid.columns : -1)
        onSideways: step => root.step(step)
        onAccepted: root.run(root.results[root.selected])
        onTab: backward => root.cycle(backward ? -1 : 1)
        onEscaped: Engine.close()
        onBackspaceEmpty: Engine.back()

        Repeater {
            model: root.filters

            Chip {
                required property var modelData
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                selected: root.filter === modelData.key
                activeFocusOnTab: false
                onClicked: root.filter = modelData.key
            }
        }
    }

    Label {
        visible: root.hint !== ""
        x: 36
        y: bar.y + bar.height + 28
        text: root.hint
        color: Config.dim
    }

    GridView {
        id: grid
        readonly property int columns: 12
        readonly property var current: root.emojiMode ? root.results[root.selected] ?? null : null

        visible: root.emojiMode && root.results.length > 0
        x: 20
        y: bar.y + bar.height + 12
        width: parent.width - 40
        cellWidth: width / columns
        cellHeight: cellWidth
        height: Math.min(Math.ceil(root.results.length / columns), 5) * cellHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.emojiMode ? root.results : []

        delegate: Item {
            id: cell
            required property var modelData
            required property int index
            readonly property bool current: index === root.selected

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors { fill: parent; margins: Config.spaceXs }
                radius: Config.innerRadius
                color: cell.current ? Config.secondary : cellArea.containsMouse ? Config.high : "transparent"
                Behavior on color { ColorAnimation { duration: Config.durationFast } }
            }
            // a kaomoji is long: it shrinks to its cell, and the line below shows it whole
            Text {
                anchors.centerIn: parent
                width: parent.width - 10
                horizontalAlignment: Text.AlignHCenter
                text: cell.modelData.glyph
                color: cell.current ? Config.secondaryInk : Config.text
                font.pixelSize: 30
                fontSizeMode: Text.HorizontalFit
                minimumPixelSize: 8
            }
            ClickArea {
                id: cellArea
                property point last: Qt.point(-1, -1)
                onPositionChanged: mouse => {
                    const p = mapToGlobal(mouse.x, mouse.y)
                    if (Math.abs(p.x - last.x) > 0.5 || Math.abs(p.y - last.y) > 0.5) {
                        if (last.x >= 0) root.selected = cell.index
                        last = p
                    }
                }
                onClicked: root.run(cell.modelData)
            }
        }
    }

    // the one chosen, whole and by name, and what Enter does with it
    Row {
        visible: grid.visible && grid.current !== null
        x: 32
        y: grid.y + grid.height + 10
        spacing: Config.spaceM

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: grid.current?.glyph ?? ""
            color: Config.text
            font.pixelSize: 22
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: (grid.current?.name ?? "") + "  ·  " + (grid.current?.group ?? "") + "  ·  Enter types it, and copies it"
            color: Config.dim
        }
    }

    ListView {
        id: list
        visible: !root.emojiMode
        x: 20
        y: bar.y + bar.height + 12
        width: parent.width - 40
        height: Math.min(root.results.length, root.maxRows) * (root.rowH + spacing)
        spacing: Config.spaceHair
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.emojiMode ? [] : root.results

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool current: index === root.selected

            width: list.width
            height: root.rowH
            radius: Config.innerRadius
            color: current ? Config.secondary : "transparent"
            Behavior on color { ColorAnimation { duration: Config.durationFast } }

            Item {
                id: lead
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 44
                height: 44

                // "" when the theme has no such icon: then the glyph circle shows instead
                readonly property string appIcon: row.modelData.kind === "app" ? Quickshell.iconPath(row.modelData.app.icon ?? "", true) : ""

                // a picture from the clipboard shows itself
                ClippingRectangle {
                    visible: (row.modelData.picture ?? "") !== ""
                    anchors.fill: parent
                    radius: 22
                    color: Config.high

                    CoverImage {
                        source: row.modelData.picture ?? ""
                        sourceSize: Qt.size(88, 88)
                    }
                }
                IconImage {
                    visible: lead.appIcon !== ""
                    anchors.centerIn: parent
                    implicitSize: 40
                    asynchronous: true
                    source: lead.appIcon
                }
                Rectangle {
                    visible: lead.appIcon === "" && (row.modelData.picture ?? "") === ""
                    anchors.fill: parent
                    radius: 22
                    color: row.current ? Config.primary : Config.high

                    Icon {
                        anchors.centerIn: parent
                        name: row.modelData.icon ?? "apps"
                        size: 20
                        color: row.current ? Config.primaryInk : Config.text
                    }
                }
            }

            Column {
                anchors { left: lead.right; leftMargin: Config.spaceL; right: parent.right; rightMargin: Config.spaceL; verticalCenter: parent.verticalCenter }
                spacing: Config.spaceHair

                Label {
                    width: parent.width
                    text: row.modelData.name
                    elide: Text.ElideRight
                    color: row.current ? Config.secondaryInk : Config.text
                    font.pixelSize: Config.body + 2
                    font.weight: Font.Medium
                }
                Label {
                    width: parent.width
                    visible: text !== ""
                    text: row.modelData.description ?? ""
                    elide: Text.ElideRight
                    color: row.current ? Config.mix(Config.secondaryInk, Config.secondary, 0.25) : Config.dim
                    font.pixelSize: Config.small + 1
                }
            }

            ClickArea {
                property point last: Qt.point(-1, -1)
                // only a real move takes the selection: a pointer resting where a row appears
                // under it must not fight the keyboard
                onPositionChanged: mouse => {
                    const p = mapToGlobal(mouse.x, mouse.y)
                    if (Math.abs(p.x - last.x) > 0.5 || Math.abs(p.y - last.y) > 0.5) {
                        if (last.x >= 0) root.selected = row.index
                        last = p
                    }
                }
                onClicked: root.run(row.modelData)
            }
        }
    }
}
