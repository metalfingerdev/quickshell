import QtQuick

Rectangle {
    id: root

    property bool current: false
    property color tint: "transparent"
    property int padding: Config.spaceL
    property string shortcut: ""
    property bool keyboardSelected: activeFocus && Config.focusVisible
    readonly property bool hovered: area.containsMouse
    default property alias content: inner.data
    signal clicked()

    activeFocusOnTab: true
    function activate() { clicked() }
    // a tile is whatever is put in it, so the view names it (Accessible.name)
    Accessible.role: Accessible.Button
    Accessible.onPressAction: activate()

    radius: Config.cardRadius
    color: Config.state(tint.a > 0 ? tint : Config.fill3, Config.text, area.containsMouse, area.pressed || keyboardSelected)
    border.width: current ? 2 : 0
    border.color: Config.primary
    Behavior on color { ColorAnimation { duration: Config.durationFast } }

    ClickArea {
        id: area
        onClicked: root.clicked()
    }

    Item {
        id: inner
        anchors { fill: parent; margins: root.padding }
    }

    FocusRing { on: root.keyboardSelected }
    KeyBadge { key: root.shortcut }
}
