import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.modules.components
import qs.modules.services

ClippingRectangle {
    id: root

    property string path: ""
    property bool picked: false
    readonly property bool applied: path !== "" && path === Wallpaper.current
    readonly property bool ringed: picked && Config.focusVisible
    signal clicked()
    function activate() { clicked() }
    Accessible.role: Accessible.Button
    Accessible.name: path.split("/").pop()
    Accessible.checked: applied
    Accessible.onPressAction: activate()

    radius: Config.innerRadius
    color: Config.container

    CoverImage {
        source: root.path ? Wallpaper.fileUrl(root.path) : ""
        sourceSize: Qt.size(384, 240)            // decode small: wallpapers are big
    }

    Rectangle {
        visible: area.containsMouse
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 34
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(Config.surface.r, Config.surface.g, Config.surface.b, 0) }
            GradientStop { position: 1; color: Qt.rgba(Config.surface.r, Config.surface.g, Config.surface.b, 0.85) }
        }

        Label {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Config.spaceM; bottomMargin: Config.spaceS }
            text: Wallpaper.baseName(root.path)
            elide: Text.ElideMiddle
            font.pixelSize: Config.small
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: root.ringed ? 4 : root.applied ? 3 : 0
        border.color: root.applied && !root.ringed ? Config.primary : Config.text
    }
    Rectangle {
        visible: root.applied
        anchors { right: parent.right; top: parent.top; margins: Config.spaceS }
        width: 24; height: 24; radius: 12
        color: Config.primary

        Icon {
            anchors.centerIn: parent
            name: "check"
            size: 16
            color: Config.primaryInk
        }
    }

    // While the colours come from the wallpaper, picking one changes them too: each shows the scheme it
    // would make (its Auto; the one in use, the option picked for it), as the Colours view's circles do.
    Loader {
        active: Config.source === "wallpaper" && root.path !== ""
        anchors { left: parent.left; top: parent.top; margins: Config.spaceS }
        width: 26
        height: 26

        sourceComponent: Item {
            id: preview

            // the one in use has its colours already (Wallpaper); the rest read their own, the same way
            ColorQuantizer {
                id: colours
                source: root.applied ? "" : Wallpaper.fileUrl(root.path)
                depth: 3
                rescaleSize: 96
            }
            readonly property var option: root.applied ? Wallpaper.option : (Config.wallpaperOptions(colours.colors)[0] ?? null)

            PaletteDot {
                visible: preview.option !== null
                anchors.fill: parent
                activeFocusOnTab: false
                palette: preview.option ? Config.wallpaperScheme(preview.option) : null
            }
        }
    }

    ClickArea {
        id: area
        onClicked: root.clicked()
    }
}
