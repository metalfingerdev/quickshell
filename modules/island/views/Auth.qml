import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// What a program asked to do as root (polkit), and the password for it. Escape or Cancel refuses, and
// so does the view going away: a request nobody can see must not stay open.
Item {
    id: root

    readonly property var flow: Auth.flow

    implicitWidth: 480
    implicitHeight: column.implicitHeight + 48
    Component.onDestruction: Auth.cancel()

    Column {
        id: column
        x: 24; y: 24
        width: parent.width - 48
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: "lock"
            title: "Authentication required"
            subtitle: "A program asks to run as root"
            showBack: false
        }

        Rectangle {
            width: parent.width
            height: message.implicitHeight + 2 * Config.spaceM
            radius: Config.innerRadius
            color: Config.tile

            Label {
                id: message
                anchors { left: parent.left; right: parent.right; margins: Config.spaceM; verticalCenter: parent.verticalCenter }
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                text: root.flow ? root.flow.message : ""
            }
        }

        Label {
            visible: text !== ""
            width: parent.width
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            text: root.flow ? root.flow.supplementaryMessage : ""
            color: root.flow?.supplementaryIsError ? Config.bad : Config.dim
        }

        SearchBar {
            id: password
            visible: root.flow?.isResponseRequired ?? false
            width: parent.width
            implicitHeight: 52
            icon: "key"
            placeholder: (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
            focus: true
            field.echoMode: root.flow?.responseVisible ? TextInput.Normal : TextInput.Password
            field.inputMethodHints: Qt.ImhSensitiveData
            onAccepted: root.send()
            onEscaped: Engine.close()
            // a refused password asks again: the field starts empty
            Connections {
                target: root.flow
                ignoreUnknownSignals: true
                function onIsResponseRequiredChanged() { password.text = "" }
            }
        }
        Label {
            visible: !password.visible
            text: "Waiting for the check to finish…"
            color: Config.dim
        }

        Row {
            spacing: Config.spaceM
            Pill { kind: "filled"; text: "Allow"; icon: "check"; enabled: password.visible; onClicked: root.send() }
            Pill { kind: "text"; text: "Cancel"; onClicked: Engine.close() }
        }

        KeyHints {
            width: parent.width
            keys: [["↵", "allow"], ["Esc", "cancel"]]
        }
    }

    function send() {
        if (password.text === "") return
        Auth.submit(password.text)
        password.text = ""
    }
}
