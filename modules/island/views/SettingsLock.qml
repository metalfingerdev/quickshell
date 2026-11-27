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

    property string pathError: ""
    component LockPicture: PictureField {
        property string setting: ""
        value: LockConfig[setting]
        onChosen: path => root.pathError = LockConfig.setPicture(setting, path)
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
            LockPicture {
                setting: "image"
                icon: Config.symbol.wallpaper
                placeholder: "Background: the default picture"

                Pill {
                    implicitHeight: 38
                    kind: "text"
                    icon: "keep"
                    iconSize: 20
                    shortcut: "w"
                    onClicked: { root.pathError = ""; LockConfig.image = Wallpaper.current }
                }
            }
            LockPicture {
                setting: "avatar"
                icon: "person"
                placeholder: "Profile picture: the default, or a path (GIFs play)"
            }
            Segmented {
                width: parent.width
                options: [{ key: "circle", label: "Circle" }, { key: "square", label: "Square" }]
                current: LockConfig.avatarShape
                onPicked: key => LockConfig.avatarShape = key
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

            // how far the picture softens once the sign-in comes up
            Slider {
                width: parent.width
                icon: "blur_on"
                value: LockConfig.blur
                valueText: "Softened behind the sign-in  " + Math.round(shown * 100) + "%"
                onMoved: v => LockConfig.blur = v
            }

            // The login screen, before you are in: its own pictures, the shipped ones when empty. Name,
            // shape and softness are the lock's. Copied for it to read: it can't open your home.
            SectionLabel { visible: LockConfig.greeterAvailable; text: "Login screen"; topPadding: Config.spaceS }
            LockPicture {
                visible: LockConfig.greeterAvailable
                setting: "greeterImage"
                icon: Config.symbol.wallpaper
                placeholder: "Login background: the default picture"

                Pill {
                    implicitHeight: 38
                    kind: "text"
                    icon: "lock"
                    iconSize: 20
                    onClicked: { root.pathError = ""; LockConfig.greeterImage = LockConfig.image }
                }
            }
            LockPicture {
                visible: LockConfig.greeterAvailable
                setting: "greeterAvatar"
                icon: "person"
                placeholder: "Login profile picture: the default"

                Pill {
                    implicitHeight: 38
                    kind: "text"
                    icon: "lock"
                    iconSize: 20
                    onClicked: { root.pathError = ""; LockConfig.greeterAvatar = LockConfig.avatar }
                }
            }

            Label {
                visible: LockConfig.greeterAvailable
                width: parent.width
                wrapMode: Text.Wrap
                text: "The lock button takes the lock screen's picture. Both are copied for the login screen, which can't open your home."
                color: Config.dim
                font.pixelSize: Config.small
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
