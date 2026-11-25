import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.parts
import qs.modules.services

// Settings: its pages, each a view of its own (SettingsIsland, SettingsGlass, ...), so Back walks them as any
// other view; Advanced has every setting.
Item {
    id: root

    readonly property int pad: 24
    readonly property int colW: 520

    implicitWidth: colW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.colW
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: Config.symbol.settings
            title: "Settings"
            onBack: Engine.back()

            Pill { kind: "text"; icon: Config.symbol.theme; iconSize: 22; shortcut: "t"; onClicked: Engine.open(Engine.View.Theme) }
        }

        ListSection {

            component Category: ListEntry {
                required property int view
                flat: true
                onClicked: Engine.open(view)
                Icon { name: "chevron_right"; size: 22; color: Config.outline }
            }
            Category { focus: true; view: Engine.View.SettingsIsland; icon: "dock_to_bottom"; title: "Island"; subtitle: "Size, shape, hiding, clock"; shortcut: "s" }
            Category { view: Engine.View.SettingsGlass; icon: "blur_on"; title: "Glass and blur"; subtitle: "Opacity, blur, liquid glass, motion"; shortcut: "k" }
            Category { view: Engine.View.SettingsAlerts; icon: "notifications"; title: "Notifications"; subtitle: "Popups, sounds, toasts"; shortcut: "a" }
            Category { view: Engine.View.SettingsEnergy; icon: "bolt"; title: "Energy"; subtitle: "Dim, lock and sleep when idle"; shortcut: "i" }
            Category { view: Engine.View.SettingsLock; icon: "lock"; title: "Lock screen"; subtitle: "Picture, profile"; shortcut: "l" }
        }
        ListSection {
            ListEntry {
                flat: true
                icon: "tune"
                title: "Advanced"
                subtitle: "Every setting, hand-editable"
                shortcut: "v"
                onClicked: Engine.open(Engine.View.Advanced)
                Icon { name: "chevron_right"; size: 22; color: Config.outline }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["⏎", "open"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
