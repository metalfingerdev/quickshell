// config/quickshell/booo/Launcher.qml
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

RowLayout {
    id: center

    signal requestSurface(string name, real anchorX)

    spacing: 2
    anchors.centerIn: parent

    Repeater {
        model: 32

        // Fixed container delegate managed by the Row
        delegate: Item {
            required property int index
            readonly property real value: Cava.leftBars.length > index ? Cava.leftBars[index] : 0

            width: 3
            height: 32 // Matches launcherButton height

            // Inner visual bar (NOT managed by Row, so anchors are 100% valid)
            Rectangle {
                width: parent.width
                height: Math.max(0, parent.value * 28)
                radius: 1
                color: Config.foreground
                anchors.centerIn: parent

                Behavior on height {
                    NumberAnimation {
                        duration: 80
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

    }


    Rectangle {
      id: button
    
      width: 32
      height: 32
      radius: Config.radius
      color: area.containsMouse ? Config.accent : Config.highlight
    
      MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            const anchorX = area.mapToItem(null, area.width / 2, 0).x
            if (mouse.button === Qt.RightButton) {
                requestSurface("player", anchorX)
            } else {
                requestSurface("launch", anchorX)
            }
        }
      }
    
      Text {
        
        anchors.centerIn: parent
        color: area.containsMouse ? Config.bgDark : Config.foreground
        font.family: "Maple Mono"
        font.pixelSize: 14
        font.bold: true
        text: "〇"
      }
    }

    Repeater {
        model: 32

        delegate: Item {
            required property int index
            readonly property real value: Cava.rightBars.length > index ? Cava.rightBars[index] : 0

            width: 3
            height: 32

            Rectangle {
                width: parent.width
                height: Math.max(0, parent.value * 28)
                radius: 1
                color: Config.foreground
                anchors.centerIn: parent

                Behavior on height {
                    NumberAnimation {
                        duration: 80
                        easing.type: Easing.OutCubic
                    }

                }

            }

        }

    }

}
