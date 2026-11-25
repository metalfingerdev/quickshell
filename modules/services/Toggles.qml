pragma Singleton

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.components

// Each one needs a program; `has(tool)` says whether it's installed, and the dashboard only shows
// the tiles that can work.
Singleton {
    id: root

    property var tools: []
    function has(tool) { return tools.includes(tool) }

    Process {
        running: true
        command: ["sh", "-c", "for t in systemd-inhibit hyprsunset wf-recorder powerprofilesctl grimblast gsettings notify-send xdg-open uwsm pw-play hyprpicker wtype pw-record; "
                            + "do command -v \"$t\" >/dev/null 2>&1 && echo \"$t\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.tools = text.split("\n").filter(t => t !== "")
                root.readProfile()
            }
        }
    }

    property bool caffeine: false
    Process {
        running: root.caffeine && root.has("systemd-inhibit")
        command: ["systemd-inhibit", "--what=idle", "--who=Island", "--why=Caffeine", "--mode=block", "sleep", "infinity"]
    }
    // Kept through a restart of the shell (a crash, Super+R), so the screen doesn't start to dim
    // behind your back; in the runtime folder, so the next session starts without it.
    FileView {
        id: caffeineFile
        path: (Quickshell.env("XDG_RUNTIME_DIR") ?? "") !== "" ? Quickshell.env("XDG_RUNTIME_DIR") + "/island-caffeine" : ""
        printErrors: false
        onLoaded: root.caffeine = text().trim() === "on"
    }
    onCaffeineChanged: if (caffeineFile.path !== "") caffeineFile.setText(caffeine ? "on\n" : "")

    property bool nightLight: false
    property int warmth: 4500
    Process {
        running: root.nightLight && root.has("hyprsunset")
        command: ["hyprsunset", "-t", String(root.warmth)]
    }

    property Store store: Store {
        category: "toggles"
        property alias nightLight: root.nightLight
        property alias warmth: root.warmth
    }

    readonly property bool airplane: !Net.wifiEnabled && (!Bluez.available || !Bluez.enabled)
    function setAirplane(on) { Net.setWifi(!on); Bluez.setEnabled(!on) }

    readonly property bool recording: recorder.running
    property string recordFile: ""
    property int recordSeconds: 0
    readonly property string recordTime: Math.floor(recordSeconds / 60) + ":" + String(recordSeconds % 60).padStart(2, "0")

    // `mic`: the microphone goes in too (wf-recorder --audio: the default source)
    property bool recordingMic: false
    function record(on, mic) {
        if (on && !recorder.running && has("wf-recorder")) {
            const dir = StandardPaths.writableLocation(StandardPaths.MoviesLocation).toString().replace("file://", "") + "/Recordings"
            const output = Hyprland.focusedMonitor?.name ?? ""
            recordFile = dir + "/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".mp4"
            recordSeconds = 0
            recordingMic = !!mic
            recorder.command = ["sh", "-c", "mkdir -p \"$1\" && shift && exec wf-recorder -y \"$@\"", "sh", dir]
                .concat(output ? ["-o", output] : []).concat(mic ? ["--audio"] : []).concat(["-f", recordFile])
            recorder.running = true
        } else if (!on && recorder.running) {
            recorder.signal(2)                              // SIGINT: wf-recorder finishes the file
        }
    }
    // Stopped the same way, and the finished file deleted once wf-recorder lets go of it.
    property bool recordDiscard: false
    function discardRecording() {
        if (!recorder.running) return
        recordDiscard = true
        recorder.signal(2)
    }
    Process {
        id: recorder
        onExited: (code, status) => {
            if (root.recordDiscard && root.recordFile !== "")
                Quickshell.execDetached(["rm", "-f", "--", root.recordFile])
            else if (root.recordFile !== "" && root.has("notify-send"))
                Quickshell.execDetached(["notify-send", "-a", "Screen recorder", "-i", "media-record", "Recording saved", root.recordFile])
            root.recordFile = ""
            root.recordDiscard = false
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.recordSeconds++
    }

    // A voice memo: the microphone alone (pw-record), into Music/Voice memos as FLAC. Stopped with
    // SIGINT, so the file is finished; a notification says where it went.
    readonly property bool memoRecording: memo.running
    property string memoFile: ""
    property int memoSeconds: 0
    readonly property string memoTime: Math.floor(memoSeconds / 60) + ":" + String(memoSeconds % 60).padStart(2, "0")
    function voiceMemo(on) {
        if (on && !memo.running && has("pw-record")) {
            const dir = StandardPaths.writableLocation(StandardPaths.MusicLocation).toString().replace("file://", "") + "/Voice memos"
            memoFile = dir + "/" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".flac"
            memoSeconds = 0
            memo.command = ["sh", "-c", "mkdir -p \"$1\" && exec pw-record \"$2\"", "sh", dir, memoFile]
            memo.running = true
        } else if (!on && memo.running) {
            memo.signal(2)
        }
    }
    property bool memoDiscard: false
    function discardMemo() {
        if (!memo.running) return
        memoDiscard = true
        memo.signal(2)
    }
    Process {
        id: memo
        onExited: {
            if (root.memoDiscard && root.memoFile !== "")
                Quickshell.execDetached(["rm", "-f", "--", root.memoFile])
            else if (root.memoFile !== "" && root.has("notify-send"))
                Quickshell.execDetached(["notify-send", "-a", "Voice memo", "-i", "audio-input-microphone", "Voice memo saved", root.memoFile])
            root.memoDiscard = false
            root.memoFile = ""
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.memoRecording
        onTriggered: root.memoSeconds++
    }

    // Types `text` into the window that has the keyboard (wtype), as if from the keyboard: the
    // launcher's emoji and its clipboard. After a moment, since the island has only just let go of it.
    function typeText(text) {
        if (text && has("wtype")) Quickshell.execDetached(["sh", "-c", "sleep 0.15; exec wtype -- \"$1\"", "sh", text])
    }

    IpcHandler {
        target: "record"

        function screen(mic: bool): void { root.record(!root.recording, mic) }
        function memo(): void            { root.voiceMemo(!root.memoRecording) }
        function status(): string {
            return JSON.stringify({ screen: root.recording, mic: root.recording && root.recordingMic, memo: root.memoRecording,
                                    time: root.recording ? root.recordTime : root.memoRecording ? root.memoTime : "" })
        }
    }

    property string profile: ""
    readonly property var profiles: [
        { key: "power-saver", label: "Saver",       icon: "eco" },
        { key: "balanced",    label: "Balanced",    icon: "balance" },
        { key: "performance", label: "Performance", icon: "speed" }
    ]
    function readProfile() { if (has("powerprofilesctl")) profileGet.running = true }
    function setProfile(p) {
        if (!has("powerprofilesctl")) return
        profile = p
        profileSet.command = ["powerprofilesctl", "set", p]
        profileSet.running = true
    }
    Process {
        id: profileGet
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector { onStreamFinished: root.profile = text.trim() }
    }
    Process { id: profileSet; onExited: root.readProfile() }

    function screenshot() {
        if (!has("grimblast")) return
        Quickshell.execDetached(["sh", "-c", "sleep 0.4; d=\"$HOME/Pictures/Screenshots\"; mkdir -p \"$d\"; "
                                           + "exec grimblast --notify copysave area \"$d/$(date +%s).png\""])
    }
    // A colour from anywhere on the screen (hyprpicker: the zoom lens, a click), as "#rrggbb", or ""
    // if it was left with Escape. A signal, not a callback: whoever asked may be gone by then (a view).
    // It starts after a moment, as the screenshot does, so the island has gone from what it freezes.
    // Where it goes is a string, as the asker may be gone: "copy" (the clipboard), "accent", "role:dark|light:<role>", "hg:<windows|island>:
    // <shared|dark|light>:<key>", "hl:<table>:<key>" or "pref:<settings key>". pickBack is how the view that
    // asked finds its place again when it comes back.
    signal colourPicked(string colour)
    property string pickTarget: "accent"
    property string pickBack: ""
    property int pickView: -1
    function pickColour(target, view) {
        if (!has("hyprpicker") || picker.running) return
        pickTarget = target ?? "accent"
        pickView = view ?? -1
        picker.running = true
    }
    Process {
        id: picker
        command: ["sh", "-c", "sleep 0.4; exec hyprpicker --no-fancy --quiet --format=hex"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.match(/#[0-9a-fA-F]{6}/)
                root.colourPicked(found ? found[0].toLowerCase() : "")
            }
        }
    }

    function colorScheme(dark) {
        if (has("gsettings"))
            Quickshell.execDetached(["gsettings", "set", "org.gnome.desktop.interface", "color-scheme", dark ? "prefer-dark" : "prefer-light"])
    }
    function open(path) { if (path) launch(["xdg-open", path]) }

    // An app the shell starts goes in a scope of its own (uwsm app), not in the shell's service:
    // restarting the shell (a crash, Super+R) would otherwise close it, and the session ends it
    // properly when it ends. A desktop entry goes by its id: launch(["firefox.desktop"]).
    function launch(command, dir) {
        const line = has("uwsm") ? ["uwsm", "app", "--"].concat(command) : command
        Quickshell.execDetached(dir ? { command: line, workingDirectory: dir } : line)
    }
}
