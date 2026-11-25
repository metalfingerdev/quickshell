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
    readonly property int shown: item ? entries.count : Tray.all.length

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
            icon: root.item ? "menu_open" : "widgets"
            title: !root.item ? "Tray"
                 : root.trail.length > 0 ? root.plain(root.trail[root.trail.length - 1].text) : Tray.name(root.item)
            subtitle: !root.item ? (Tray.all.length === 1 ? "1 app" : Tray.all.length + " apps")
                                   + (Tray.all.length > Tray.items.length ? "  ·  " + (Tray.all.length - Tray.items.length) + " hidden" : "")
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
                readonly property bool hiding: root.item !== null && Tray.isHidden(root.item)
                icon: hiding ? "visibility" : "visibility_off"
                shortcut: "h"
                Accessible.name: hiding ? "Show in the island" : "Hide from the island"
                onClicked: { if (hiding) Tray.show(root.item); else Tray.hide(root.item); Tray.current = null }
            }
        }

        ScrollList {
            width: parent.width
            visible: root.shown > 0
            maxHeight: 7 * 56 + 14
            spacing: Config.spaceXs

            Repeater {
                model: root.item ? [] : Tray.all

                ListEntry {
                    id: appRow
                    required property var modelData
                    required property int index
                    readonly property bool hiding: Tray.isHidden(modelData)

                    width: parent.width
                    filled: true
                    focus: index === 0
                    opacity: hiding ? 0.6 : 1
                    title: Tray.name(modelData)
                    subtitle: hiding ? "Hidden from the island" : modelData.tooltipDescription
                    lead: Component {
                        IconImage { implicitSize: 28; asynchronous: true; source: modelData.icon }
                    }
                    onClicked: root.open(modelData)

                    // a hidden one comes back from here, where it is still listed
                    Pill {
                        visible: appRow.hiding
                        implicitHeight: 36
                        kind: "tonal"
                        icon: "visibility"
                        text: "Show"
                        activeFocusOnTab: false
                        onClicked: Tray.show(modelData)
                    }
                    Icon { visible: modelData.hasMenu; name: "chevron_right"; color: Config.dim }
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
                    // a separator is a wider gap between the tiles, not a line across one
                    height: modelData.isSeparator ? Config.spaceS : entry.height

                    ListEntry {
                        id: entry
                        visible: !slot.modelData.isSeparator
                        activeFocusOnTab: visible && enabled
                        focus: slot.index === 0
                        width: parent.width
                        filled: true
                        enabled: slot.modelData.enabled
                        opacity: enabled ? 1 : 0.38
                        icon: root.glyph(slot.modelData)
                        active: slot.modelData.checkState === Qt.Checked
                        title: root.plain(slot.modelData.text)
                        lead: slot.modelData.icon !== "" && slot.modelData.buttonType === QsMenuButtonType.None ? picture : null
                        onClicked: root.choose(slot.modelData)

                        property Component picture: Component {
                            IconImage { implicitSize: 24; asynchronous: true; source: slot.modelData.icon }
                        }

                        Icon { visible: slot.modelData.hasChildren; name: "chevron_right"; color: Config.dim }
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
                            : Tray.hidden !== "" ? "Apps you hid are listed here when they run, with Show to bring them back."
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
