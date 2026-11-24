import QtQuick
import qs.modules.components
import qs.modules.services

// What's being recorded, while it goes on, as MediaCard shows what plays (the same size as its compact
// form): how long so far, Stop (saved, as from anywhere else) and Discard (the file deleted, after a
// second press). A screen recording with the microphone can mute it on the way: it takes the default
// source, which then records silence. No pause: wf-recorder has none, and stopping either recorder's
// process would freeze the video or stall PipeWire for every app.
Rectangle {
    id: root

    property string kind: "screen"           // or "memo"
    readonly property bool screen: kind === "screen"
    readonly property bool withMic: screen && Toggles.recordingMic

    property bool armed: false
    Timer { id: disarm; interval: 3000; onTriggered: root.armed = false }

    implicitWidth: 420
    implicitHeight: 84
    radius: Config.cardRadius
    color: Config.container

    Rectangle {
        id: badge
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        height: 56
        radius: Config.smallRadius
        color: Qt.rgba(Config.recording.r, Config.recording.g, Config.recording.b, 0.16)

        Icon {
            anchors.centerIn: parent
            name: root.screen ? "screen_record" : "mic"
            size: 26
            filled: true
            color: Config.recording
            SequentialAnimation on opacity {
                running: root.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.4; duration: 700 }
                NumberAnimation { to: 1; duration: 700 }
            }
        }
    }

    Column {
        anchors { left: badge.right; leftMargin: 12; right: controls.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 2

        Label {
            width: parent.width
            text: root.armed ? "Discard it?" : root.screen ? "Screen recording" : "Voice memo"
            elide: Text.ElideRight
            font.pixelSize: Config.body + 1
            font.weight: Font.DemiBold
        }
        Label {
            width: parent.width
            text: (root.screen ? Toggles.recordTime : Toggles.memoTime)
                + (root.withMic ? (Audio.micMuted ? "  ·  microphone muted" : "  ·  with the microphone") : "")
            elide: Text.ElideRight
            color: Config.recording
            font.pixelSize: Config.small + 1
            font.weight: Font.DemiBold
            font.features: { "tnum": 1 }
        }
    }

    Row {
        id: controls
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 2

        Pill {
            visible: root.withMic
            kind: "text"
            icon: Audio.micMuted ? "mic_off" : "mic"
            iconSize: 22
            onClicked: Audio.toggleMic()
        }
        Pill {
            kind: root.armed ? "tonal" : "text"
            icon: root.armed ? "delete_forever" : "delete"
            iconSize: 22
            onClicked: {
                if (!root.armed) { root.armed = true; disarm.restart(); return }
                root.armed = false
                if (root.screen) Toggles.discardRecording()
                else Toggles.discardMemo()
            }
        }
        // Stop in the recording's own red; its filled square drawn natively, as Qt's default text
        // renderer garbles filled Material Symbols
        Rectangle {
            width: 44
            height: 44
            radius: 22
            color: Config.state(Config.recording, "white", stopArea.containsMouse, stopArea.pressed)

            Icon {
                anchors.centerIn: parent
                name: "stop"
                size: 22
                filled: true
                color: "white"
                renderType: Text.NativeRendering
            }
            ClickArea {
                id: stopArea
                onClicked: root.screen ? Toggles.record(false, false) : Toggles.voiceMemo(false)
            }
        }
    }
}
