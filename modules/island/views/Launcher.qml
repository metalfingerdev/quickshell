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
    // Each filter has a sign: typed first in the field it switches there (as "?" asks the agent), so a filter
    // is a keystroke away, as in Walker, Raycast or Ulauncher; the row under the field shows the signs.
    readonly property var filters: [
        { key: "all",     label: "All" },
        { key: "apps",    label: "Apps" },
        { key: "files",   label: "Files  /", sign: "/" },
        { key: "actions", label: "Actions  >", sign: ">" },
        { key: "clipboard", label: "Clipboard  @", sign: "@" },
        { key: "emoji",   label: "Emoji  :", sign: ":" }
    ]
    // Taken once, not bound: the IPC `launch <filter>` (Super+., Super+Ctrl+D...) sets Engine.launcherFilter
    // before the view loads, and asks again through launcherAsked when it is already open.
    property string filter: "all"
    Component.onCompleted: { filter = Engine.launcherFilter; Engine.launcherFilter = "all"; ClipHistory.refresh() }
    Connections {
        target: Engine
        function onLauncherAsked(f) { root.filter = f; Engine.launcherFilter = "all" }
    }
    Connections {
        target: bar
        function onTextChanged() {
            const f = root.filters.find(x => x.sign && x.sign === bar.text[0])
            if (f) { root.filter = f.key; bar.text = bar.text.slice(1) }
        }
    }
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
    // With nothing typed the pinned ones come first, in their order (Ctrl+P pins the selected app)
    readonly property var apps: {
        const q = query
        const pinned = q === "" ? Pins.apps : []
        const all = Array.from(DesktopEntries.applications.values).filter(a => !a.noDisplay && !pinned.includes(a))
        const ranked = q === ""
            ? all.map(a => ({ app: a, score: used(a) > 0 ? 1 : 0 }))
            : all.map(a => ({ app: a, score: score(a, q) })).filter(m => m.score > 0)
        return pinned.concat(ranked
            .sort((a, b) => (b.score - a.score) || (used(b.app) - used(a.app)) || (a.app.name.length - b.app.name.length)
                            || a.app.name.localeCompare(b.app.name))
            .map(m => m.app))
            .slice(0, maxResults)
            .map(a => ({ kind: "app", app: a, name: a.name, description: a.comment || a.genericName || "" }))
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
        { name: "Tasks", description: Tasks.open > 0 ? Tasks.open + " not done" : "To do, doing, done", icon: "checklist", keys: "todo kanban board", run: view(Engine.View.Tasks) },
        { name: "Favourites", description: "Pinned apps; Ctrl+P on one here pins it", icon: "keep", keys: "dock pinned apps favorites", run: view(Engine.View.Dock) },
        { name: "NixOS", description: "Generations, and the flake's updates", icon: "history", keys: "generations updates rebuild flake nix", run: view(Engine.View.Generations) },
        { name: "Tray", description: "Apps' tray icons and their menus", icon: "widgets", keys: "systray status icons", run: view(Engine.View.Tray) },
        { name: "Calendar", description: "The month, with today", icon: Config.symbol.calendar, keys: "clock date time", run: view(Engine.View.Clock) },
        { name: "Battery", description: "Charge, time left and health", icon: Config.symbol.battery, keys: "power energy", run: view(Engine.View.Battery) },
        { name: "Theme", description: "Colours and the wallpaper", icon: Config.symbol.theme, keys: "appearance look", run: view(Engine.View.Theme) },
        { name: "Colours", description: "Palettes, an accent, dark or light", icon: Config.symbol.colours, keys: "color palette accent dark light mode", run: view(Engine.View.Colours) },
        { name: "Wallpaper", description: "Pick from every image", icon: Config.symbol.wallpaper, keys: "wallpapers background image", run: view(Engine.View.Wallpapers) },
        { name: "Settings", description: "The island's size, shape and hiding", icon: Config.symbol.settings, keys: "preferences options size notch autohide", run: view(Engine.View.Settings) },
        { name: "Random wallpaper", description: "From your wallpaper folders", icon: "wallpaper", keys: "background", run: () => Wallpaper.random() },
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
        { hidden: !Toggles.has("nilo-agent"), name: "Agent", description: "Ask the local model; ? before a question does it from here", icon: "smart_toy", keys: "ai assistant llm chat ask ollama", run: view(Engine.View.Agent) },
        { hidden: !Toggles.has("crush"), name: "Coding agent", description: "Crush, in a terminal, for work in a repository", icon: "terminal", keys: "ai crush code agent repository", run: quit(() => Toggles.launch([terminal, "-e", agent])) },
        { name: "Lock", description: "Lock the session", icon: "lock", run: quit(() => Session.run("lock")) },
        { name: "Suspend", description: "Sleep", icon: "bedtime", keys: "sleep", run: quit(() => Session.run("suspend")) },
        { hidden: !Session.canHibernate, name: "Hibernate", description: "Save the session to disk and power off", icon: "ac_unit", keys: "sleep disk", run: quit(() => Session.run("hibernate")) },
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

    // The calculator: a sum typed anywhere shows its answer first; "=" before it is the calculator alone, and
    // there Math's functions and constants work by name too (sqrt, sin, log, ln, pi, e...). Only these names,
    // digits and operators get through, so nothing else can run.
    readonly property var mathNames: ({ sqrt: "Math.sqrt", cbrt: "Math.cbrt", abs: "Math.abs", round: "Math.round",
        floor: "Math.floor", ceil: "Math.ceil", sin: "Math.sin", cos: "Math.cos", tan: "Math.tan", asin: "Math.asin",
        acos: "Math.acos", atan: "Math.atan", ln: "Math.log", log: "Math.log10", log2: "Math.log2", exp: "Math.exp",
        pow: "Math.pow", min: "Math.min", max: "Math.max", hypot: "Math.hypot", pi: "Math.PI", e: "Math.E", tau: "(2*Math.PI)" })
    readonly property bool calcMode: bar.text.trim().startsWith("=")
    readonly property var calc: {
        const q = calcMode ? bar.text.trim().slice(1).trim() : bar.text.trim()
        if (q === "" || !/^[\d\s+\-*/%^().,a-z]+$/i.test(q)) return null
        const named = /[a-z]/i.test(q)
        if (!calcMode && (named || !/\d/.test(q) || !/[+\-*/%^]/.test(q))) return null
        let unknown = false
        // a letter after a digit is an exponent (1e3), not a name
        const js = q.replace(/\^/g, "**").replace(/[a-z][a-z0-9]*/gi, (w, at, s) =>
            /[\d.]/.test(s[at - 1] ?? "") && /^e\d*$/i.test(w) ? w : (mathNames[w.toLowerCase()] ?? (unknown = true, w)))
        if (unknown) return null
        try {
            const v = Function('"use strict"; return (' + (named ? js : js.replace(/,/g, ".")) + ")")()
            if (typeof v !== "number" || !isFinite(v)) return null
            const shown = String(Math.round(v * 1e10) / 1e10)
            return { kind: "calc", name: "= " + shown, value: shown, description: q + "  ·  Enter copies it", icon: "calculate" }
        } catch (e) { return null }
    }

    // "!" before a command runs it in the terminal, which stays open to show what it said
    readonly property var runRow: {
        const q = bar.text.trim()
        if (!q.startsWith("!") || q.slice(1).trim() === "") return null
        const cmd = q.slice(1).trim()
        return { kind: "run", name: "Run: " + cmd, command: cmd, description: "In " + terminal + ", which stays open", icon: "terminal" }
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
        if (runRow) return [runRow]
        if (calcMode) return calc ? [calc] : []
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
        : calcMode ? "A sum, or sqrt, sin, cos, log, ln, pow, min, max, pi, e…"
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
            Pins.run(row.app)
            Engine.close()
            break
        case "file":   Toggles.open(row.path); Engine.close(); break
        case "calc":   Quickshell.clipboardText = row.value; Engine.close(); break
        case "run":    Engine.close(); Toggles.launch([root.terminal, "--hold", "sh", "-c", row.command]); break
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
    readonly property real listTop: modes.y + modes.height + 12
    implicitHeight: listTop + (results.length === 0 ? 56 : emojiMode ? grid.height + 44 : list.height) + 18 + (hints.visible ? hints.implicitHeight + Config.spaceXs : 0)

    BackButton {
        id: back
        x: 20
        anchors.verticalCenter: bar.verticalCenter
        onClicked: Engine.back()
    }

    // under the results, while the keyboard is in use (the field is where you type, so these are all there is)
    KeyHints {
        id: hints
        x: 36; y: root.implicitHeight - hints.implicitHeight - Config.spaceXs
        width: parent.width - 72
        keys: [["↑ ↓", "choose"], ["↵", "open"], ["Tab", "filter"], ["Ctrl P", "pin"], ["Esc", "close"]]
    }

    SearchBar {
        id: bar
        x: back.x + back.width + 8; y: 20
        width: parent.width - x - 20
        implicitHeight: 60
        fieldSize: 18
        placeholder: "Search  ·  ? ask  ·  = calculate  ·  ! run"
        takesTab: true
        takesArrows: true
        takesSides: root.emojiMode
        focus: true
        controlKeys: [Qt.Key_P]
        onControl: key => {
            const row = root.results[root.selected]
            if (row?.kind === "app") { Engine.key(); Pins.toggle(row.app) }
        }

        onKey: Engine.key()
        onDown: root.step(root.emojiMode ? grid.columns : 1)
        onUp: root.step(root.emojiMode ? -grid.columns : -1)
        onSideways: step => root.step(step)
        onAccepted: root.run(root.results[root.selected])
        onTab: backward => root.cycle(backward ? -1 : 1)
        onEscaped: Engine.close()
        // Backspace on an empty field leaves the filter first, then the launcher
        onBackspaceEmpty: root.filter !== "all" ? root.filter = "all" : Engine.back()
    }

    // the filters, with their signs, as the Control Centre's connected group; the field keeps the keyboard
    Segmented {
        id: modes
        x: bar.x; y: bar.y + bar.height + 10
        width: bar.width
        height: 36
        options: root.filters
        current: root.filter
        onPicked: key => { root.filter = key; bar.forceActiveFocus() }
    }

    // the results, the hint and the emoji's name, all on one card under the filters: the rows are clear
    // until chosen, and the glass behind them may be too
    Rectangle {
        x: 12
        y: root.listTop - Config.spaceXs
        width: parent.width - 24
        height: (root.results.length === 0 ? 56 : root.emojiMode ? grid.height + 44 : list.height) + Config.spaceS
        radius: Config.cardRadius
        color: Config.tile
    }

    Label {
        visible: root.hint !== ""
        x: 36
        y: root.listTop + 16
        text: root.hint
        color: Config.dim
    }

    GridView {
        id: grid
        readonly property int columns: 12
        readonly property var current: root.emojiMode ? root.results[root.selected] ?? null : null

        visible: root.emojiMode && root.results.length > 0
        x: 20
        y: root.listTop
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
                color: cell.current ? Config.secondary : cellArea.containsMouse ? Config.raised : "transparent"
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
        y: root.listTop
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
                    color: Config.raised

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
                    color: row.current ? Config.primary : Config.raised

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

            Icon {
                visible: row.modelData.kind === "app" && Pins.has(row.modelData.app)
                anchors { right: parent.right; rightMargin: Config.spaceL; verticalCenter: parent.verticalCenter }
                name: "keep"
                size: 18
                color: row.current ? Config.secondaryInk : Config.dim
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
