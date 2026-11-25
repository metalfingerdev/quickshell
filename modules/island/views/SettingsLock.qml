import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.parts
import qs.modules.lock
import qs.modules.services

// Settings: the lock screen's pictures and who it says is signing in.
Item {
    id: root

    readonly property int pad: 24
    readonly property int colW: 520

    implicitWidth: colW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    // a text field that takes its keys (ViewLoader never sees them) and gives Escape and Backspace
    // back what they mean in a view
    component Field: SearchBar {
        width: parent.width
        height: 52
        fieldSize: Config.body
        onKey: Engine.key()
        onEscaped: Engine.close()
        onBackspaceEmpty: Engine.back()
    }

    // a picture's path: applied on Enter and on leaving the field
    property string pathError: ""
    component PathField: Field {
        id: path
        property string setting: ""
        text: LockConfig[setting]
        function apply() { root.pathError = LockConfig.setPicture(setting, text.trim()) }
        onAccepted: apply()

        Connections {
            target: path.field
            function onActiveFocusChanged() { if (!path.field.activeFocus && path.text !== LockConfig[path.setting]) path.apply() }
        }
    }


    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.colW
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: "lock"
            title: "Lock screen"
            subtitle: LockConfig.shownName + "  ·  " + LockConfig.shownInfo
            onBack: Engine.back()
        }

        Column {
            width: parent.width
            spacing: Config.spaceM

            SectionLabel { text: "Pictures"; topPadding: Config.spaceS }
            PathField {
                setting: "image"
                icon: Config.symbol.wallpaper
                placeholder: "Background: follows the wallpaper"

                Pill {
                    implicitHeight: 38
                    kind: "text"
                    icon: "keep"
                    iconSize: 20
                    shortcut: "w"
                    onClicked: { root.pathError = ""; LockConfig.image = Wallpaper.current }
                }
            }
            PathField {
                setting: "avatar"
                icon: "person"
                placeholder: "Profile picture: a path, GIFs play"
            }
            Segmented {
                width: parent.width
                options: [{ key: "circle", label: "Circle" }, { key: "square", label: "Square" }]
                current: LockConfig.avatarShape
                onPicked: key => LockConfig.avatarShape = key
            }
            Label {
                visible: root.pathError !== ""
                width: parent.width
                leftPadding: Config.spaceXs
                elide: Text.ElideMiddle
                text: root.pathError
                color: Config.bad
                font.pixelSize: Config.small
            }

            // how far the picture softens once the sign-in comes up
            Slider {
                width: parent.width
                icon: "blur_on"
                value: LockConfig.blur
                valueText: "Softened behind the sign-in  " + Math.round(shown * 100) + "%"
                onMoved: v => LockConfig.blur = v
            }

            SectionLabel { text: "Who"; topPadding: Config.spaceS }
            Field {
                text: LockConfig.name
                icon: "badge"
                placeholder: LockConfig.fullName || LockConfig.user
                onTextChanged: LockConfig.name = text
            }
            Field {
                text: LockConfig.info
                icon: "info"
                placeholder: LockConfig.defaultInfo
                onTextChanged: LockConfig.info = text
            }
        }

        KeyHints {
            width: parent.width
            keys: [["⏎", "apply"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
