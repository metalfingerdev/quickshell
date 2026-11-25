import QtQuick
import Quickshell.Widgets

// A whole scheme as a circle, the way Android shows wallpaper colours: the accent across the top, its
// secondary bottom left, and the surface bottom right, tinted as the scheme tints it, so two variants of
// one accent still look apart. `palette` is a Config scheme (Config.wallpaperScheme, Config.palettes).
Item {
    id: root

    property var palette: null
    property bool chosen: false
    property bool keyboardSelected: activeFocus && Config.focusVisible
    readonly property bool hovered: area.containsMouse
    signal picked()

    activeFocusOnTab: true
    function activate() { picked() }
    Accessible.role: Accessible.RadioButton
    Accessible.name: palette?.label ?? palette?.name ?? ""
    Accessible.checked: chosen
    Accessible.onPressAction: activate()

    implicitWidth: 48
    implicitHeight: 48
    scale: hovered && !area.pressed ? 1.08 : 1
    Behavior on scale { NumberAnimation { duration: Config.durationFast; easing.type: Easing.OutCubic } }

    ClippingRectangle {
        anchors { fill: parent; margins: root.chosen ? 5 : 0 }
        radius: width / 2
        color: root.palette?.high ?? Config.raised
        border.width: 1
        border.color: Qt.rgba(Config.outline.r, Config.outline.g, Config.outline.b, 0.5)

        Rectangle {
            width: parent.width
            height: parent.height / 2
            color: root.palette?.primary ?? Config.primary
        }
        Rectangle {
            y: parent.height / 2
            width: parent.width / 2
            height: parent.height / 2
            color: root.palette?.secondary ?? Config.secondary
        }
    }

    // the one in use: a ring round it, with a gap
    Rectangle {
        visible: root.chosen
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: Config.primary
    }

    ClickArea {
        id: area
        onClicked: root.picked()
    }

    FocusRing { on: root.keyboardSelected }
}
