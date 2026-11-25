import QtQuick
import Quickshell
import qs.modules.island
import qs.modules.components
import qs.modules.services

// While a panel is open the list keeps its order, so nothing moves under you.
Item {
    id: root

    readonly property int pad: 24
    readonly property int tileH: 72
    readonly property int maxRows: 4

    property var selected: null
    property bool details: false
    // the list's order when that panel opened; networks that vanish since drop out, new ones wait
    property var frozen: []
    readonly property var shown: selected ? frozen.filter(n => Net.networks.includes(n)) : Net.networks
    readonly property bool asking: selected !== null && !selected.connected
    readonly property bool connecting: selected !== null && (Net.attempt === selected || Net.busy(selected))

    function open(n) { frozen = Net.networks.slice(); selected = n }
    function close()  { selected = null }

    function choose(n) {
        if (selected === n) { close(); return }
        if (n.connected || Net.needsPassword(n)) { open(n); return }
        close()
        if (!Net.busy(n)) Net.connect(n)
    }
    function status(n) {
        if (Net.attempt === n || Net.busy(n)) return n.connected ? "Disconnecting…" : "Connecting…"
        if (n.connected) return "Connected"
        return (n.known ? "Saved" : Net.secured(n) ? "Secured" : "Open")
    }

    // the open network came up (password panel) or went down (actions panel): that panel is done
    Connections {
        target: root.selected
        function onConnectedChanged() { root.close() }
    }
    // focus the field as soon as it appears, and again after a failed try
    onAskingChanged: if (asking) password.forceActiveFocus()
    onConnectingChanged: if (asking && !connecting) password.forceActiveFocus()

    Component.onCompleted: { Net.scan(true); Net.readDetails() }
    Component.onDestruction: Net.scan(false)

    // Escape closes the panel first (the field has its own); otherwise it goes on to "back"
    Keys.onEscapePressed: event => { if (root.selected) { root.close(); Engine.key() } else event.accepted = false }

    implicitWidth: 720
    implicitHeight: column.implicitHeight + 2 * pad

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: "language"
            title: "Internet"
            subtitle: Net.attempt ? "Connecting to " + Net.attempt.name + "…" : Net.summary
            onBack: Engine.back()
        }

        ListSection {
            ListEntry {
                flat: true
                focus: !Net.wifiEnabled || Net.networks.length === 0
                lit: Net.wifiEnabled
                icon: Net.wifiEnabled ? "wifi" : "wifi_off"
                title: "Wi-Fi"
                subtitle: Net.wifiBlocked ? "Blocked by a hardware switch or rfkill"
                        : !Net.wifiEnabled ? "Off" : Net.current ? Net.current.name : "On"
                shortcut: "w"
                enabled: Net.available && !Net.wifiBlocked
                onClicked: Net.setWifi(!Net.wifiEnabled)
            }
            ListEntry {
                flat: true
                visible: Net.ethernet
                height: visible ? implicitHeight : 0
                activeFocusOnTab: false
                lit: Net.ethernet
                icon: "lan"
                title: "Ethernet"
                subtitle: Net.linkSpeed > 0 ? "Connected  ·  " + Net.linkSpeed + " Mb/s" : "Connected"
            }
        }

        Label {
            visible: text !== ""
            width: parent.width
            topPadding: Config.spaceS
            bottomPadding: Config.spaceS
            horizontalAlignment: Text.AlignHCenter
            text: !Net.available ? "NetworkManager isn't running"
                : Net.wifi === null ? "No Wi-Fi device"
                : !Net.wifiEnabled ? "Turn Wi-Fi on to see networks"
                : Net.networks.length === 0 ? "Searching…" : ""
            color: Config.dim
        }

        // known networks first, as System Settings has them; each row opens the panel below
        ScrollList {
            id: list
            visible: Net.wifiEnabled && root.shown.length > 0
            width: parent.width
            maxHeight: Math.min(6 * 68 + 2 * 48 + 2 * inset, Engine.room - 420)

            Column {
                width: list.innerWidth
                spacing: Config.spaceM

                component NetworkRow: ListEntry {
                    id: row
                    required property var net
                    required property int number
                    flat: true
                    focus: number === 0
                    lit: net.connected
                    icon: Net.glyph(net.signalStrength)
                    title: net.name
                    subtitle: root.status(net)
                    shortcut: number < 9 ? String(number + 1) : ""
                    active: root.selected === net
                    onClicked: root.choose(net)

                    Icon { visible: net.connected; name: "check"; size: 20; color: Config.primary }
                    Icon { visible: Net.secured(net); name: "lock"; size: 16; color: Config.dim }
                }

                ListSection {
                    title: "My networks"
                    visible: mine.count > 0
                    Repeater {
                        id: mine
                        model: ScriptModel { values: Net.wifiEnabled ? root.shown.filter(n => n.known || n.connected) : []; objectProp: "name" }
                        NetworkRow { required property var modelData; required property int index; net: modelData; number: index }
                    }
                }
                ListSection {
                    title: "Other networks"
                    visible: other.count > 0
                    Repeater {
                        id: other
                        model: ScriptModel { values: Net.wifiEnabled ? root.shown.filter(n => !(n.known || n.connected)) : []; objectProp: "name" }
                        NetworkRow { required property var modelData; required property int index; net: modelData; number: index + mine.count }
                    }
                }
            }
        }

        Rectangle {
            visible: root.selected !== null
            width: parent.width
            height: panel.implicitHeight + 32
            radius: Config.cardRadius
            color: Config.tile

            Column {
                id: panel
                x: 16; y: 16
                width: parent.width - 32
                spacing: Config.spaceM

                Label {
                    leftPadding: Config.spaceXs
                    text: !root.selected ? "" : root.asking ? "Connect to " + root.selected.name : root.selected.name
                    font.pixelSize: Config.large
                    font.weight: Font.Medium
                }

                Row {
                    visible: root.asking
                    width: parent.width
                    spacing: Config.spaceM

                    Rectangle {
                        width: parent.width - join.width - cancel.width - 2 * parent.spacing
                        height: 52
                        radius: height / 2
                        color: Config.raised
                        border.width: password.activeFocus ? 2 : 0
                        border.color: Config.primary

                        TextInput {
                            id: password
                            anchors { fill: parent; leftMargin: Config.spaceXl; rightMargin: Config.spaceXl }
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            enabled: !root.connecting
                            color: Config.text
                            font.family: Config.font
                            font.pixelSize: Config.large
                            clip: true

                            // the field accepts its keys, so ViewLoader never sees them: report them here
                            Keys.onPressed: event => { Engine.key(); event.accepted = false }
                            Keys.onReturnPressed: join.activate()
                            Keys.onEnterPressed:  join.activate()
                            Keys.onEscapePressed: root.close()

                            Text {
                                visible: password.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.connecting ? "Connecting…" : "Password"
                                color: Config.dim
                                font: password.font
                            }
                        }
                    }
                    Pill {
                        id: join
                        implicitHeight: 52
                        kind: "filled"
                        text: root.connecting ? "Connecting…" : "Connect"
                        enabled: password.text.length >= 8 && !root.connecting      // WPA: 8..63 characters
                        onClicked: {
                            Net.connect(root.selected, password.text)
                            password.text = ""
                        }
                    }
                    Pill {
                        id: cancel
                        implicitHeight: 52
                        kind: "text"
                        text: "Cancel"
                        onClicked: root.close()
                    }
                }

                Row {
                    visible: root.selected !== null && !root.asking
                    spacing: Config.spaceM

                    Pill {
                        implicitHeight: 52
                        icon: "link_off"
                        text: "Disconnect"
                        shortcut: "x"
                        onClicked: Net.disconnect(root.selected)
                    }
                    Pill {
                        implicitHeight: 52
                        icon: "delete"
                        text: "Forget"
                        shortcut: "f"
                        onClicked: { Net.forget(root.selected); root.close() }
                    }
                    Pill {
                        implicitHeight: 52
                        kind: "text"
                        text: "Cancel"
                        onClicked: root.close()
                    }
                }
            }
        }

        // Noctalia's info, out of the way: the row opens it, and a value copies with a click
        ListEntry {
            visible: Net.details.length > 0
            width: parent.width
            filled: true
            icon: "info"
            title: "Details"
            subtitle: Net.details.map(d => d.device + "  " + d.facts[0][1].split("/")[0]).join("  ·  ")
            shortcut: "i"
            onClicked: root.details = !root.details

            Icon { name: root.details ? "expand_less" : "expand_more"; size: 22; color: Config.dim }
        }
        Repeater {
            model: root.details ? Net.details : []

            Rectangle {
                id: card
                required property var modelData
                width: parent.width
                height: facts.implicitHeight + 2 * Config.spaceM
                radius: Config.innerRadius + 4
                color: Config.tile

                Column {
                    id: facts
                    x: Config.spaceL
                    y: Config.spaceM
                    width: parent.width - 2 * Config.spaceL

                    SectionLabel { text: card.modelData.device + (card.modelData.connection ? "  ·  " + card.modelData.connection : "") }
                    Repeater {
                        model: card.modelData.facts

                        Item {
                            id: fact
                            required property var modelData
                            width: facts.width
                            height: 32
                            activeFocusOnTab: true
                            function activate() { Toggles.launch(["wl-copy", "--", fact.modelData[1]]); done.restart() }
                            Accessible.role: Accessible.Button
                            Accessible.name: "Copy " + fact.modelData[0]
                            Accessible.onPressAction: activate()
                            FocusRing { on: fact.activeFocus && Config.focusVisible }

                            Label { anchors.verticalCenter: parent.verticalCenter; width: 4 * Config.spaceXl; text: fact.modelData[0]; color: Config.dim }
                            Label {
                                anchors { left: parent.left; leftMargin: 4 * Config.spaceXl; right: copied.left; verticalCenter: parent.verticalCenter }
                                text: fact.modelData[1]
                                elide: Text.ElideRight
                                font.family: Config.mono
                            }
                            Icon {
                                id: copied
                                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                                visible: copyArea.containsMouse || done.running || fact.activeFocus
                                name: done.running ? "check" : "content_copy"
                                color: done.running ? Config.good : Config.dim
                            }
                            ClickArea {
                                id: copyArea
                                onClicked: fact.activate()
                            }
                            Timer { id: done; interval: 1500 }
                        }
                    }
                }
            }
        }

        Label {
            visible: Net.lastError !== ""
            width: parent.width
            leftPadding: Config.spaceM
            text: Net.lastError
            elide: Text.ElideRight
            color: Config.bad
        }

        KeyHints {
            width: parent.width
            keys: [["1–9", "a network"], ["W", "Wi-Fi on/off"], ["I", "details"], ["⌫", "back"], ["Esc", root.selected ? "close the panel" : "close"]]
        }
    }
}
