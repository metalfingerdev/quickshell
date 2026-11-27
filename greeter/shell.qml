//@ pragma Env QT_QPA_PLATFORM=wayland

// The login screen, run by greetd inside cage (modules/system/session in nixos-dotfiles) as the `greeter`
// user, so it can't read the island's settings or anyone's home: its few colours are its own, the pictures
// are the repo's (assets/wallpapers/greeter.gif, assets/avatar.gif), and what it needs from the machine comes as environment variables
// (GREETER_USER, GREETER_SESSION as a JSON command, GREETER_READY a file it touches once it is up).
// After Nihil-Shell's greeter (MIT). Try the look without logging in: GREETER_DRY=1 qs -p greeter
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import Quickshell.Widgets

ShellRoot {
    id: root

    readonly property string user: Quickshell.env("GREETER_USER") || "admin"
    readonly property var session: { try { return JSON.parse(Quickshell.env("GREETER_SESSION")) } catch (e) { return ["uwsm", "start", "hyprland-uwsm.desktop"] } }
    readonly property bool dry: Quickshell.env("GREETER_DRY") === "1"
    // By shellPath, as the island's lock does: a URL resolved against this file outside its own folder
    // doesn't reach the picture (Quickshell intercepts the config's URLs)
    function asset(name) { return "file://" + Quickshell.shellPath("../assets/" + name) }

    property bool asking: false         // PAM wants an answer
    property bool echo: false           // and it may be seen as typed (a username, a code)
    property bool sent: false
    property string note: ""
    property bool wrong: false
    property int attempts: 0
    property bool going: false
    property real shown: 0              // the whole screen: in at the start, out on the way to the session
    property real ui: 1                 // the login controls alone: they fade first, the picture stays
    property bool playGif: false
    Behavior on shown { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

    // After a login: the controls fade away, the picture plays once (it waits on its first frame until
    // then), and everything fades into the session. A picture still loading, or one that never ends, doesn't
    // hold the login up: each step has its way out.
    property bool gifReady: false
    function farewell() {
        if (going) return
        going = true
        uiOut.start()
    }
    function play() {
        if (!gifReady) { finish(); return }
        playGif = true
        cap.restart()
    }
    function finish() {
        cap.stop()
        playGif = false
        leave.start()
    }

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
    function back() { leave.stop(); uiOut.stop(); cap.stop(); playGif = false; going = false; ui = 1; shown = 1 }
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
        function onReadyToLaunch(): void { root.farewell() }
        function onError(error: string): void {
            root.back()
            root.wrong = true
            root.note = root.said(error)
            again.restart()
        }
    }
    Timer { id: again; interval: 400; onTriggered: root.start() }
    Timer { id: cap; interval: 20000; onTriggered: root.finish() }       // the longest the picture may play
    NumberAnimation { id: uiOut; target: root; property: "ui"; to: 0; duration: 350; easing.type: Easing.InOutQuad; onFinished: root.play() }
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
            // a dry run plays the whole sequence on Enter, and sends and starts nothing
            onAccepted: { if (root.dry || !Greetd.available) root.farewell(); else root.submit(text) }
            Keys.onEscapePressed: text = ""
        }

        Repeater {
            model: root.faces

            Item {
                id: face
                required property rect modelData
                required property int index
                // one unit for every size and gap, so the layout scales with the screen (1 at 1080 p)
                readonly property real u: Math.max(0.7, Math.min(width, height) / 1080)

                x: modelData.x; y: modelData.y
                width: modelData.width; height: modelData.height
                opacity: root.shown

                // The greeter's picture, held on its first frame while you log in, then played once. `playing`
                // also waits for the load: a GIF that isn't Ready yet ignores being told to play.
                AnimatedImage {
                    id: gif
                    anchors.fill: parent
                    source: root.asset("wallpapers/greeter.gif")
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false            // its frames are tens of megabytes: read as it plays, not kept
                    playing: root.playGif && status === Image.Ready
                    onStatusChanged: {
                        if (face.index !== 0) return
                        root.gifReady = status === Image.Ready
                        if (status === Image.Error) console.warn("greeter: the picture didn't load:", source)
                    }
                    // one loop: from the last frame on, the screen fades into the session
                    onCurrentFrameChanged: if (face.index === 0 && root.playGif && frameCount > 1 && currentFrame === frameCount - 1) root.finish()
                }
                Rectangle { anchors.fill: parent; color: "#000000"; opacity: 0.35 * root.ui }

                Column {
                    id: stack
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -face.height * 0.04
                    width: 360 * face.u
                    opacity: root.ui

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(clock.date, "HH:mm")
                        color: root.ink
                        font.pixelSize: 132 * face.u
                        font.weight: Font.Light
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(clock.date, "dddd, d MMMM")
                        color: root.dim
                        font.pixelSize: 20 * face.u
                    }
                    Item { width: 1; height: 56 * face.u }

                    // the avatar the lock screen shows by default; the initial while it loads or if it can't
                    ClippingRectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 96 * face.u
                        height: width
                        radius: width / 2
                        color: root.glass

                        Text {
                            anchors.centerIn: parent
                            visible: avatar.status !== Image.Ready
                            text: root.user.charAt(0).toUpperCase()
                            color: root.ink
                            font.pixelSize: 38 * face.u
                            font.weight: Font.Medium
                        }
                        AnimatedImage {
                            id: avatar
                            anchors.fill: parent
                            source: root.asset("avatar.gif")
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            playing: status === Image.Ready
                        }
                    }
                    Item { width: 1; height: 14 * face.u }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.user
                        color: root.ink
                        font.pixelSize: 20 * face.u
                        font.weight: Font.Medium
                    }
                    Item { width: 1; height: 20 * face.u }

                    Rectangle {
                        id: field
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: 52 * face.u
                        radius: height / 2
                        color: root.glass
                        border.width: 1
                        border.color: root.wrong ? root.bad : root.sent ? root.muted : Qt.rgba(1, 1, 1, 0.25)
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Text {          // what a prompt that may be seen asks for, as typed
                            anchors { fill: parent; leftMargin: 20 * face.u; rightMargin: 20 * face.u }
                            visible: root.echo
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideLeft
                            text: input.text
                            color: root.ink
                            font.pixelSize: 16 * face.u
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 8 * face.u
                            visible: !root.echo
                            Repeater {
                                model: Math.min(input.text.length, 16)
                                Rectangle { width: 10 * face.u; height: width; radius: width / 2; color: root.ink }
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: input.text.length === 0
                            text: root.sent ? "Checking…" : "Password"
                            color: root.muted
                            font.pixelSize: 15 * face.u
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onClicked: input.forceActiveFocus() }
                    }
                    // always its height, so a message appearing never moves the field
                    Item {
                        width: parent.width
                        height: 44 * face.u

                        Text {
                            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter }
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: root.note
                            color: root.wrong ? root.bad : root.muted
                            font.pixelSize: 14 * face.u
                        }
                    }
                }

                // Restart and Shut down ask twice, as the island's Power does: one click by chance doesn't turn it off
                Row {
                    anchors { right: parent.right; bottom: parent.bottom; margins: 40 * face.u }
                    spacing: 12 * face.u
                    opacity: root.ui

                    Repeater {
                        model: [{ label: "Restart", command: ["systemctl", "reboot"] }, { label: "Shut down", command: ["systemctl", "poweroff"] }]

                        Rectangle {
                            id: action
                            required property var modelData
                            property bool armed: false
                            width: label.implicitWidth + 32 * face.u
                            height: 38 * face.u
                            radius: height / 2
                            color: armed ? root.bad : area.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : root.glass

                            Text {
                                id: label
                                anchors.centerIn: parent
                                text: action.armed ? "Again?" : action.modelData.label
                                color: action.armed ? "#000000" : root.ink
                                font.pixelSize: 14 * face.u
                            }
                            Timer { id: disarm; interval: 3000; onTriggered: action.armed = false }
                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !root.going
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
            onFinished: { if (!root.dry && Greetd.available) Greetd.launch(root.session, ["XDG_SESSION_TYPE=wayland"]) }
        }
    }
}
