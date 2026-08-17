import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config

Item {
    property var close: function() {}

    MouseArea {
        anchors.fill: parent
        onClicked: close()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // ── Battery info ─────────────────────────────────────────────
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: UPower.icon
                color: UPower.isCritical ? "#f38ba8" : UPower.isCharging ? "#a6e3a1" : Config.foreground
                font.family: "Maple Mono"
                font.pixelSize: 48
                font.weight: Font.Light
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: UPower.percentage + "%"
                color: Config.foreground
                font.family: "Maple Mono"
                font.pixelSize: 48
                font.weight: Font.Light
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: UPower.statusLabel
                color: Config.foreground
                font.family: "Maple Mono"
                font.pixelSize: 14
                font.weight: Font.Light
                opacity: 0.6
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Config.foreground
            opacity: 0.15
        }

        // ── Brightness control ──────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: Brightness.available

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰃟"
                    color: Config.foreground
                    font.family: "Maple Mono"
                    font.pixelSize: 16
                }

                Text {
                    text: "Brightness"
                    color: Config.foreground
                    font.family: "Maple Mono"
                    font.pixelSize: 12
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: Brightness.percentage + "%"
                    color: Config.foreground
                    opacity: 0.6
                    font.family: "Maple Mono"
                    font.pixelSize: 12
                }
            }

            // Slider track
            Rectangle {
                id: sliderTrack

                Layout.fillWidth: true
                Layout.preferredHeight: 8
                radius: height / 2
                color: Config.highlight

                Rectangle {
                    id: sliderFill

                    width: sliderTrack.width * (Brightness.percentage / 100)
                    height: parent.height
                    radius: parent.radius
                    color: Config.accent

                    Behavior on width {
                        enabled: !sliderArea.pressed
                        NumberAnimation { duration: 120 }
                    }
                }

                // Handle
                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    color: Config.accent
                    border.width: 2
                    border.color: Config.bgDark
                    x: Math.max(0, Math.min(sliderTrack.width - width, sliderFill.width - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                }

                MouseArea {
                    id: sliderArea

                    anchors.fill: parent
                    anchors.margins: -6 // easier to grab
                    cursorShape: Qt.PointingHandCursor

                    function updateFromX(x) {
                        var pct = ((x - 6) / sliderTrack.width) * 100
                        Brightness.setPercentage(pct)
                    }

                    onPressed: mouse => updateFromX(mouse.x)
                    onPositionChanged: mouse => { if (pressed) updateFromX(mouse.x) }
                    onReleased: Brightness.commit()
                }
            }
        }
    }
}