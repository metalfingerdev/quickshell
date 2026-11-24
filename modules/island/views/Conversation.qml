import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The agent (services/Agent.qml; this file is Conversation, not Agent, so it doesn't hide that singleton), after Nihil-Shell's Nilo but light: a conversation with the local
// model. Pinned: the conversation, its switches (the model, Internet, Think) and the field to ask in.
// Enter asks, Ctrl+C stops an answer, Ctrl+N starts over, Escape closes and the answer goes on: when it
// ends, Triggers peeks it here as a toast (the question, how the answer starts), and a click opens it.
Item {
    id: root

    readonly property int pad: 24
    readonly property bool peek: Engine.toast

    implicitWidth: peek ? 560 : 780
    implicitHeight: peek ? Math.max(84, peekText.implicitHeight + 36) : column.implicitHeight + 2 * pad

    // the model loads while you get to the question (as Nilo does while you type)
    Component.onCompleted: { Agent.refresh(); if (!peek) Agent.warm() }

    function send() {
        if (Agent.busy) return
        Agent.ask(field.text)
        field.text = ""
    }
    function host(url) { const m = String(url).match(/^\w+:\/\/([^/]+)/); return m ? m[1].replace(/^www\./, "") : url }
    // a peek reads as plain text: no Markdown marks
    function plain(text) { return String(text).replace(/```[\s\S]*?```/g, " … ").replace(/[*_`#>\[\]]/g, "").replace(/\s+/g, " ").trim() }

    readonly property string status: !Agent.reachable ? "Ollama isn't running: systemctl status ollama"
        : Agent.inUse === "" ? "No chat model yet: ollama pull qwen3.5:2b"
        : Agent.busy ? ({ searching: "Searching the web", loading: "Loading " + Agent.inUse, thinking: "Thinking",
                          answering: "Answering" })[Agent.phase] ?? "Working"
        : Agent.warming ? "Loading " + Agent.inUse
        : Agent.loaded ? Agent.inUse + ", in memory" : Agent.inUse + ", asleep: it loads with the first question"

    // ---- the peek ----
    Row {
        visible: root.peek
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 20; rightMargin: 20 }
        spacing: 14

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
            spacing: 2

            Label {
                width: parent.width
                text: Agent.lastQuestion
                elide: Text.ElideRight
                color: Config.dim
                font.pixelSize: Config.small + 1
            }
            Label {
                width: parent.width
                text: root.plain(Agent.lastAnswer)
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
        spacing: 12

        Header {
            width: parent.width
            icon: "smart_toy"
            title: "Agent"
            subtitle: root.status
            onBack: Engine.back()

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
            spacing: 8

            Repeater {
                model: Agent.models

                Chip {
                    required property string modelData
                    text: modelData
                    selected: Agent.inUse === modelData
                    onClicked: { Agent.model = modelData; Agent.loaded = false; Agent.warm() }
                }
            }
            Chip {
                icon: "travel_explore"
                text: "Internet"
                selected: Agent.web
                onClicked: Agent.web = !Agent.web
            }
            Chip {
                icon: "psychology"
                text: "Think"
                selected: Agent.think
                onClicked: Agent.think = !Agent.think
            }
        }

        Label {
            visible: Agent.messages.count === 0
            width: parent.width
            topPadding: 8
            bottomPadding: 8
            wrapMode: Text.Wrap
            text: "Ask anything. The model runs on this computer: nothing leaves it unless Internet is on, "
                + "and the conversation is kept only until the shell stops. Try “?” in the launcher too."
            color: Config.dim
        }

        ListView {
            id: list
            visible: Agent.messages.count > 0
            width: parent.width
            height: Math.min(contentHeight, 440)
            spacing: 14
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
                required property string sources
                required property string by
                required property bool streaming
                required property string error
                readonly property bool mine: role === "user"
                readonly property var links: { try { return JSON.parse(sources) } catch (e) { return [] } }

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

                // the answer, as Markdown, with what it's doing before the words come
                Column {
                    id: answer
                    visible: !msg.mine
                    width: parent.width
                    spacing: 8

                    Label {
                        visible: msg.streaming && msg.content === ""
                        width: parent.width
                        elide: Text.ElideRight
                        font.italic: true
                        color: Config.dim
                        text: Agent.phase === "searching" ? "Searching the web…"
                            : Agent.phase === "loading" ? "Loading " + msg.by + "…"
                            : msg.thinking !== "" ? "Thinking: " + msg.thinking.slice(-120).replace(/\s+/g, " ")
                            : "Thinking…"
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
                        onLinkActivated: link => Toggles.open(link)
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
                        spacing: 6

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

        Row {
            width: parent.width
            spacing: 10

            SearchBar {
                id: field
                width: parent.width - sendButton.width - parent.spacing
                implicitHeight: 56
                icon: "smart_toy"
                placeholder: Agent.busy ? "Answering… Ctrl+C stops it" : "Ask anything"
                focus: true
                controlKeys: [Qt.Key_C, Qt.Key_N]
                onKey: Engine.key()
                onAccepted: root.send()
                onEscaped: Engine.close()
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
            keys: [["↵", "ask"], ["Ctrl C", "stop"], ["Ctrl N", "new"], ["Esc", "close: the answer goes on"]]
        }
    }
}
