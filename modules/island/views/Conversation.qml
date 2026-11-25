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

    implicitWidth: peek ? 560 : 780
    implicitHeight: peek ? Math.max(84, peekText.implicitHeight + 36) : column.implicitHeight + 2 * pad

    // the model loads while you get to the question (as Nilo does while you type)
    Component.onCompleted: { Agent.refresh(); if (!Engine.toast) { Agent.warm(); Agent.fresh = false } }

    // With a card waiting, the first Enter only arms it and the second allows (as Nilo's): a question
    // typed and sent the moment the card comes up can't say yes to it.
    property string armed: ""
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
    }
    function host(url) { const m = String(url).match(/^\w+:\/\/([^/]+)/); return m ? m[1].replace(/^www\./, "") : url }
    // Only the web: the model reads pages now, and a page could have it write a file:// link to a script.
    function follow(link) { if (/^https?:\/\//i.test(link)) Toggles.open(link) }
    property string pointing: ""      // the link under the pointer: where it goes, whatever its words say
    function step(s) {
        const verbs = ({ web_search: ["Searching", "Searched", "search"], open_url: ["Reading", "Read", "read"],
                         system_info: ["Looking at", "Looked at", "look at"], open_app: ["Opening", "Opened", "open"] })[s.name]
            ?? [s.name, s.name, "run " + s.name]
        const what = s.name === "system_info" ? "this computer" : s.name === "web_search" ? "“" + s.arg + "”"
            : s.name === "open_url" ? (s.title || host(s.arg)) : (s.opened || s.arg)
        return s.status === "running" ? verbs[0] + " " + what + "…"
            : s.status === "failed" ? "Couldn't " + verbs[2] + " " + what + (s.error ? ": " + s.error : "")
            : s.status === "declined" ? "Didn't " + verbs[2] + " " + what
            : verbs[1] + " " + what + (s.count !== undefined ? " · " + s.count + " results" : "")
    }
    // a peek reads as plain text: no Markdown marks
    function plain(text) { return String(text).replace(/```[\s\S]*?```/g, " … ").replace(/[*_`#>\[\]]/g, "").replace(/\s+/g, " ").trim() }
    function question(a) { return Agent.describe(a) }

    readonly property string status: Agent.trouble !== "" ? Agent.trouble
        : !Agent.ready ? "Starting the agent"
        : !Agent.reachable ? "Ollama isn't running: systemctl status ollama"
        : Agent.inUse === "" ? "No chat model yet: add one to loadModels (features/ollama)"
        : Agent.busy ? Agent.activity
        : Agent.warming ? "Loading " + Agent.inUse
        : Agent.loaded ? Agent.inUse + ", in memory" : Agent.inUse + ", asleep: it loads with the first question"

    // ---- the peek ----
    Row {
        visible: root.peek
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Config.spaceXl; rightMargin: Config.spaceXl }
        spacing: Config.spaceL

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 44; height: 44; radius: 22
            color: Config.primary

            Icon {
                anchors.centerIn: parent
                name: "smart_toy"
                size: 22
                filled: true
                color: Config.primaryInk
            }
        }
        Column {
            id: peekText
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 58
            spacing: Config.spaceHair

            Label {
                width: parent.width
                text: Agent.asking ? "The agent asks, in the conversation" : Agent.lastQuestion
                elide: Text.ElideRight
                color: Config.dim
                font.pixelSize: Config.small + 1
            }
            Label {
                width: parent.width
                text: Agent.asking ? root.question(Agent.asking) : root.plain(Agent.lastAnswer)
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
        }
    }

    // ---- the conversation ----
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

        Label {
            visible: Agent.messages.count === 0
            width: parent.width
            topPadding: Config.spaceS
            bottomPadding: Config.spaceS
            wrapMode: Text.Wrap
            text: "Ask anything. The model runs on this computer: nothing leaves it unless Internet is on, "
                + "when it may search the web and read pages. It can also look up this computer and open apps. "
                + "The conversation is kept only until the shell stops. Try “?” in the launcher too."
            color: Config.dim
        }

        ListView {
            id: list
            visible: Agent.messages.count > 0
            width: parent.width
            height: Math.min(contentHeight, 440)
            spacing: Config.spaceL
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: Agent.messages
            // the answer being written stays in sight
            onContentHeightChanged: if (Agent.busy) positionViewAtEnd()
            onCountChanged: Qt.callLater(positionViewAtEnd)

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
                height: mine ? bubble.height : answer.implicitHeight

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

                // the answer: what it thought, the tools it used, then the words, as Markdown
                Column {
                    id: answer
                    visible: !msg.mine
                    width: parent.width
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
                            ClickArea { onClicked: Agent.messages.setProperty(msg.index, "open", !msg.open) }
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
                                color: Config.container

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
                Row {
                    spacing: Config.spaceS

                    Chip {
                        icon: "check"
                        text: root.armed !== "" ? "Enter again to allow" : "Allow"
                        selected: root.armed !== ""
                        onClicked: Agent.answer(true)
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
