// widgets/ClockWidget.qml
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config

Item {
    id: root

    property var close: function() {}

    // ── Tab state ─────────────────────────────────────────────────────────────
    property int tab: 0   // 0 = clock, 1 = calendar

    MouseArea {
        anchors.fill: parent
        onClicked: close()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 0

        // ── Tab bar ───────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: 4

            Repeater {
                model: ["Clock", "Calendar"]

                Rectangle {
                    required property string modelData
                    required property int    index

                    implicitWidth:  tabLabel.implicitWidth + 16
                    implicitHeight: 24
                    radius: Config.radius
                    color: root.tab === index
                        ? Config.accent
                        : (tabArea.containsMouse ? Config.highlight : "transparent")

                    Text {
                        id: tabLabel
                        anchors.centerIn: parent
                        text: modelData
                        font.family: "Maple Mono"
                        font.pixelSize: 12
                        color: root.tab === index ? Config.bgDark : Config.foreground
                    }

                    MouseArea {
                        id: tabArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tab = index
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Live time in corner
            Text {
                text: Time.time
                font.family: "Maple Mono"
                font.pixelSize: 12
                color: Config.foreground
                opacity: 0.5
            }
        }

        // ── Divider ───────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 10
            Layout.bottomMargin: 10
            height: 1
            color: Config.foreground
            opacity: 0.12
        }

        // ── Clock view ────────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.tab === 0
            spacing: 4

            // Big time
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Time.time
                font.family: "Maple Mono"
                font.pixelSize: 64
                font.weight: Font.Light
                color: Config.foreground
            }

            // Date line
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Time.date
                font.family: "Maple Mono"
                font.pixelSize: 16
                color: Config.foreground
                opacity: 0.55
            }

            Item { Layout.fillHeight: true }

            // Analog clock face
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth:  160
                implicitHeight: 160

                // Face
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.color: Config.foreground
                    border.width: 1
                    opacity: 0.2
                }

                // Hour markers
                Repeater {
                    model: 12
                    Rectangle {
                        width:  index % 3 === 0 ? 2 : 1
                        height: index % 3 === 0 ? 10 : 6
                        color:  Config.foreground
                        opacity: 0.4
                        x: 80 + Math.sin(index / 12 * Math.PI * 2) * 72 - width  / 2
                        y: 80 - Math.cos(index / 12 * Math.PI * 2) * 72 - height / 2
                    }
                }

                // Hour hand
                Rectangle {
                    width: 3
                    height: 44
                    radius: 2
                    color: Config.foreground
                    x: 80 - width / 2
                    y: 80 - height
                    transformOrigin: Item.Bottom
                    rotation: (Time.hours % 12) / 12 * 360 + Time.minutes / 60 * 30
                }

                // Minute hand
                Rectangle {
                    width: 2
                    height: 62
                    radius: 2
                    color: Config.foreground
                    x: 80 - width / 2
                    y: 80 - height
                    transformOrigin: Item.Bottom
                    rotation: Time.minutes / 60 * 360 + Time.seconds / 60 * 6
                }

                // Second hand
                Rectangle {
                    width: 1
                    height: 68
                    radius: 1
                    color: Config.accent
                    x: 80 - width / 2
                    y: 80 - height
                    transformOrigin: Item.Bottom
                    rotation: Time.seconds / 60 * 360

                    Behavior on rotation {
                        RotationAnimation {
                            duration: 200
                            direction: RotationAnimation.Clockwise
                        }
                    }
                }

                // Centre dot
                Rectangle {
                    width: 6; height: 6
                    radius: 3
                    color: Config.accent
                    anchors.centerIn: parent
                }
            }

            Item { Layout.fillHeight: true }
        }

        // ── Calendar view ─────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.tab === 1
            spacing: 8

            // Month navigation
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "‹"
                    font.pixelSize: 20
                    font.family: "Maple Mono"
                    color: Config.foreground
                    opacity: prevArea.containsMouse ? 1.0 : 0.5
                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cal.showPreviousMonth()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: cal.monthName + " " + cal.year
                    font.family: "Maple Mono"
                    font.pixelSize: 14
                    color: Config.foreground
                }

                Text {
                    text: "›"
                    font.pixelSize: 20
                    font.family: "Maple Mono"
                    color: Config.foreground
                    opacity: nextArea.containsMouse ? 1.0 : 0.5
                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cal.showNextMonth()
                    }
                }
            }

            // Day-of-week headers
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                Repeater {
                    model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.family: "Maple Mono"
                        font.pixelSize: 11
                        color: Config.foreground
                        opacity: 0.4
                    }
                }
            }

            // Calendar grid
            Grid {
                id: calGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                rowSpacing: 2
                columnSpacing: 0

                Repeater {
                    model: cal.days

                    Rectangle {
                        required property var modelData
                        width:  calGrid.width / 7
                        height: width
                        radius: width / 2
                        color: modelData.isToday
                            ? Config.accent
                            : (dayArea.containsMouse ? Config.highlight : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day > 0 ? modelData.day : ""
                            font.family: "Maple Mono"
                            font.pixelSize: 12
                            font.bold: modelData.isToday
                            color: modelData.isToday
                                ? Config.bgDark
                                : modelData.currentMonth
                                    ? Config.foreground
                                    : Config.foreground
                            opacity: modelData.currentMonth ? 1.0 : 0.25
                        }

                        MouseArea {
                            id: dayArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }

    // ── Calendar logic ────────────────────────────────────────────────────────
    QtObject {
        id: cal

        property int year:  Time.year
        property int month: Time.month   // 1-based
        property string monthName: [
            "January","February","March","April","May","June",
            "July","August","September","October","November","December"
        ][month - 1]

        property var days: []

        onYearChanged:  rebuild()
        onMonthChanged: rebuild()
        Component.onCompleted: rebuild()

        function showPreviousMonth() {
            if (month === 1) { month = 12; year-- }
            else month--
        }

        function showNextMonth() {
            if (month === 12) { month = 1; year++ }
            else month++
        }

        function rebuild() {
            var result = []
            var first  = new Date(year, month - 1, 1)
            // Monday-based: getDay() returns 0=Sun,so shift
            var startDow = (first.getDay() + 6) % 7  // 0=Mon
            var daysInMonth   = new Date(year, month,     0).getDate()
            var daysInPrev    = new Date(year, month - 1, 0).getDate()

            // Pad from previous month
            for (var i = 0; i < startDow; i++) {
                result.push({
                    day: daysInPrev - startDow + 1 + i,
                    currentMonth: false,
                    isToday: false
                })
            }
            // Current month
            var today = new Date()
            for (var d = 1; d <= daysInMonth; d++) {
                result.push({
                    day: d,
                    currentMonth: true,
                    isToday: d === today.getDate()
                          && month === (today.getMonth() + 1)
                          && year  === today.getFullYear()
                })
            }
            // Pad to complete last row
            var remaining = (7 - (result.length % 7)) % 7
            for (var j = 1; j <= remaining; j++) {
                result.push({ day: j, currentMonth: false, isToday: false })
            }
            days = result
        }
    }
}