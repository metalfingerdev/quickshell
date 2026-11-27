//@ pragma Env QT_QPA_PLATFORM=wayland

// The login screen, run by greetd inside cage (modules/system/session in nixos-dotfiles) as the `greeter`
// user, so it can't read the island's settings or anyone's home: its few colours are its own, the picture is
// the lock screen's from the repo, and what it needs from the machine comes as environment variables
// (GREETER_USER, GREETER_SESSION as a JSON command, GREETER_READY a file it touches once it is up).
// After Nihil-Shell's greeter (MIT). Try the look without logging in: GREETER_DRY=1 qs -p greeter
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

ShellRoot {
    id: root

    readonly property string user: Quickshell.env("GREETER_USER") || "admin"
    readonly property var session: { try { return JSON.parse(Quickshell.env("GREETER_SESSION")) } catch (e) { return ["uwsm", "start", "hyprland-uwsm.desktop"] } }
    readonly property bool dry: Quickshell.env("GREETER_DRY") === "1"

    property bool asking: false         // PAM wants an answer
    property bool echo: false           // and it may be seen as typed (a username, a code)
    property bool sent: false
    property string note: ""
    property bool wrong: false
    property int attempts: 0
    property bool going: false
    property real shown: 0              // the faces fade in, and out on the way to the session
    Behavior on shown { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    // The colours: a dark glass over the picture, white ink, one red for a refusal
    readonly property color ink: "#f5f5f7"
    readonly property color dim: "#c7c7cc"
    readonly property color muted: "#8e8e93"
    readonly property color glass: Qt.rgba(0.08, 0.09, 0.1, 0.55)
    readonly property color bad: "#ff6b6b"

    function start() {
        asking = false; echo = false; sent = false
        if (Greetd.available) Greetd.createSession(user)
    }
    function submit(text) {
        if (text === "" || going || sent || !asking) return
        asking = false
        sent = true
        Greetd.respond(text)
    }
    // If launching fails, the faces come back instead of staying dark with the field off.
    function back() { leave.stop(); going = false; shown = 1 }
    function said(text) {
        const words = text.trim()
        if (/^authentication failure$/i.test(words)) return "Wrong password" + (attempts > 1 ? " (" + attempts + ")" : "")
        return words.length > 0 ? words.charAt(0).toUpperCase() + words.slice(1) : words
    }

    // One face per screen when cage extends over several, else one that fills the window
    readonly property var faces: {
        const full = [Qt.rect(0, 0, window.width, window.height)]
        const screens = Quickshell.screens
        if (screens.length < 2) return full
        let left = Infinity, top = Infinity
        for (const s of screens) { left = Math.min(left, s.x); top = Math.min(top, s.y) }
        const out = []
        for (const s of screens) {
            const r = Qt.rect(s.x - left, s.y - top, s.width, s.height)
            if (!(r.width > 0 && r.height > 0 && r.x + r.width <= window.width + 1 && r.y + r.height <= window.height + 1)) return full
            out.push(r)
        }
        return out
    }

    Connections {
        target: Greetd

        function onAuthMessage(message: string, error: bool, responseRequired: bool, echoResponse: bool): void {
            if (responseRequired) {
                root.echo = echoResponse
                root.note = echoResponse ? root.said(message) : root.wrong ? root.note : ""
                root.sent = false
                root.asking = true
                return
            }
            // a reader asking for a finger, or a message from PAM
            root.note = /finger|swipe|sensor|reader/i.test(message) ? "Touch the fingerprint reader" : root.said(message)
            root.wrong = error
        }
        function onAuthFailure(message: string): void {
            root.back()
            root.attempts += 1
            root.wrong = true
            root.note = root.said("authentication failure")
            root.asking = false
            root.sent = false
            input.text = ""
            again.restart()
        }
        function onReadyToLaunch(): void { root.going = true; leave.start() }
        function onError(error: string): void {
            root.back()
            root.wrong = true
            root.note = root.said(error)
            again.restart()
        }
    }
    Timer { id: again; interval: 400; onTriggered: root.start() }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    // the start script waits for this file: without it, it falls back to the text greeter
    Process { id: ready; command: ["touch", Quickshell.env("GREETER_READY") || "/dev/null"] }

    FloatingWindow {
        id: window
        title: "Login"
        color: "#000000"
        fullscreen: true
        visible: true

        Component.onCompleted: {
            if (Greetd.available) ready.running = true
            if (Greetd.available) root.start()
            else root.asking = true     // outside greetd (a dry run): the field works, nothing is sent
            root.shown = 1
            input.forceActiveFocus()
        }

        // What's typed, for every face: out of sight, the one thing that takes the keys
        TextInput {
            id: input
            width: 1; height: 1
            opacity: 0
            echoMode: root.echo ? TextInput.Normal : TextInput.Password
            enabled: !root.going
            onTextEdited: root.wrong = false
            onAccepted: { if (root.dry || !Greetd.available) { text = ""; root.wrong = true; root.note = "Dry run: nothing is sent" } else { root.submit(text); } }
            Keys.onEscapePressed: text = ""
        }

        Repeater {
            model: root.faces

            Item {
                id: face
                required property rect modelData
                x: modelData.x; y: modelData.y
                width: modelData.width; height: modelData.height
                opacity: root.shown

                Image {
                    anchors.fill: parent
                    source: Qt.resolvedUrl("../assets/wallpapers/lockscreen.webp")
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.35 }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 - 190
                    text: Qt.formatTime(clock.date, "HH:mm")
                    color: root.ink
                    font.pixelSize: 140
                    font.weight: Font.Light
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 - 60
                    text: Qt.formatDate(clock.date, "dddd, d MMMM")
                    color: root.dim
                    font.pixelSize: 18
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 - 14
                    text: root.user
                    color: root.ink
                    font.pixelSize: 20
                    font.weight: Font.Medium
                }

                Rectangle {
                    id: field
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height / 2 + 36
                    width: 300
                    height: 48
                    radius: 24
                    color: root.glass
                    border.width: 1
                    border.color: root.wrong ? root.bad : root.sent ? root.muted : Qt.rgba(1, 1, 1, 0.25)
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {          // what a prompt that may be seen asks for, as typed
                        anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                        visible: root.echo
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideLeft
                        text: input.text
                        color: root.ink
                        font.pixelSize: 15
                    }
                    Row {
                        anchors.centerIn: parent
                        spacing: 7
                        visible: !root.echo
                        Repeater {
                            model: Math.min(input.text.length, 16)
                            Rectangle { width: 10; height: 10; radius: 5; color: root.ink }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: input.text.length === 0
                        text: root.sent ? "Checking…" : "Password"
                        color: root.muted
                        font.pixelSize: 14
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: input.forceActiveFocus() }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: field.y + field.height + 18
                    text: root.note
                    color: root.wrong ? root.bad : root.muted
                    font.pixelSize: 13
                }

                // Restart and Shut down ask twice, as the island's Power does: one click by chance doesn't turn it off
                Row {
                    anchors { right: parent.right; bottom: parent.bottom; margins: 36 }
                    spacing: 20

                    Repeater {
                        model: [{ label: "Restart", command: ["systemctl", "reboot"] }, { label: "Shut down", command: ["systemctl", "poweroff"] }]

                        Rectangle {
                            id: action
                            required property var modelData
                            property bool armed: false
                            width: label.implicitWidth + 28
                            height: 34
                            radius: 17
                            color: armed ? root.bad : area.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : root.glass

                            Text {
                                id: label
                                anchors.centerIn: parent
                                text: action.armed ? "Again?" : action.modelData.label
                                color: action.armed ? "#000000" : root.ink
                                font.pixelSize: 13
                            }
                            Timer { id: disarm; interval: 3000; onTriggered: action.armed = false }
                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (action.armed) { if (!root.dry) Quickshell.execDetached(action.modelData.command); return }
                                    action.armed = true
                                    disarm.restart()
                                }
                            }
                        }
                    }
                }
            }
        }

        NumberAnimation {
            id: leave
            target: root
            property: "shown"
            to: 0
            duration: 250
            onFinished: Greetd.launch(root.session, ["XDG_SESSION_TYPE=wayland"])
        }
    }
}
