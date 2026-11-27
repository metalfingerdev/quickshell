import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The agent (services/Agent.qml, run by Nihil-Shell's; this file is Conversation, not Agent, so it doesn't
// hide that singleton): a conversation with the local model, which may search, read pages, look up this
// computer and open apps. Pinned: the conversation, its switches (the model, Internet, Think), the card
// for what waits for a yes, and the field to ask in.
// Enter asks, Ctrl+C stops an answer, Ctrl+N starts over, Escape closes and the answer goes on: when it
// ends, Triggers peeks it here as a toast (the question, how the answer starts), and a click opens it.
Item {
    id: root

    readonly property int pad: 24
    // Frozen once the engine has left this view: Bar keeps it up through the fade-out, and by then
    // Engine.toast is false, which would flash the full conversation for that split second.
    property bool peek: false
    Binding {
        target: root; property: "peek"; value: Engine.toast
        when: Engine.view === Engine.View.Agent
        restoreMode: Binding.RestoreNone
    }

    // wider than a notification popup (480): an answer, not a line
    implicitWidth: peek ? 600 : 780
    implicitHeight: peek ? peekCard.height + 16 : column.implicitHeight + 2 * pad

    // the model loads while you get to the question (as Nilo does while you type)
    Component.onCompleted: { Agent.refresh(); if (!Engine.toast) { Agent.warm(); Agent.fresh = false } }

    // With a card waiting, the first Enter only arms it and the second allows (as Nilo's): a question
    // typed and sent the moment the card comes up can't say yes to it.
    property string armed: ""
    Component.onCompleted: if (Agent.access !== "chat") Agent.loadRepos()
    Connections {
        target: Agent
        function onAskingChanged() { root.armed = "" }
    }
    function send() {
        if (Agent.asking) {
            if (field.text.trim() !== "") return
            if (armed === Agent.asking.id) Agent.answer(true)
            else armed = Agent.asking.id
            return
        }
        if (Agent.busy) return
        Agent.ask(field.text)
        field.text = ""
        list.stick()                // asking is wanting to see the answer, wherever you had scrolled
    }
    function host(url) { const m = String(url).match(/^\w+:\/\/([^/]+)/); return m ? m[1].replace(/^www\./, "") : url }
    // Only the web: the model reads pages now, and a page could have it write a file:// link to a script.
    function follow(link) { if (/^https?:\/\//i.test(link)) Toggles.open(link) }
    property string pointing: ""      // the link under the pointer: where it goes, whatever its words say
    function step(s) {
        const verbs = ({ web_search: ["Searching", "Searched", "search"], open_url: ["Reading", "Read", "read"],
                         system_info: ["Looking at", "Looked at", "look at"], open_app: ["Opening", "Opened", "open"],
                         read_file: ["Reading", "Read", "read"], list_files: ["Listing", "Listed", "list"],
                         edit_file: ["Editing", "Edited", "edit"], write_file: ["Writing", "Wrote", "write"],
                         run_command: ["Running", "Ran", "run"], git_status: ["Checking", "Checked", "check"],
                         git_commit: ["Committing", "Committed", "commit"], list_windows: ["Listing", "Listed", "list"],
                         look_at_screen: ["Looking at", "Looked at", "look at"], click: ["Clicking", "Clicked", "click"],
                         use_window: ["Using", "Used", "use"], type_text: ["Typing", "Typed", "type"],
                         press_keys: ["Pressing", "Pressed", "press"], media: ["Controlling", "Controlled", "control"],
                         control: ["Setting", "Set", "set"] })[s.name]
            ?? [s.name, s.name, "run " + s.name]
        const what = s.name === "system_info" ? "this computer" : s.name === "web_search" ? "“" + s.arg + "”"
            : s.name === "open_url" ? (s.title || host(s.arg))
            : s.name === "git_status" || s.name === "git_commit" ? "git" : s.name === "list_windows" ? "the windows"
            : s.name === "look_at_screen" ? "the screen" : s.name === "run_command" ? "`" + s.arg + "`" : (s.opened || s.arg)
        return s.status === "running" ? verbs[0] + " " + what + "…"
            : s.status === "failed" ? "Couldn't " + verbs[2] + " " + what + (s.error ? ": " + s.error : "")
            : s.status === "declined" ? "Didn't " + verbs[2] + " " + what
            : verbs[1] + " " + what + (s.count !== undefined ? " · " + s.count + " results" : "")
    }
    // a peek reads as plain text: no Markdown marks
    function plain(text) { return String(text).replace(/```[\s\S]*?```/g, " … ").replace(/[*_`#>\[\]]/g, "").replace(/\s+/g, " ").trim() }
    function question(a) { return Agent.describe(a) }
    // the part of a confirm too long for a sentence: a diff, a command, the files a commit takes
    function detail(a) {
        if (!a) return ""
        if (a.action === "edit" || a.action === "create") return String(a.diff ?? "")
        if (a.action === "run" || a.action === "terminal") return "$ " + a.command
        if (a.files?.length > 0) return a.files.join("\n") + (a.more > 0 ? "\n… and " + a.more + " more" : "")
        return ""
    }

    readonly property string status: Agent.trouble !== "" ? Agent.trouble
        : !Agent.ready ? "Starting the agent"
        : !Agent.reachable ? "Ollama isn't running: systemctl status ollama"
        : Agent.inUse === "" ? "No chat model yet: add one to loadModels (features/ollama)"
        : Agent.busy ? Agent.activity
        : Agent.warming ? "Loading " + Agent.inUse
        : Agent.loaded ? Agent.inUse + ", in memory" : Agent.inUse + ", asleep: it loads with the first question"

    // The peek: a card laid out as a notification popup's (parts/NotificationCard), never words on the bare
    // glass, which a busy wallpaper behind it would swallow
    Rectangle {
        id: peekCard
        visible: root.peek
        x: 8; y: 8
        width: parent.width - 16
        height: Math.max(72, peekText.implicitHeight + 32)
        radius: Config.innerRadius + 4
        color: Config.tile

        Rectangle {
            x: 16; y: 16
            width: 40; height: 40; radius: 20
            color: Config.raised

            Icon {
                anchors.centerIn: parent
                name: "smart_toy"
                size: 20
                filled: true
                color: Config.primary
            }
        }
        Column {
            id: peekText
            anchors { left: parent.left; leftMargin: 16 + 40 + Config.spaceL; right: parent.right; rightMargin: Config.spaceL; top: parent.top; topMargin: Config.spaceL }
            spacing: Config.spaceHair

            Label {
                width: parent.width
                text: "Agent" + (Agent.busy ? "  ·  " + Agent.activity : "")
                elide: Text.ElideRight
                color: Config.dim
                font.pixelSize: Config.small
            }
            Label {
                width: parent.width
                text: Agent.asking ? "The agent asks, in the conversation" : Agent.lastQuestion
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Config.text
                font.pixelSize: Config.body + 1
                font.weight: Font.DemiBold
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: Agent.asking ? root.question(Agent.asking) : root.plain(Agent.lastAnswer)
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                color: Config.dim
                font.pixelSize: Config.small + 1
            }
        }
    }

    // The conversation
    Column {
        id: column
        visible: !root.peek
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceM

        Header {
            width: parent.width
            icon: "smart_toy"
            title: "Agent"
            subtitle: root.pointing !== "" ? "Goes to " + root.pointing : root.status
            onBack: Engine.back()

            Pill {
                visible: Agent.has("notes")
                implicitHeight: 44
                icon: "sticky_note_2"
                text: "Notes"
                onClicked: Agent.openNotes()
            }
            Pill {
                visible: Agent.messages.count > 0
                implicitHeight: 44
                icon: "add_comment"
                text: "New"
                onClicked: { Agent.reset(); field.forceActiveFocus() }
            }
        }

        // which model, and what it may do: read the web first (SearXNG), and think before answering
        Flow {
            width: parent.width
            spacing: Config.spaceS

            Repeater {
                // one model is no choice: its chip would look like a button that does nothing
                model: Agent.models.length > 1 ? Agent.models : []

                Chip {
                    required property string modelData
                    text: modelData
                    selected: Agent.inUse === modelData
                    onClicked: { Agent.set("model", modelData); Agent.warm() }
                }
            }
            Chip {
                icon: "travel_explore"
                text: "Internet"
                selected: Agent.web
                onClicked: Agent.set("web", !Agent.web)
            }
            Chip {
                icon: "psychology"
                text: "Think"
                selected: Agent.think
                onClicked: Agent.set("think", !Agent.think)
            }
        }

        // What it may do, by level (the agent asks before each change, command and desktop action): Chat
        // answers, searches and opens apps; Terminal works in one repository; System also uses windows and
        // the screen. A level older than the agent knows isn't offered.
        Flow {
            visible: Agent.has("access")
            width: parent.width
            spacing: Config.spaceS

            Repeater {
                model: [{ key: "chat", icon: "chat", text: "Chat" }, { key: "terminal", icon: "terminal", text: "Files and commands" },
                        { key: "system", icon: "desktop_windows", text: "Desktop" }]

                Chip {
                    required property var modelData
                    icon: modelData.icon
                    text: modelData.text
                    selected: Agent.access === modelData.key
                    onClicked: { Agent.set("access", modelData.key); if (modelData.key !== "chat") Agent.loadRepos() }
                }
            }
        }
        // the repository it works in (Files and commands, Desktop): the ones found in the home folder
        Flow {
            visible: Agent.has("repos") && Agent.access !== "chat" && Agent.repos.length > 0
            width: parent.width
            spacing: Config.spaceS

            Repeater {
                model: Agent.repos.slice(0, 8)

                Chip {
                    required property string modelData
                    icon: "folder"
                    text: modelData
                    selected: Agent.repo === modelData
                    onClicked: Agent.set("repo", modelData)
                }
            }
        }

        Rectangle {
            visible: Agent.messages.count === 0
            width: parent.width
            height: intro.implicitHeight + 2 * Config.spaceM
            radius: Config.innerRadius
            color: Config.tile

            Label {
                id: intro
                anchors { left: parent.left; right: parent.right; margins: Config.spaceM; verticalCenter: parent.verticalCenter }
                wrapMode: Text.Wrap
                text: "Ask anything. The model runs on this computer: nothing leaves it unless Internet is on, "
                    + "when it may search the web and read pages. It can also look up this computer and open apps; "
                    + "with Files and commands it works in a repository, and with Desktop it can use windows too, "
                    + "always asking before it changes anything. "
                    + "The conversation is kept only until the shell stops. Try “?” in the launcher too."
                color: Config.dim
            }
        }

        Item {
            visible: Agent.messages.count > 0
            width: parent.width
            height: list.height

            ListView {
                id: list
                width: parent.width
                height: Math.min(contentHeight, 440)
                spacing: Config.spaceL
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: Agent.messages

                // Follows the answer only while you're at the end, as web chats do (after StackBlitz's
                // use-stick-to-bottom): scrolling up by any amount lets go, and new text never pulls you back;
                // scrolling down to within 70 px of the end, sending a question or the arrow takes hold again.
                // A ListView keeps contentY when content grows (it measures rows as they're made, moving
                // originY), so growth is never mistaken for you; the one move that isn't yours is the clamp
                // when content shrinks under the very end. Unlike the library, shrinking doesn't take hold
                // again: a ListView re-measures rows as you scroll, and that would undo your scroll up.
                property bool stuck: true
                property bool own: false
                property real lastY: 0
                readonly property real gap: originY + contentHeight - height - contentY
                readonly property bool nearEnd: gap <= 70
                function toEnd() { own = true; positionViewAtEnd(); own = false; lastY = contentY }
                function stick() { stuck = true; Qt.callLater(settle) }
                // checked when it runs: a scroll of yours in between (making rows) may have let go
                function settle() { if (stuck) toEnd() }
                function follow() { Qt.callLater(settle) }
                onContentYChanged: {
                    // worked out here: `gap` is a binding on contentY and may not have caught up yet
                    const left = originY + contentHeight - height - contentY
                    if (!own) {
                        if (contentY < lastY - 0.5 && left > 0.5) stuck = false
                        else if (contentY > lastY + 0.5 && left <= 70) stuck = true
                    }
                    lastY = contentY
                }
                onContentHeightChanged: follow()
                onOriginYChanged: follow()
                onCountChanged: follow()
                onHeightChanged: follow()

                delegate: Item {
                    id: msg
                    required property int index
                    required property string role
                    required property string content
                    required property string thinking
                    required property int thought
                    required property bool open
                    required property string steps
                    required property string sources
                    required property string by
                    required property bool streaming
                    required property string error
                    readonly property bool mine: role === "user"
                    readonly property bool thinkingNow: streaming && Agent.phase === "thinking"
                    readonly property var links: { try { return JSON.parse(sources) } catch (e) { return [] } }
                    readonly property var tools: { try { return JSON.parse(steps) } catch (e) { return [] } }

                    width: list.width
                    height: mine ? bubble.height : answer.implicitHeight + 2 * Config.spaceM

                    // the question, on the right
                    Rectangle {
                        id: bubble
                        visible: msg.mine
                        anchors.right: parent.right
                        width: question.width + 32
                        height: question.implicitHeight + 20
                        radius: Config.innerRadius + 4
                        color: Config.secondary

                        Label {
                            id: question
                            x: 16
                            y: 10
                            width: Math.min(implicitWidth, msg.width * 0.8 - 32)
                            text: msg.content
                            wrapMode: Text.Wrap
                            textFormat: Text.PlainText
                            color: Config.secondaryInk
                        }
                    }

                    // the answer on a card, so it reads on clear glass
                    Rectangle {
                        visible: !msg.mine
                        anchors.fill: parent
                        radius: Config.cardRadius
                        color: Config.tile
                    }

                    // the answer: what it thought, the tools it used, then the words, as Markdown
                    Column {
                        id: answer
                        visible: !msg.mine
                        x: Config.spaceM
                        y: Config.spaceM
                        width: parent.width - 2 * Config.spaceM
                        spacing: Config.spaceS

                        // The thinking as the model wrote it, folded to its latest words while it goes on; a
                        // click opens all of it. Laid out only when open: it can run to thousands of words.
                        Column {
                            visible: msg.thinking !== ""
                            width: parent.width
                            spacing: Config.spaceS

                            Item {
                                width: parent.width
                                height: 24
                                activeFocusOnTab: true
                                function activate() { Agent.messages.setProperty(msg.index, "open", !msg.open) }
                                Accessible.role: Accessible.Button
                                Accessible.name: "Thinking"
                                Accessible.onPressAction: activate()
                                FocusRing { on: parent.activeFocus && Config.focusVisible }

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Config.spaceXs

                                    Icon {
                                        anchors.verticalCenter: parent.verticalCenter
                                        name: "chevron_right"
                                        size: 18
                                        color: Config.dim
                                        rotation: msg.open ? 90 : 0
                                        Behavior on rotation { Motion {} }
                                    }
                                    Label {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: (msg.thinkingNow ? "Thinking" : "Thought") + (msg.thought > 0 ? " for " + msg.thought + " s" : "")
                                        color: Config.dim
                                    }
                                }
                                ClickArea { onClicked: parent.activate() }
                            }
                            Label {
                                visible: !msg.open && msg.thinkingNow
                                width: parent.width
                                leftPadding: Config.spaceXl
                                text: msg.thinking.slice(-160).replace(/\s+/g, " ")
                                elide: Text.ElideLeft
                                font.italic: true
                                color: Config.dim
                            }
                            Loader {
                                active: msg.open
                                visible: active
                                sourceComponent: Rectangle {
                                    width: answer.width
                                    height: thoughts.implicitHeight + 24
                                    radius: Config.innerRadius
                                    color: Config.raised

                                    Text {
                                        id: thoughts
                                        x: 14
                                        y: 12
                                        width: parent.width - 28
                                        text: msg.thinking
                                        textFormat: Text.PlainText
                                        wrapMode: Text.Wrap
                                        color: Config.dim
                                        font.family: Config.font
                                        font.pixelSize: Config.small + 1
                                    }
                                }
                            }
                        }

                        // a row for each tool, its dot beating while it works
                        Repeater {
                            model: msg.tools

                            Row {
                                id: tool
                                required property var modelData
                                spacing: Config.spaceM

                                Rectangle {
                                    id: dot
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: tool.modelData.status === "failed" ? Config.bad : tool.modelData.status === "running" ? Config.text : Config.dim
                                    SequentialAnimation on opacity {
                                        running: tool.modelData.status === "running"
                                        loops: Animation.Infinite
                                        onRunningChanged: if (!running) dot.opacity = 1
                                        NumberAnimation { to: 0.2; duration: Config.durationMedium * 2 }
                                        NumberAnimation { to: 1; duration: Config.durationMedium * 2 }
                                    }
                                }
                                Label {
                                    width: answer.width - 16
                                    text: root.step(tool.modelData)
                                    elide: Text.ElideRight
                                    color: Config.dim
                                    font.family: Config.mono
                                    font.pixelSize: Config.small
                                }
                            }
                        }

                        Label {
                            visible: msg.streaming && msg.content === "" && !Agent.toolAtWork && !(msg.thinkingNow && msg.thinking !== "")
                            width: parent.width
                            elide: Text.ElideRight
                            font.italic: true
                            color: Config.dim
                            text: Agent.activity + "…"
                        }
                        Text {
                            visible: msg.content !== ""
                            width: parent.width
                            text: msg.content + (msg.streaming ? " ▍" : "")
                            textFormat: Text.MarkdownText
                            wrapMode: Text.Wrap
                            color: Config.text
                            linkColor: Config.primary
                            font.family: Config.font
                            font.pixelSize: Config.body + 1
                            onLinkActivated: link => root.follow(link)
                            onHoveredLinkChanged: root.pointing = hoveredLink
                        }
                        Label {
                            visible: msg.error !== ""
                            width: parent.width
                            wrapMode: Text.Wrap
                            text: msg.error
                            color: msg.error === "Stopped" ? Config.dim : Config.bad
                        }
                        // where it read it, and the answer to take away
                        Flow {
                            visible: !msg.streaming && msg.content !== ""
                            width: parent.width
                            spacing: Config.spaceS

                            Repeater {
                                model: msg.links

                                Chip {
                                    required property var modelData
                                    required property int index
                                    icon: "link"
                                    text: "[" + (index + 1) + "] " + root.host(modelData.url)
                                    onClicked: Toggles.open(modelData.url)
                                }
                            }
                            Chip {
                                icon: "content_copy"
                                text: "Copy"
                                onClicked: Quickshell.clipboardText = msg.content
                            }
                        }
                    }
                }
            }

            // back to the end, when you've scrolled away from it (and something is below)
            Pill {
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Config.spaceS }
                visible: !list.stuck && !list.nearEnd
                implicitHeight: 36
                icon: "arrow_downward"
                iconSize: 20
                onClicked: list.stick()
            }
        }

        // What waits for a yes. Once a chat has read this computer, anything on its way to the web asks,
        // as does what looks like a password and a file that runs; five minutes unanswered is a no.
        Rectangle {
            visible: Agent.asking !== null
            width: parent.width
            height: ask.implicitHeight + 28
            radius: Config.innerRadius + 4
            color: Config.secondary

            Column {
                id: ask
                x: 16
                y: 14
                width: parent.width - 32
                spacing: Config.spaceM

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    textFormat: Text.PlainText
                    color: Config.secondaryInk
                    text: root.question(Agent.asking)
                }
                // what exactly is asked: the diff, the command or the files, in a box of its own
                Rectangle {
                    visible: detailText.text !== ""
                    width: parent.width
                    height: Math.min(detailText.implicitHeight, 220) + 20
                    radius: Config.innerRadius
                    color: Config.raised
                    clip: true

                    Text {
                        id: detailText
                        x: 10
                        y: 10
                        width: parent.width - 20
                        text: root.detail(Agent.asking)
                        textFormat: Text.PlainText
                        wrapMode: Text.WrapAnywhere
                        color: Config.text
                        font.family: Config.mono
                        font.pixelSize: Config.small
                    }
                }
                Row {
                    spacing: Config.spaceS

                    Chip {
                        icon: "check"
                        text: root.armed !== "" ? "Enter again to allow" : "Allow"
                        selected: root.armed !== ""
                        onClicked: Agent.answer(true)
                    }
                    Chip {
                        visible: Agent.asking?.action === "edit" || Agent.asking?.action === "create"
                        icon: "done_all"
                        text: "Allow edits in this answer"
                        onClicked: { Agent.confirmAll = true; Agent.answer(true) }
                    }
                    Chip { icon: "close"; text: "Don't"; onClicked: Agent.answer(false) }
                }
            }
        }

        Row {
            width: parent.width
            spacing: Config.spaceM

            SearchBar {
                id: field
                width: parent.width - sendButton.width - parent.spacing
                implicitHeight: 56
                icon: "smart_toy"
                placeholder: Agent.asking ? "Enter twice allows it, Escape doesn't"
                    : Agent.busy ? "Answering… Ctrl+C stops it" : "Ask anything"
                focus: true
                controlKeys: [Qt.Key_C, Qt.Key_N]
                onKey: Engine.key()
                onAccepted: root.send()
                onEscaped: Agent.asking ? Agent.answer(false) : Engine.close()
                onBackspaceEmpty: Engine.back()
                // Ctrl+C stops an answer (with nothing being answered it copies, as usual); Ctrl+N starts over
                onControl: key => {
                    if (key === Qt.Key_N) Agent.reset()
                    else if (Agent.busy) Agent.stop()
                    else if (field.field.selectedText !== "") field.field.copy()
                }
            }
            Pill {
                id: sendButton
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: 56
                icon: Agent.busy ? "stop" : "arrow_upward"
                text: Agent.busy ? "Stop" : "Ask"
                onClicked: Agent.busy ? Agent.stop() : root.send()
            }
        }

        KeyHints {
            width: parent.width
            keys: Agent.asking ? [["↵ ↵", "allow"], ["Esc", "don't"], ["Ctrl C", "stop"]]
                : [["↵", "ask"], ["Ctrl C", "stop"], ["Ctrl N", "new"], ["Esc", "close: the answer goes on"]]
        }
    }
}
