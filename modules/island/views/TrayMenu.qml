import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.island
import qs.modules.components
import qs.modules.services

// The tray: every icon (Tray.current null), or one app's menu and its submenus. The menu is drawn here
// instead of as the app's own popup, so the keyboard works in it and the island never loses the
// pointer to another surface, which would restart its countdown under an open menu.
Item {
    id: root

    readonly property int pad: 24
    readonly property var item: Tray.current
    // submenus gone into, deepest last
    property var trail: []
    readonly property var menu: trail.length > 0 ? trail[trail.length - 1] : item?.menu ?? null
    // opened on the list, Back comes back to it rather than to the view before
    property bool fromList: false
    onItemChanged: trail = []
    Component.onDestruction: Tray.current = null

    implicitWidth: 560
    implicitHeight: column.implicitHeight + 2 * pad

    function back() {
        Engine.key()
        if (trail.length > 0) trail = trail.slice(0, -1)
        else if (item && fromList) Tray.current = null
        else Engine.back()
    }
    function choose(entry) {
        if (entry.hasChildren) { Engine.key(); trail = trail.concat([entry]); return }
        // now, while the opener still holds the menu: after closing, the view and the menu are gone
        entry.triggered()
        Engine.close()
    }
    // A window the app raises can't take the keyboard while the island holds it, hence closeThen.
    function run(app) { Engine.closeThen(() => app.activate()) }
    function open(app) {
        if (!app.hasMenu) { run(app); return }
        fromList = true
        Tray.current = app
    }
    // "_Quit" and "&Quit": the mnemonic's marker isn't text
    function plain(text) { return String(text ?? "").replace(/[_&](?=\S)/g, "") }
    function glyph(entry) {
        if (entry.buttonType === QsMenuButtonType.CheckBox)
            return entry.checkState === Qt.Checked ? "check_box" : "check_box_outline_blank"
        if (entry.buttonType === QsMenuButtonType.RadioButton)
            return entry.checkState === Qt.Checked ? "radio_button_checked" : "radio_button_unchecked"
        return entry.hasChildren ? "chevron_right" : "radio_button_partial"
    }

    QsMenuOpener {
        id: opener
        menu: root.menu
    }
    readonly property int shown: item ? entries.count : Tray.items.length

    // Backspace climbs out of a submenu first; ViewLoader's own Backspace would leave the view
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Backspace) { root.back(); event.accepted = true }
        else event.accepted = false
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: parent.width - 2 * root.pad
        spacing: Config.spaceM

        Header {
            width: parent.width
            icon: root.item ? "" : "widgets"
            title: !root.item ? "Tray"
                 : root.trail.length > 0 ? root.plain(root.trail[root.trail.length - 1].text) : Tray.name(root.item)
            subtitle: !root.item ? (Tray.items.length === 1 ? "1 app" : Tray.items.length + " apps")
                    : root.trail.length > 0 ? Tray.name(root.item) : root.item.tooltipDescription
            onBack: root.back()

            Pill {
                visible: root.item !== null && !root.item.onlyMenu
                implicitHeight: 48
                icon: "open_in_new"
                text: "Open"
                shortcut: "o"
                onClicked: root.run(root.item)
            }
            Pill {
                visible: root.item !== null
                implicitHeight: 48
                kind: "text"
                icon: "visibility_off"
                shortcut: "h"
                Accessible.name: "Hide from the island"
                onClicked: { Tray.hide(root.item); Tray.current = null }
            }
        }

        ScrollList {
            width: parent.width
            visible: root.shown > 0
            maxHeight: 7 * 54 + 14
            spacing: Config.spaceHair

            Repeater {
                model: root.item ? [] : Tray.items

                ListEntry {
                    required property var modelData
                    required property int index

                    width: parent.width
                    focus: index === 0
                    title: Tray.name(modelData)
                    subtitle: modelData.tooltipDescription
                    trailing: modelData.hasMenu ? "›" : ""
                    lead: Component {
                        IconImage { implicitSize: 28; asynchronous: true; source: modelData.icon }
                    }
                    onClicked: root.open(modelData)
                }
            }

            Repeater {
                id: entries
                model: root.item ? opener.children : []

                Item {
                    id: slot
                    required property var modelData
                    required property int index

                    width: parent.width
                    height: modelData.isSeparator ? Config.spaceM : entry.height

                    Rectangle {
                        visible: slot.modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        x: Config.spaceM
                        width: parent.width - 2 * Config.spaceM
                        height: 1
                        color: Config.divider
                    }

                    ListEntry {
                        id: entry
                        visible: !slot.modelData.isSeparator
                        activeFocusOnTab: visible && enabled
                        focus: slot.index === 0
                        width: parent.width
                        enabled: slot.modelData.enabled
                        opacity: enabled ? 1 : 0.38
                        icon: root.glyph(slot.modelData)
                        active: slot.modelData.checkState === Qt.Checked
                        title: root.plain(slot.modelData.text)
                        trailing: slot.modelData.hasChildren ? "›" : ""
                        lead: slot.modelData.icon !== "" && slot.modelData.buttonType === QsMenuButtonType.None ? picture : null
                        onClicked: root.choose(slot.modelData)

                        property Component picture: Component {
                            IconImage { implicitSize: 24; asynchronous: true; source: slot.modelData.icon }
                        }
                    }
                }
            }
        }

        EmptyState {
            width: parent.width
            visible: root.shown === 0
            icon: "widgets"
            title: root.item ? "This menu is empty" : "Nothing in the tray"
            hint: root.item ? "The app has nothing in its menu right now."
                            : Tray.hidden !== "" ? "Apps you hid stay hidden; Settings shows them again."
                            : "Apps that put an icon in the tray show here."
            actionText: root.item && !root.item.onlyMenu ? "Open the app" : ""
            onAction: root.run(root.item)
        }

        KeyHints {
            width: parent.width
            keys: root.item ? [["⏎", "choose"], ["⌫", "back"]] : [["⏎", "menu"], ["Esc", "close"]]
        }
    }
}
