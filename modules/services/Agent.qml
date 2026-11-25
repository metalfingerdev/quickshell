pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The conversation with the local model, run by Nihil-Shell's agent: `nilo-agent` (nixos-dotfiles,
// features/nilo-agent), spoken to in JSON lines. The model may search the web (SearXNG) and read pages,
// look up this computer and open apps, in as many rounds as it needs; what goes out after it has read
// this computer waits for a yes (`asking`). Only at the agent's Chat level: nothing here raises it.
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
        messages.clear()
        lastQuestion = ""
        lastAnswer = ""
        fresh = false
    }
    // a confirm in words, for the conversation's card and Expanded
    function describe(a) {
        if (!a) return ""
        const what = ({ search: "Search the web for", fetch: "Read", open: "Open", launch: "Open" })[a.what] ?? "Allow"
        const why = (a.why ?? []).map(w => ({ private: "this chat has read details of this computer",
            sensitive: "it looks like a password, a key or a card number", runs: "it runs a program",
            web: "this answer has read the web" })[w]).filter(w => w)
        return what + " “" + (a.text ?? a.path ?? "") + "”?" + (why.length > 0 ? " Asked because " + why.join(", and ") + "." : "")
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
    readonly property var phases: ({ web_search: "searching", open_url: "reading", system_info: "looking", open_app: "opening" })

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
                detail = String(e.args?.query ?? e.args?.url ?? e.args?.target ?? "")
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
        case "error":
            if (e.code === "ollama-down") reachable = false
            if (busy) failure = e.code === "ollama-down" ? "Ollama isn't answering at 127.0.0.1:11434 (systemctl status ollama)"
                                                         : String(e.detail || e.code)
            else console.log("nilo-agent: " + e.code + " " + (e.detail ?? ""))
            break
        case "done":
            if (busy) finish(!e.failed && !e.cancelled, e.cancelled ? "Stopped" : failure)
            break
        }
    }
    function settings(s) {
        model = s.model ?? ""
        web = s.web === true
        think = s.think === true
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
        running: true
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
