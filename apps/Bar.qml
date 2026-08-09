///quickshell/boooo/Bar2.qml
import Quickshell // for PanelWindow
import QtQuick // for Text
import Quickshell.Wayland // for Blur
import Quickshell.Io // for Process
import QtQuick.Layouts // for RowLayout
import Quickshell.Hyprland // for monitor name
import qs.config
import qs.widgets

Scope {
    id: root

    property string openMon: ""
    property string openSurface: ""
    property real openX: -1
    property real openY: -1
    property bool openByMouse: false

    function toggleSurface(mon, surface, anchorX) {
        if (!mon || mon.length === 0) {
            var focused = Hyprland.focusedMonitor
            mon = focused ? focused.name : Quickshell.screens[0].name
        }
        if (openMon === mon && openSurface === surface) {
            openMon = ""
            openSurface = ""
            return
        }
        openMon = mon
        openSurface = surface
        openByMouse = (anchorX !== undefined)
        openX = anchorX !== undefined ? anchorX : 0
    }

    function close() {
        openMon = ""
        openSurface = ""
    }

    IpcHandler {
        target: "bar"
        function notif(mon: string): void  { toggleSurface(mon, "notif") }
        function clock(mon: string): void  { toggleSurface(mon, "clock") }
        function launch(mon: string): void { toggleSurface(mon, "launch") }
        function network(mon: string): void{ toggleSurface(mon, "network") }
        function bluetooth(mon: string): void { toggleSurface(mon, "bluetooth") }
        function volume(mon: string): void { toggleSurface(mon, "volume") }
        function player(mon: string): void { toggleSurface(mon, "player") }
        function hide(): void              { close() }
    }

    Component.onCompleted: {
        Hyprland.refreshMonitors()
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: reserve
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 64
            color: "transparent"
            WlrLayershell.exclusiveZone: 64
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "quickshell:reserve"
            mask: Region {}
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: overlay
            required property var modelData
            readonly property string surface: openMon === modelData.name ? openSurface : ""
            readonly property bool surfaceOpen: surface.length > 0
            screen: modelData
            anchors { top: true; left: true; right: true; bottom: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell:overlay"
            WlrLayershell.keyboardFocus: surfaceOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            onSurfaceOpenChanged: if (surfaceOpen) focusScope.forceActiveFocus()

            mask: Region {
                item: island
            }

            MouseArea {
                anchors.fill: parent
                enabled: overlay.surfaceOpen
                onClicked: root.close()
            }

            FocusScope {
                id: focusScope
                anchors.fill: parent
                focus: overlay.surfaceOpen
                Keys.onEscapePressed: root.close()

                Rectangle {
                    id: island

                    readonly property int targetW: {
                        switch (overlay.surface) {
                            case "notif":  return 400
                            case "clock":  return 500
                            case "launch": return 500
                            case "volume": return 260
                            case "player": return 800
                            case "network":return 300
                            case "bluetooth":return 300
                            case "battery":  return 300
                            default:       return 1080
                        }
                    }

                    readonly property int targetH: {
                        switch (overlay.surface) {
                            case "notif":  return 480
                            case "clock":  return 380
                            case "launch": return 500
                            case "volume": return 160
                            case "player": return 600
                            case "network":return 400
                            case "bluetooth":return 300
                            case "battery":  return 260
                            default:       return 42
                        }
                    }

                    readonly property int targetX: (!surfaceOpen || !root.openByMouse)
                        ? overlay.width / 2 - targetW / 2
                        : Math.max(8, Math.min(overlay.width - targetW - 8, root.openX - targetW / 2))

                    readonly property int targetY: (!surfaceOpen || root.openByMouse)
                        ? 8
                        : overlay.height / 2 - targetH / 2

                    
                    width: targetW
                    height: targetH
                    x: targetX
                    y: targetY

                    color: '#c0141216'
                    radius: 8
                    clip: true

                    Behavior on x      { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                    Behavior on y      { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                    Behavior on width  { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
                    Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

                    Loader {
                        anchors.fill: parent
                        asynchronous: false
                        sourceComponent: {
                            switch (overlay.surface) {
                                case "":        return tabsComponent
                                case "network": return networkComponent
                                case "volume":  return volumeComponent
                                case "player":  return playerComponent
                                case "clock":   return clockComponent
                                case "notif":   return notifComponent
                                case "launch":  return launcherComponent
                                case "bluetooth":return bluetoothComponent
                                case "battery": return batteryComponent
                                default:        return tabsComponent
                            }
                        }

                        onLoaded: {
                            if (item) item.forceActiveFocus()
                        }
                    }

                    Component {
                        id: tabsComponent
                        TabsWidget {
                            anchors.fill: parent
                            focus: true
                            onRequestSurface: (name, anchorX) => root.toggleSurface(overlay.modelData.name, name, anchorX)
                        }
                    }

                    Component {
                        id: networkComponent
                        NetworkWidget {
                            anchors.fill: parent
                            focus: true
                        }
                    }

                    Component {
                        id: notifComponent
                        NotificationsWidget {
                            anchors.fill: parent
                            focus: true
                        }
                    }

                    Component {
                        id: launcherComponent
                        LauncherWidget {
                            anchors.fill: parent
                            focus: true
                        }
                    }

                    Component {
                        id: bluetoothComponent
                        BluetoothWidget {
                            anchors.fill: parent
                            focus: true
                        }
                    }

                    Component {
                        id: volumeComponent
                        VolumeWidget {
                            anchors.fill: parent
                            focus: true
                        }
                    }

                    Component {
                        id: clockComponent
                        ClockWidget {
                            anchors.fill: parent
                            focus: true
                        }
                    }

                    Component {
                        id: playerComponent
                        PlayerWidget {
                            anchors.fill: parent
                            focus: true
                        }
                    }
                    // new Component alongside the others:
                    Component {
                        id: batteryComponent
                        BatteryWidget {
                            anchors.fill: parent
                            focus: true
                            close: root.close
                        }
                    }
                }
            }
        }
    }
}
