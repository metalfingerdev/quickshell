import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.modules.island
import qs.modules.components
import qs.modules.services

// A tray app as a glass circle: its icon, in one colour unless it needs attention. A click opens its menu
// (or its own action, for an app without one); a right click is its secondary action.
Rectangle {
    id: root

    required property var app
    property int size: 28
    readonly property bool hovered: area.containsMouse
    readonly property bool urgent: app?.status === Status.NeedsAttention
    readonly property bool keyboardSelected: activeFocus && Config.focusVisible

    function activate() {
        if (app?.hasMenu) { Tray.current = app; Engine.open(Engine.View.Tray) }
        else Engine.closeThen(() => app?.activate())
    }
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: app ? Tray.name(app) : ""
    Accessible.onPressAction: activate()

    width: size; height: size; radius: size / 2
    color: Config.state(Config.tile, Config.text, area.containsMouse, area.pressed || keyboardSelected)
    Behavior on color { ColorAnimation { duration: Config.durationFast } }

    IconImage {
        id: image
        anchors.centerIn: parent
        implicitSize: Math.round(root.size * 0.6)
        asynchronous: true
        source: root.app?.icon ?? ""
        layer.enabled: Config.trayMono && !root.urgent
        layer.effect: MultiEffect { saturation: -1 }
    }

    // needs attention: the accent's dot
    Rectangle {
        visible: root.urgent
        anchors { right: parent.right; top: parent.top }
        width: 8; height: 8; radius: 4
        color: Config.primary
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => mouse.button === Qt.RightButton ? root.app?.secondaryActivate() : root.activate()
    }
    FocusRing { on: root.keyboardSelected }
}
