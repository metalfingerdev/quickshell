pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The conversation with the local model, run by Nihil-Shell's agent: `nilo-agent` (nixos-dotfiles,
// features/nilo-agent), spoken to in JSON lines. The model may search the web (SearXNG) and read pages,
// look up this computer and open apps, in as many rounds as it needs; what goes out after it has read
// this computer waits for a yes (`asking`). At its Terminal level it reads and edits files, uses git and
// runs commands in one repository, and at System it also drives windows, the screen and the quick
// controls: each change, command and desktop action asks first, and `access` says which level it has.
// The agent keeps the conversation while the shell runs, never on disk, and the switches (model,
// Internet, Think). views/Conversation.qml shows it; Triggers peeks the answer when it ends with the view closed.
Singleton {
    id: root

    // { role: "user" | "assistant", content, thinking, thought (seconds of it), open (the thinking shown),
    // steps (JSON: its tools, { id, name, arg, status: running | done | failed | declined, and the agent's
    // facts }), sources (JSON: the pages it read), by (the model), streaming, error }.
    // Not "model": a delegate has its own `model`, which would hide it.
    readonly property ListModel messages: ListModel {}
    property bool busy: false
    property string phase: ""     // loading, thinking, answering, searching, reading, looking, opening, asking, stopping
    readonly property bool toolAtWork: Object.values(phases).includes(phase)
    property string detail: ""    // what the tool at work was given: the query, the page, the app
    property var asking: null     // the agent's confirm: { id, what, why: [...], text | path }
    property string lastQuestion: ""
    property string lastAnswer: ""
    property bool fresh: false        // an answer not yet seen in the conversation (Expanded shows it)
    signal answered(string question, string answer, bool ok)

    // the agent's settings, as it last said them: change them with set()
    // what the agent says it can do (hello). An older agent lists none, so the buttons for these stay hidden.
    property var features: []
    function has(feature) { return features.includes(feature) }
    // Nilo's notes (~/.config/nihil/nilo.md) go to the model on every question, out of its small window
    function openNotes() { if (has("notes")) send({ op: "notes" }) }

    property string model: ""
    property bool web: false
    property bool think: false
    property string access: "chat"      // chat, terminal or system: what the agent may do, set in the conversation
    property string repo: ""            // where terminal-level work happens
    property var repos: []              // the repositories it found in the home folder, newest first
    property bool confirmAll: false     // an edit asks no more for the rest of this answer: the next answer asks again
    function loadRepos() { if (has("repos")) send({ op: "repos" }) }
    signal aside()                      // the agent is about to use the screen: the island gets out of the way

    // Ollama's installed models, whether it answers, and what is in memory
    property var models: []
    property bool reachable: true
    property bool loaded: false
    property bool warming: false
    readonly property string inUse: models.includes(model) ? model : (models[0] ?? "")

    readonly property string activity: ({
        loading: "Loading " + inUse, thinking: "Thinking", answering: "Answering",
        searching: "Searching the web" + (detail !== "" ? ": " + detail : ""), reading: "Reading " + detail,
        looking: "Looking at this computer", opening: "Opening " + detail, asking: "Waiting for your answer",
        files: "Working on files" + (detail !== "" ? ": " + detail : ""), running: "Running " + detail,
        git: "Using git", desktop: "Using the desktop" + (detail !== "" ? ": " + detail : ""),
        stopping: "Stopping"
    })[phase] ?? "Working"

    function set(key, value) { send({ op: "set", key: key, value: value }) }
    function refresh() { send({ op: "status" }) }
    // Loads the model before the question comes: on a 4 GB GPU that is the seconds the first answer would
    // otherwise wait. `warming` comes from the agent alone, so a load it turns down leaves nothing stuck.
    function warm() {
        if (!loaded && !warming && !busy && inUse !== "") send({ op: "warm" })
    }

    function ask(text) {
        const q = text.trim()
        if (q === "" || busy) return
        if (!ready || inUse === "") { refresh(); return }
        lastQuestion = q
        const blank = { content: "", thinking: "", thought: 0, open: false, steps: "[]", sources: "[]", error: "" }
        messages.append(Object.assign({}, blank, { role: "user", content: q, by: "", streaming: false }))
        messages.append(Object.assign({}, blank, { role: "assistant", by: inUse, streaming: true }))
        busy = true
        phase = loaded ? "thinking" : "loading"
        failure = ""
        thinkFrom = 0
        thoughtMs = 0
        send({ op: "ask", text: q })
        Activities.start("agent", "Agent", true)
    }
    // The answer ends when the agent says done (cancelled), so a question asked right after finds it free.
    function stop() {
        if (!busy) return
        phase = "stopping"
        send({ op: "stop" })
    }
    function reset() {
        stop()
        send({ op: "reset" })
        confirmAll = false
        messages.clear()
        lastQuestion = ""
        lastAnswer = ""
        fresh = false
    }
    // a confirm in words, for the conversation's card and Expanded
    function describe(a) {
        if (!a) return ""
        const why = (a.why ?? []).map(w => ({ private: "this chat has read details of this computer",
            sensitive: "it looks like a password, a key or a card number", runs: "it runs a program",
            web: "this answer has read the web", outside: "this answer has read from outside" })[w]).filter(w => w)
        const because = why.length > 0 ? " Asked because " + why.join(", and ") + "." : ""
        const text = a.text ?? a.path ?? ""
        switch (a.action) {
        case "edit": return "Change " + a.path + " (+" + a.added + " −" + a.removed + ")?"
        case "create": return "Create " + a.path + " (" + a.added + " lines)?"
        case "run": return "Run in " + a.cwd + (a.reason ? " (" + a.reason + ")" : "") + ": " + a.command + (a.danger?.length > 0 ? "  — risky" : "") + "?"
        case "terminal": return "Run in a terminal, in " + a.cwd + ": " + a.command + "?"
        case "commit": case "commit-push": case "push":
            return (a.action === "push" ? "Push " : "Commit" + (a.action === "commit-push" ? " and push " : " ")) + (a.files?.length ?? 0)
                + " changed file(s) in " + a.repo + (a.message ? ": “" + a.message + "”" : "") + "?"
        case "desktop": {
            const where = a.app ? " in " + a.app + (a.title ? " (" + a.title + ")" : "") : ""
            const what = ({ search: "Search the web for", fetch: "Read", open: "Open", launch: "Open", read: "Read",
                            click: "Click", type: "Type “" + (a.text ?? "") + "”", keys: "Press " + (a.keys ?? ""),
                            send: "Send to your phone" })[a.what] ?? "Allow"
            return what + (["search", "fetch", "open", "launch", "read"].includes(a.what) ? " “" + text + "”" : where) + "?" + because
        }
        }
        return "Allow " + (a.action ?? "this") + "?" + because
    }
    function answer(ok) {
        if (asking) send({ op: "confirm", id: asking.id, ok: ok })
    }

    // Tokens come ~50 a second, and each write re-lays the whole Markdown answer and rebuilds its scene
    // graph nodes: that churn crashed Qt 6.12's renderer mid-answer (QSGBatchRenderer::Element::
    // computeBounds). So they're held, and written at most every 80 ms.
    property string heldThinking: ""
    property string heldContent: ""
    function flush() {
        const last = messages.count - 1
        if (last >= 0 && heldThinking !== "") {
            messages.setProperty(last, "thinking", messages.get(last).thinking + heldThinking)
            messages.setProperty(last, "thought", Math.round((thoughtMs + (thinkFrom > 0 ? Date.now() - thinkFrom : 0)) / 1000))
        }
        if (last >= 0 && heldContent !== "") messages.setProperty(last, "content", messages.get(last).content + heldContent)
        heldThinking = ""
        heldContent = ""
    }
    Timer { id: flusher; interval: 80; onTriggered: root.flush() }

    // How long it thought: each stretch of thinking (one a round), without the tools and the words between.
    property real thinkFrom: 0
    property real thoughtMs: 0
    function thinkingEnds() {
        if (thinkFrom === 0) return
        flush()
        thoughtMs += Date.now() - thinkFrom
        thinkFrom = 0
        if (messages.count > 0) messages.setProperty(messages.count - 1, "thought", Math.round(thoughtMs / 1000))
    }
    function step(id, changes) {
        const last = messages.count - 1
        if (last < 0) return
        const steps = JSON.parse(messages.get(last).steps)
        const i = steps.findIndex(s => s.id === id)
        if (i >= 0) Object.assign(steps[i], changes)
        else steps.push(Object.assign({ id: id }, changes))
        messages.setProperty(last, "steps", JSON.stringify(steps))
    }

    property string failure: ""     // the agent's error, said before its done
    property bool afterTool: false  // the next words start a new paragraph
    readonly property var phases: ({ web_search: "searching", open_url: "reading", system_info: "looking", open_app: "opening",
        git_status: "git", git_commit: "git", list_files: "files", read_file: "files", edit_file: "files", write_file: "files",
        run_command: "running", list_windows: "desktop", look_at_screen: "desktop", click: "desktop", use_window: "desktop",
        type_text: "desktop", press_keys: "desktop", media: "desktop", control: "desktop", send_to_phone: "desktop" })

    function handle(line) {
        let e
        try { e = JSON.parse(line) } catch (err) { return }
        const last = messages.count - 1
        switch (e.ev) {
        case "hello":
            restarts = 0
            trouble = ""
            features = Array.isArray(e.features) ? e.features.filter(f => typeof f === "string") : []
            settings(e.settings)
            catalogue(e)
            break
        case "notes":
            // the file is the person's: it only opens, in their editor, and is never written from here
            if (typeof e.path === "string" && e.path !== "") Toggles.open(e.path)
            break
        case "settings": settings(e.settings); break
        case "models": catalogue(e); break
        case "repos": repos = Array.isArray(e.repos) ? e.repos.filter(r => typeof r === "string") : []; break
        case "output": {
            // a running command's last lines, live in its step
            const text = Array.isArray(e.lines) ? e.lines.join("\n") : ""
            if (last >= 0) step(e.id, { tail: text })
            break
        }
        case "state":
            if (e.ollama === true || e.ollama === false) reachable = e.ollama
            loaded = e.loaded
            warming = e.loading
            break
        case "thinking":
            if (phase !== "stopping") phase = "thinking"
            if (thinkFrom === 0) {
                thinkFrom = Date.now()
                if (last >= 0 && messages.get(last).thinking + heldThinking !== "") heldThinking += "\n\n"
            }
            heldThinking += e.text
            flusher.start()
            break
        case "token":
            thinkingEnds()
            if (afterTool && last >= 0 && messages.get(last).content + heldContent !== "") heldContent += "\n\n"
            afterTool = false
            if (phase !== "stopping") phase = "answering"
            heldContent += e.text
            flusher.start()
            break
        case "tool":
            if (e.status === "running") {
                thinkingEnds()
                flush()
                phase = phases[e.name] ?? "thinking"
                detail = String(e.args?.query ?? e.args?.url ?? e.args?.target ?? e.args?.path ?? e.args?.command ?? e.args?.window
                                ?? e.args?.setting ?? e.args?.action ?? "")
                step(e.id, { name: e.name, arg: detail, status: "running" })
            } else {
                // a no leaves the result without an error: that's how a declined search or page reads
                step(e.id, Object.assign({}, e, { status: e.ok ? "done" : e.error ? "failed" : "declined", ev: undefined }))
                if (e.name === "open_url" && e.ok && last >= 0)
                    messages.setProperty(last, "sources", JSON.stringify(JSON.parse(messages.get(last).sources).concat([{ url: detail }])))
                afterTool = true
                detail = ""
                if (phase !== "stopping") phase = "thinking"
            }
            break
        case "confirm":
            thinkingEnds()
            flush()
            // only a change to a file may be let through for the rest of the answer: commands, commits and
            // the desktop always ask
            if (confirmAll && (e.action === "edit" || e.action === "create")) { send({ op: "confirm", id: e.id, ok: true }); break }
            asking = e
            phase = "asking"
            break
        case "confirmed":
            asking = null
            if (phase === "asking") phase = "thinking"
            break
        case "launch":
            send(Object.assign({ op: "launched", id: e.id }, launch(String(e.target), e.kind)))
            break
        case "aside":
            // the island goes first, so a screenshot or a click lands on the app and not on it
            aside()
            asideIds.push(e.id)
            asideLater.restart()
            break
        case "control": {
            const done = control(String(e.setting ?? ""), String(e.value ?? ""))
            send(Object.assign({ op: "answer", id: e.id }, done))
            break
        }
        case "vector":
            // no phone link in this island
            send({ op: "answer", id: e.id, ok: false, error: "off" })
            break
        case "error":
            if (e.code === "ollama-down") reachable = false
            if (busy) failure = e.code === "ollama-down" ? "Ollama isn't answering at 127.0.0.1:11434 (systemctl status ollama)"
                                                         : String(e.detail || e.code)
            else console.log("nilo-agent: " + e.code + " " + (e.detail ?? ""))
            break
        case "done":
            confirmAll = false
            if (busy) finish(!e.failed && !e.cancelled, e.cancelled ? "Stopped" : failure)
            break
        }
    }
    function settings(s) {
        model = s.model ?? ""
        web = s.web === true
        think = s.think === true
        access = ["chat", "terminal", "system"].includes(s.access) ? s.access : "chat"
        repo = s.repo ?? ""
    }
    function catalogue(e) {
        models = (e.models ?? []).filter(m => m.installed).map(m => m.tag)
        if (e.ollama === true || e.ollama === false) reachable = e.ollama
    }

    // open_app, answered as the launcher would: an app by its name (uwsm scope, as Launcher does), a page
    // or a file in what opens it. Not found, it hands back the names closest to it.
    function launch(target, kind) {
        if (kind !== "app") { Toggles.open(target); return { ok: true, name: target } }
        const q = target.toLowerCase()
        const all = Array.from(DesktopEntries.applications.values).filter(a => !a.noDisplay)
        const app = all.find(a => a.name.toLowerCase() === q) ?? all.find(a => a.name.toLowerCase().startsWith(q))
        if (!app) return { ok: false, similar: all.filter(a => a.name.toLowerCase().includes(q)).slice(0, 5).map(a => a.name) }
        if (Toggles.has("uwsm")) Toggles.launch([app.id + ".desktop"])
        else app.execute()
        return { ok: true, name: app.name }
    }

    property var asideIds: []
    Timer {
        id: asideLater
        interval: 350       // the drawer's close, so the screen is the app's by the time it looks
        onTriggered: { for (const id of root.asideIds.splice(0)) root.send({ op: "answer", id: id, ok: true }) }
    }

    // The agent's quick controls, on this island's own services. What it has no control for answers so,
    // and the agent tells the model.
    function control(setting, value) {
        const v = value.trim().toLowerCase()
        const flag = (now) => v === "on" ? true : v === "off" ? false : v === "toggle" || v === "" ? !now : null
        const amount = (now) => {
            const m = v.match(/^([+-]?)(\d+)$/)
            if (!m) return NaN
            return m[1] === "" ? Number(m[2]) : now + (m[1] === "-" ? -1 : 1) * Number(m[2])
        }
        const level = (now, set, name) => {
            const n = amount(now)
            if (isNaN(n)) return { ok: false, error: name + " takes 0 to 100, or a step like +10" }
            const to = Math.max(0, Math.min(100, n))
            set(to)
            return { ok: true, value: String(to) }
        }
        const sw = (now, set) => {
            const on = flag(now)
            if (on === null) return { ok: false, error: setting + " takes on, off or toggle" }
            set(on)
            return { ok: true, value: on ? "on" : "off" }
        }
        switch (setting) {
        case "volume": return level(Audio.volume, p => Audio.setVolume(p), "volume")
        case "brightness":
            if (!Backlight.available) return { ok: false, error: "this screen has no brightness control" }
            return level(Backlight.percent, p => Backlight.set(p), "brightness")
        case "mute": return sw(Audio.muted, on => { if (on !== Audio.muted) Audio.toggleMuted(Audio.sink) })
        case "mic": return sw(!Audio.micMuted, on => { if (on === Audio.micMuted) Audio.toggleMic() })
        case "dnd": return sw(Notifier.dnd, on => Notifier.dnd = on)
        case "caffeine": return sw(Toggles.caffeine, on => Toggles.caffeine = on)
        case "night":
            return sw(Toggles.nightLight, on => Toggles.nightLight = on)
        case "glass": return sw(Glass.enabled, on => Glass.enabled = on)
        case "wifi":
            if (flag(Net.wifiEnabled) === null) return { ok: false, error: "joining a network by name isn't offered here: wifi takes on, off or toggle" }
            return sw(Net.wifiEnabled, on => Net.setWifi(on))
        case "bluetooth":
            if (!Bluez.available) return { ok: false, error: "there is no Bluetooth adapter" }
            if (flag(Bluez.enabled) === null) return { ok: false, error: "connecting a device by name isn't offered here: bluetooth takes on, off or toggle" }
            return sw(Bluez.enabled, on => Bluez.setEnabled(on))
        case "wallpaper":
            if (v === "next" || v === "") Wallpaper.step(1)
            else if (v === "prev" || v === "previous") Wallpaper.step(-1)
            else return { ok: false, error: "wallpaper takes next or prev" }
            return { ok: true, value: v || "next" }
        case "screenshot": Toggles.screenshot(); return { ok: true, value: "region" }
        case "record": return sw(Toggles.recording, on => { if (on !== Toggles.recording) Toggles.record(on, false) })
        case "lock": Session.run("lock"); return { ok: true, value: "locked" }
        }
        return { ok: false, error: "this island has no control called " + setting }
    }

    function finish(ok, error) {
        thinkingEnds()
        flush()
        const last = messages.count - 1
        if (last >= 0) {
            messages.setProperty(last, "streaming", false)
            if (!ok && error !== "") messages.setProperty(last, "error", error)
        }
        busy = false
        phase = ""
        detail = ""
        asking = null
        afterTool = false
        Activities.finish("agent", "quiet")
        lastAnswer = last >= 0 ? messages.get(last).content : ""
        fresh = ok && lastAnswer !== ""
        answered(lastQuestion, lastAnswer, ok)
    }

    // The agent runs as long as the shell does (idle, it asks Ollama what is loaded once a minute).
    // If it stops it comes back, five times in a row at most.
    property bool ready: false
    property var queue: []
    property int restarts: 0
    property string trouble: ""
    function send(request) {
        if (ready) agent.write(JSON.stringify(request) + "\n")
        else queue.push(request)
    }
    Process {
        id: agent
        running: Toggles.has("nilo-agent")
        command: ["nilo-agent"]
        stdinEnabled: true
        stdout: SplitParser { onRead: line => root.handle(line) }
        stderr: SplitParser { onRead: line => console.log("nilo-agent: " + line) }
        onStarted: {
            root.ready = true
            agent.write(JSON.stringify({ op: "hello" }) + "\n")
            for (const request of root.queue.splice(0)) agent.write(JSON.stringify(request) + "\n")
        }
        onRunningChanged: {
            if (running) return
            root.ready = false
            if (root.busy) root.finish(false, "The agent stopped (journalctl --user -u quickshell)")
            if (++root.restarts <= 5) comeBack.start()
            else root.trouble = "The agent keeps stopping: journalctl --user -u quickshell"
        }
    }
    Timer { id: comeBack; interval: 1000; onTriggered: agent.running = true }

    IpcHandler {
        target: "agent"

        function ask(text: string): void { root.ask(text) }
        function stop(): void            { root.stop() }
        function reset(): void           { root.reset() }
        function last(): string          { return root.messages.count > 0 ? root.messages.get(root.messages.count - 1).content : "" }
    }
}
