import QtQuick

// A pop-up list in the view, after Apple's: checkmarks, destructive items in red, separators, a shortcut
// at the right. The caller places it and sets `open`; it closes itself on a choice or Escape, and
// reports the choice as a key. Each item: { key, label, icon, checked, destructive, enabled, separator, hint }.
FocusScope {
    id: root

    property var items: []
    property bool open: false
    property int rowHeight: 40
    signal chosen(string key)

    visible: open
    focus: open
    z: 10
    implicitWidth: 240
    implicitHeight: list.implicitHeight + 2 * Config.spaceXs

    function close() { open = false }
    Keys.onEscapePressed: event => { close(); event.accepted = true }

    // focus leaving (a click elsewhere, Tab past the last item) closes it
    onActiveFocusChanged: if (!activeFocus && open) close()

    Rectangle {
        anchors.fill: parent
        radius: Config.innerRadius + 4
        color: Config.raised
    }

    Column {
        id: list
        x: Config.spaceXs; y: Config.spaceXs
        width: parent.width - 2 * Config.spaceXs

        Repeater {
            model: root.items

            Item {
                id: row
                required property var modelData
                readonly property bool separator: modelData.separator === true
                width: parent.width
                height: separator ? Config.spaceS : root.rowHeight

                Rectangle {
                    visible: row.separator
                    anchors.verticalCenter: parent.verticalCenter
                    x: Config.spaceM; width: parent.width - 2 * Config.spaceM; height: 1
                    color: Config.raised
                }

                Rectangle {
                    id: hit
                    visible: !row.separator
                    anchors.fill: parent
                    radius: Config.innerRadius
                    activeFocusOnTab: true
                    readonly property bool lit: area.containsMouse || (activeFocus && Config.focusVisible)
                    color: lit ? Config.primary : "transparent"
                    opacity: row.modelData.enabled === false ? 0.38 : 1
                    function activate() { if (row.modelData.enabled !== false) { root.chosen(row.modelData.key); root.close() } }
                    Accessible.role: Accessible.MenuItem
                    Accessible.name: row.modelData.label ?? ""
                    Accessible.checked: row.modelData.checked === true
                    Accessible.onPressAction: activate()

                    readonly property color ink: lit ? Config.primaryInk : row.modelData.destructive ? Config.bad : Config.text

                    Icon {
                        x: Config.spaceM
                        anchors.verticalCenter: parent.verticalCenter
                        name: row.modelData.checked ? "check" : row.modelData.icon ?? ""
                        size: 18
                        color: hit.ink
                    }
                    Label {
                        x: Config.spaceM + 28
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - x - Config.spaceM - (hint.visible ? hint.implicitWidth + Config.spaceM : 0)
                        text: row.modelData.label ?? ""
                        elide: Text.ElideRight
                        color: hit.ink
                    }
                    Label {
                        id: hint
                        visible: text !== ""
                        anchors { right: parent.right; rightMargin: Config.spaceM; verticalCenter: parent.verticalCenter }
                        text: row.modelData.hint ?? ""
                        color: hit.lit ? Config.primaryInk : Config.dim
                        font.pixelSize: Config.small
                    }
                    ClickArea { id: area; onClicked: hit.activate() }
                    FocusRing { on: hit.activeFocus && Config.focusVisible }
                }
            }
        }
    }
}
