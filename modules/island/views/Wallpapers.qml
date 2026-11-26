import QtQuick
import Quickshell.Widgets
import qs.modules.island
import qs.modules.parts
import qs.modules.components
import qs.modules.services

// Named Wallpapers, not Wallpaper: a view must not share a singleton's name (services/Wallpaper.qml).
Item {
    id: root

    readonly property int pad: 24
    readonly property int contentW: 840
    readonly property int across: 4
    readonly property int rows: 2
    readonly property real gap: 12
    readonly property bool any: Wallpaper.files.length > 0
    // what the search leaves, by the file's name
    property string query: ""
    readonly property var shown: query === "" ? Wallpaper.files
        : Wallpaper.files.filter(f => Wallpaper.baseName(f).toLowerCase().includes(query.toLowerCase()))

    implicitWidth: contentW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    // Super+P held (Held): each P moves along the grid, letting go of Super sets the one reached
    Connections {
        target: Held
        function onStepped(view, delta) {
            if (view !== Engine.View.Wallpapers || grid.count === 0) return
            grid.currentIndex = (grid.currentIndex + delta + grid.count) % grid.count
            grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
        }
        function onChosen(view) {
            if (view !== Engine.View.Wallpapers || grid.count === 0) return
            Wallpaper.set(root.shown[grid.currentIndex])
            Engine.close()
        }
    }

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.contentW
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: Config.symbol.wallpaper
            title: "Wallpaper"
            subtitle: (Wallpaper.current ? Wallpaper.baseName(Wallpaper.current) + "  ·  " : "")
                    + Wallpaper.files.length + (Wallpaper.files.length === 1 ? " image" : " images")
            onBack: Engine.back()

            Pill {
                visible: Wallpaper.files.length > 1
                icon: "shuffle"
                text: "Random"
                shortcut: "r"
                onClicked: Wallpaper.random()
            }
        }

        ClippingRectangle {
            visible: Wallpaper.current !== ""
            width: parent.width
            height: 200
            radius: Config.cardRadius
            color: Config.tile

            CoverImage {
                source: Wallpaper.current ? Wallpaper.fileUrl(Wallpaper.current) : ""
                sourceSize: Qt.size(1280, 720)
            }
        }

        // only once there is more than a row to look through; "/" goes to it, Down back to the grid
        SearchBar {
            id: search
            property string shortcut: "/"
            function activate() { field.forceActiveFocus() }

            visible: Wallpaper.files.length > root.across
            width: parent.width
            height: 48
            placeholder: "Search by name"
            takesArrows: true
            onTextChanged: { root.query = text; grid.currentIndex = 0 }
            onKey: Engine.key()
            onDown: grid.forceActiveFocus()
            onAccepted: if (root.shown.length > 0) Wallpaper.set(root.shown[grid.currentIndex])
            onEscaped: { if (text !== "") text = ""; else grid.forceActiveFocus() }
        }

        Item {
            visible: root.shown.length > 0
            width: parent.width
            height: grid.height

            GridView {
                id: grid

                // each cell carries half a gap on every side: hang those outside the column so the
                // thumbnails line up with its edges
                x: -root.gap / 2
                width: parent.width + root.gap
                height: Math.max(1, Math.min(root.rows, Math.ceil(count / root.across))) * cellHeight
                cellWidth: width / root.across
                cellHeight: Math.round((cellWidth - root.gap) * 0.625) + root.gap
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.shown
                currentIndex: Math.max(0, root.shown.indexOf(Wallpaper.current))
                focus: true                              // the keyboard starts here
                activeFocusOnTab: true
                Component.onCompleted: positionViewAtIndex(currentIndex, GridView.Contain)

                // the grid moves its own selection with the arrows (off its edge it lets them go,
                // and ViewLoader moves focus out); report every key, so the countdown restarts
                Keys.onPressed: event => { Engine.key(); event.accepted = false }

                delegate: Item {
                    id: cell
                    required property string modelData
                    required property int index

                    // the current delegate holds the active focus, not the grid, so Enter lands here
                    function activate() { thumb.activate() }

                    width: grid.cellWidth
                    height: grid.cellHeight

                    WallpaperThumb {
                        id: thumb
                        anchors { fill: parent; margins: root.gap / 2 }
                        path: cell.modelData
                        picked: grid.activeFocus && cell.GridView.isCurrentItem
                        onClicked: { grid.currentIndex = cell.index; Wallpaper.set(cell.modelData) }
                    }
                }
            }
        }

        EmptyState {
            width: parent.width
            compact: true
            visible: root.any && root.shown.length === 0
            icon: "search_off"
            title: "No picture's name has “" + root.query + "” in it"
        }

        EmptyState {
            width: parent.width
            visible: !root.any
            icon: Config.symbol.wallpaper
            title: "No images in your wallpaper folders"
            hint: "Put pictures there (png, jpg, webp) and they show up here."
        }

        KeyHints {
            width: parent.width
            keys: [["← →", "pick"], ["↵", "apply"], ["/", "search"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
