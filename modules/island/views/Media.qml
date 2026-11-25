import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

Item {
    id: root

    readonly property var player: Players.active
    readonly property bool hasLength: Players.length > 0
    readonly property int pad: 24

    function clock(seconds) {
        if (!(seconds >= 0)) return "-:--"
        const s = Math.floor(seconds), m = Math.floor(s / 60)
        return (m >= 60 ? Math.floor(m / 60) + ":" + String(m % 60).padStart(2, "0") : m) + ":" + String(s % 60).padStart(2, "0")
    }

    component MixerButton: Pill {
        kind: "text"
        icon: Config.symbol.mixer
        iconSize: 22
        shortcut: "v"
        onClicked: Engine.open(Engine.View.Mixer)
    }

    Component.onCompleted: Players.watch(true)
    Component.onDestruction: Players.watch(false)

    implicitWidth: player ? 780 : 520
    implicitHeight: (player ? column.implicitHeight : empty.implicitHeight) + 2 * pad

    // clipped to the island's own corners (a notch's top ones are square): unclipped, the blur's square
    // corners stood out past the island's round ones
    ClippingRectangle {
        visible: root.player !== null && backdrop.status === Image.Ready
        anchors.fill: parent
        color: "transparent"
        radius: Config.radius
        topLeftRadius: Config.style === "notch" ? 0 : Config.radius
        topRightRadius: Config.style === "notch" ? 0 : Config.radius

        CoverImage {
            id: backdrop
            source: root.player?.trackArtUrl ?? ""
            sourceSize: Qt.size(192, 192)
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: backdrop
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            saturation: 0.2
            opacity: 0.5
        }
    }

    Column {
        id: empty
        visible: !root.player
        x: root.pad; y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: Config.symbol.media
            title: "Media"
            subtitle: "Nothing is playing"
            onBack: Engine.back()

            MixerButton {}
        }
        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: "music_off"
            size: 48
            color: Config.outline
        }
    }

    Column {
        id: column
        visible: root.player !== null
        x: root.pad; y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: Config.symbol.media
            title: "Now playing"
            subtitle: (root.player?.identity ?? "") + "  ·  " + Audio.label(Audio.sink)
            onBack: Engine.back()

            MixerButton {}
        }

        Row {
            width: parent.width
            spacing: Config.spaceXl

            ClippingRectangle {
                id: art
                width: 240
                height: 240
                radius: Config.cardRadius + 4
                color: Config.tile

                Icon {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    name: "music_note"
                    size: 64
                    color: Config.outline
                }
                CoverImage {
                    id: cover
                    source: root.player?.trackArtUrl ?? ""
                    sourceSize: Qt.size(480, 480)
                }
            }

            Item {
                width: parent.width - art.width - parent.spacing
                height: art.height

                Column {
                    anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: Config.spaceS }
                    spacing: Config.spaceXs

                    Label {
                        width: parent.width
                        text: root.player?.trackTitle || "Unknown title"
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                        font.pixelSize: Config.headline
                        font.weight: Font.DemiBold
                    }
                    Label {
                        width: parent.width
                        text: root.player?.trackArtist || root.player?.trackAlbum || ""
                        elide: Text.ElideRight
                        color: Config.dim
                        font.pixelSize: Config.large + 1
                    }
                }

                Column {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    spacing: Config.spaceL

                    Item {
                        visible: root.hasLength
                        width: parent.width
                        height: 20

                        Label {
                            id: elapsed
                            anchors.verticalCenter: parent.verticalCenter
                            width: 52
                            // while dragging: where the drop would seek to
                            text: root.clock(seekBar.dragging ? seekBar.shownFraction * Players.length : Players.position)
                            color: Config.dim
                            font.features: { "tnum": 1 }
                        }
                        Progress {
                            id: seekBar
                            anchors { left: elapsed.right; right: total.left; verticalCenter: parent.verticalCenter }
                            thickness: 6
                            fraction: root.hasLength ? Players.position / Players.length : 0
                            seekable: Players.canSeek
                            onSeek: f => Players.seek(f)
                        }
                        Label {
                            id: total
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            width: 52
                            horizontalAlignment: Text.AlignRight
                            text: root.clock(Players.length)
                            color: Config.dim
                            font.features: { "tnum": 1 }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 76

                        Pill {
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            kind: "text"
                            icon: "shuffle"
                            iconSize: 24
                            implicitHeight: 52
                            active: Players.shuffle
                            shortcut: "s"
                            enabled: root.player?.shuffleSupported ?? false
                            onClicked: Players.toggleShuffle()
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: Config.spaceL

                            Pill {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "skip_previous"
                                iconSize: 30
                                implicitHeight: 64
                                shortcut: "b"
                                enabled: root.player?.canGoPrevious ?? false
                                onClicked: Players.previous()
                            }
                            // the play button: a rounded square while playing (Material 3's expressive FAB)
                            Pill {
                                anchors.verticalCenter: parent.verticalCenter
                                kind: "filled"
                                icon: Players.playing ? "pause" : "play_arrow"
                                iconSize: 36
                                implicitHeight: 76
                                implicitWidth: 96
                                radius: Players.playing ? 24 : 38
                                shortcut: "p"
                                focus: true                    // Enter/Space toggle playback straight away
                                enabled: Players.canToggle
                                onClicked: Players.toggle()
                                Behavior on radius { NumberAnimation { duration: Config.durationMedium; easing.type: Easing.OutCubic } }
                            }
                            Pill {
                                anchors.verticalCenter: parent.verticalCenter
                                icon: "skip_next"
                                iconSize: 30
                                implicitHeight: 64
                                shortcut: "n"
                                enabled: root.player?.canGoNext ?? false
                                onClicked: Players.next()
                            }
                        }

                        Pill {
                            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                            kind: "text"
                            icon: Players.loop === "track" ? "repeat_one" : "repeat"
                            iconSize: 24
                            implicitHeight: 52
                            active: Players.loop !== "none"
                            shortcut: "r"
                            enabled: root.player?.loopSupported ?? false
                            onClicked: Players.cycleLoop()
                        }
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: Config.spaceXl

            Column {
                visible: Audio.sinks.length > 0
                width: Players.list.length > 1 ? (parent.width - parent.spacing) / 2 : parent.width
                spacing: Config.spaceS

                Label {
                    leftPadding: Config.spaceXs
                    bottomPadding: Config.spaceXs
                    text: "Output"
                    font.pixelSize: Config.large
                    font.weight: Font.Medium
                }
                Repeater {
                    model: Audio.sinks.slice(0, 4)

                    ListEntry {
                        id: output
                        required property var modelData
                        readonly property int level: Audio.level(modelData)
                        readonly property bool silent: Audio.isMuted(modelData)
                        function step(by) { Audio.setLevel(modelData, level + 5 * by) }

                        width: parent.width
                        icon: Audio.glyph(modelData)
                        title: Audio.label(modelData)
                        active: modelData === Audio.sink
                        wheelable: true
                        onClicked: Audio.setSink(modelData)
                        onScrolled: by => step(by)
                        Keys.onPressed: event => {
                            const t = event.text
                            if (t === "+" || t === "=") step(1)
                            else if (t === "-") step(-1)
                            else { event.accepted = false; return }
                            Engine.key()
                        }

                        Progress {
                            Layout.preferredWidth: 72
                            Layout.alignment: Qt.AlignVCenter
                            fraction: output.silent ? 0 : output.level / 100
                        }
                        Label {
                            Layout.preferredWidth: 44
                            Layout.alignment: Qt.AlignVCenter
                            horizontalAlignment: Text.AlignRight
                            text: output.silent ? "Muted" : output.level + "%"
                            color: output.active ? Config.secondaryInk : Config.dim
                            font.pixelSize: Config.small + 1
                            font.features: { "tnum": 1 }
                        }
                    }
                }
            }

            Column {
                visible: Players.list.length > 1
                width: (parent.width - parent.spacing) / 2
                spacing: Config.spaceS

                Label {
                    leftPadding: Config.spaceXs
                    bottomPadding: Config.spaceXs
                    text: "Players"
                    font.pixelSize: Config.large
                    font.weight: Font.Medium
                }
                Repeater {
                    model: Players.list

                    ListEntry {
                        id: entry
                        required property var modelData
                        width: parent.width
                        title: modelData.trackTitle || modelData.identity
                        subtitle: (modelData.trackArtist ? modelData.trackArtist + "  ·  " : "") + modelData.identity
                        active: modelData === Players.active
                        lead: Component {
                            ClippingRectangle {
                                width: 44; height: 44; radius: 12
                                color: Config.raised
                                CoverImage {
                                    source: entry.modelData.trackArtUrl ?? ""
                                    sourceSize: Qt.size(88, 88)
                                }
                            }
                        }
                        onClicked: Players.picked = modelData
                    }
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["Space", "play / pause"], ["← →", "seek, on the bar"], ["+ −", "an output's volume"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
