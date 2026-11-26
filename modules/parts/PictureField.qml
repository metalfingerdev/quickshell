import QtQuick
import qs.modules.island
import qs.modules.components

// A picture's path as a text field: `chosen` fires on Enter and on leaving the field. It takes its keys
// itself (ViewLoader never sees them) and gives Escape and Backspace back what they mean in a view.
SearchBar {
    id: root

    property string value: ""
    signal chosen(string path)

    width: parent.width
    height: 52
    fieldSize: Config.body
    text: value
    onKey: Engine.key()
    onEscaped: Engine.close()
    onBackspaceEmpty: Engine.back()
    onAccepted: chosen(text.trim())

    Connections {
        target: root.field
        function onActiveFocusChanged() { if (!root.field.activeFocus && root.text.trim() !== root.value) root.chosen(root.text.trim()) }
    }
}
