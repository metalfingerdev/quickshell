import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.parts
import qs.modules.services

// Settings: the folders the wallpaper picker shows. The island's own pictures are always among them,
// listed like any other (Wallpaper.qml), so there is nothing here about them.
Item {
    id: root

    readonly property int pad: 24
    readonly property int colW: 520

    implicitWidth: colW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    property string pathError: ""

    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.colW
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: Config.symbol.wallpaper
            title: "Wallpaper"
            subtitle: Wallpaper.files.length + (Wallpaper.files.length === 1 ? " image" : " images")
            onBack: Engine.back()
        }

        Column {
            width: parent.width
            spacing: Config.spaceM

            ListSection {
                title: "Folders"
                footer: "A GIF with a still of the same name beside it (.jpg, .png, .webp) shows the still on battery saver."
                Repeater {
                    model: Wallpaper.folders
                    ListEntry {
                        required property string modelData
                        flat: true
                        icon: "folder"
                        title: Wallpaper.baseName(modelData)
                        subtitle: modelData
                        Pill {
                            implicitHeight: 38
                            kind: "text"
                            icon: "close"
                            iconSize: 20
                            onClicked: Wallpaper.removeFolder(modelData)
                        }
                    }
                }
            }
            PictureField {
                id: adding
                icon: "create_new_folder"
                placeholder: "Add a folder: its path"
                onChosen: path => {
                    if (path === "") return
                    root.pathError = Wallpaper.addFolder(path)
                    if (root.pathError === "") adding.text = ""
                }
            }
            Rectangle {
                visible: root.pathError !== ""
                width: parent.width
                height: pathNote.implicitHeight + 2 * Config.spaceS
                radius: Math.min(height / 2, Config.innerRadius)
                color: Config.tile

                Label {
                    id: pathNote
                    anchors { left: parent.left; right: parent.right; margins: Config.spaceM; verticalCenter: parent.verticalCenter }
                    elide: Text.ElideMiddle
                    text: root.pathError
                    color: Config.bad
                    font.pixelSize: Config.small
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["⏎", "add"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
