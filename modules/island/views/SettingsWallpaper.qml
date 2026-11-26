import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.parts
import qs.modules.services

// Settings: the wallpaper, and the still shown in its place on battery saver.
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
            subtitle: Wallpaper.baseName(Wallpaper.base)
            onBack: Engine.back()
        }

        Column {
            width: parent.width
            spacing: Config.spaceM

            SectionLabel { text: "Pictures"; topPadding: Config.spaceS }
            PictureField {
                icon: Config.symbol.wallpaper
                placeholder: "Wallpaper: the default one"
                value: Wallpaper.basePath
                onChosen: path => root.pathError = Wallpaper.setPicture("base", path)

                Pill {
                    implicitHeight: 38
                    kind: "text"
                    icon: "keep"
                    iconSize: 20
                    shortcut: "w"
                    onClicked: { root.pathError = ""; Wallpaper.setPicture("base", Wallpaper.current) }
                }
            }
            PictureField {
                icon: "battery_saver"
                placeholder: "On battery saver: the default still"
                value: Wallpaper.stillPath
                onChosen: path => root.pathError = Wallpaper.setPicture("still", path)
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
            keys: [["⏎", "apply"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
