import QtQuick

// The field takes its own keys and reports them as signals, so the view decides what they do, and
// ViewLoader never sees them: key() is for Engine.key(). up() / down() only with `takesArrows`, tab()
// only with `takesTab`; otherwise those keys move focus out of the field as usual. sideways(-1 | 1),
// Left and Right, only with `takesSides` (a grid of results), in place of moving the text cursor. Not
// left() / right(): every Item already has properties by those names (its anchor lines), and a signal
// can't take their place, so `onRight` wouldn't exist and the view using it wouldn't load.
FocusScope {
    id: root

    property alias text: field.text
    property alias field: field
    property string placeholder: "Search"
    property string icon: "search"
    property bool readOnly: false
    property bool takesTab: false
    property bool takesArrows: false
    property bool takesSides: false
    // Ctrl with these keys (Qt.Key_C, ...) goes to control(key) instead of the field: Ctrl+C would
    // copy otherwise, and the field keeps it, so it never reaches the view
    property var controlKeys: []
    property int fieldSize: 16
    default property alias trailing: side.data

    signal key()
    signal accepted()
    signal up()
    signal down()
    signal sideways(int step)
    signal control(int key)
    signal tab(bool backward)
    signal escaped()
    signal backspaceEmpty()
    signal clicked()

    implicitWidth: 400
    implicitHeight: 56

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Config.state(Config.high, Config.text, area.containsMouse && root.readOnly, false)
        border.width: field.activeFocus && !root.readOnly ? 2 : 0
        border.color: Config.primary
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.readOnly ? Qt.PointingHandCursor : Qt.IBeamCursor
        onClicked: root.readOnly ? root.clicked() : field.forceActiveFocus()
    }

    Rectangle {
        id: badge
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        width: root.height - 12
        height: width
        radius: width / 2
        color: Config.primary

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: Math.round(root.height * 0.36)
            color: Config.primaryInk
        }
    }

    TextInput {
        id: field
        anchors { left: badge.right; leftMargin: 12; right: side.left; rightMargin: 10; top: parent.top; bottom: parent.bottom }
        focus: true
        verticalAlignment: TextInput.AlignVCenter
        readOnly: root.readOnly
        activeFocusOnTab: !root.readOnly
        color: Config.text
        selectionColor: Config.secondary
        selectedTextColor: Config.secondaryInk
        font.family: Config.font
        font.pixelSize: root.fieldSize
        clip: true

        Keys.onPressed: event => {
            root.key()
            if ((event.modifiers & Qt.ControlModifier) && root.controlKeys.includes(event.key)) {
                root.control(event.key)
                event.accepted = true
                return
            }
            switch (event.key) {
            case Qt.Key_Return: case Qt.Key_Enter: root.accepted(); break
            case Qt.Key_Up: case Qt.Key_Down:
                if (!root.takesArrows) { event.accepted = false; return }
                if (event.key === Qt.Key_Up) root.up(); else root.down()
                break
            case Qt.Key_Left: case Qt.Key_Right:
                if (!root.takesSides) { event.accepted = false; return }
                root.sideways(event.key === Qt.Key_Left ? -1 : 1)
                break
            case Qt.Key_Escape:  root.escaped(); break
            case Qt.Key_Tab: case Qt.Key_Backtab:
                if (!root.takesTab) { event.accepted = false; return }
                root.tab(event.key === Qt.Key_Backtab); break
            case Qt.Key_Backspace:
                if (text.length > 0) { event.accepted = false; return }
                root.backspaceEmpty(); break
            default: event.accepted = false; return
            }
            event.accepted = true
        }

        Text {
            visible: field.text === ""
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            elide: Text.ElideRight
            text: root.placeholder
            color: Config.dim
            font: field.font
        }
    }

    Row {
        id: side
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 6
    }
}
