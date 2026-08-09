import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config

FocusScope {
    property var close: function() { }
    property string searchQuery: ""
    property bool clickActivated: false

    readonly property bool isActive: searchQuery.length > 0 || hoverHandler.hovered || appList.searchBarKeyboardFocus

    onIsActiveChanged: if (!isActive) clickActivated = false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Search Bar
        Rectangle {
            id: searchBar
            Layout.fillWidth: true
            implicitHeight: 52
            radius: 8
            color: isActive ? Config.bgLight : "transparent"
            

            HoverHandler {
                id: hoverHandler
                onHoveredChanged: {
                    if (hovered) appList.currentIndex = -1
                }
            }

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                onPressed: (mouse) => {
                    clickActivated = true
                    mouse.accepted = false
                }
            }

            Text {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "\uf002"
                font.family: Config.font
                font.pixelSize: Config.fontSize
                color: Config.foreground
            }

            TextInput {
                id: searchInput
                anchors.left: searchIcon.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: 8
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                font.family: Config.font
                font.pixelSize: 18
                color: Config.foreground
                focus: true
                Keys.forwardTo: [appList]
                onTextChanged: {
                    searchQuery = text
                    appList.searchBarKeyboardFocus = false
                    appList.currentIndex = 0
                }

                Text {
                    text: "Search | 검색 | Поиск | Sök"
                    font.family: Config.font
                    font.pixelSize: 18
                    color: Config.foreground
                    opacity: 0.4
                    visible: searchInput.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                }

                cursorDelegate: Rectangle {
                    color: Config.foreground
                    width: 1
                    visible: isActive && (clickActivated || searchInput.text.length > 0)
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: true
                        PauseAnimation { duration: 500 }
                        PropertyAction { value: 0 }
                        PauseAnimation { duration: 500 }
                        PropertyAction { value: 1 }
                    }
                }
            }

            Rectangle {
                height: 1
                color: isActive ? Config.accent : Config.foreground
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }
                
            }
        }

        // App List
        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 8
            currentIndex: -1
            highlightMoveDuration: 0
            interactive: false

            property point lastMouseScenePos: Qt.point(-1, -1)
            property bool searchBarKeyboardFocus: false

            Keys.onUpPressed: (event) => {
                if (currentIndex <= 0) {
                    currentIndex = -1
                    searchBarKeyboardFocus = true
                } else {
                    currentIndex--
                }
                event.accepted = true
            }

            Keys.onDownPressed: (event) => {
                searchBarKeyboardFocus = false
                if (count > 0) {
                    currentIndex = currentIndex >= count - 1 ? 0 : currentIndex + 1
                }
                event.accepted = true
            }

            Keys.onReturnPressed: {
                if (currentIndex >= 0 && currentItem) {
                    currentItem.modelData.execute()
                    close()
                }
            }

            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                onWheel: (wheel) => {
                    const itemSize = 48 + 8
                    appList.contentY = Math.max(0, Math.min(appList.contentHeight - appList.height, appList.contentY - (wheel.angleDelta.y / 120) * itemSize * 3))
                    wheel.accepted = true
                }
                onPressed: (mouse) => mouse.accepted = false
            }

            model: ScriptModel {
                values: {
                    let apps = DesktopEntries.applications.values
                    if (searchQuery.length === 0) return apps
                    let query = searchQuery.toLowerCase()
                    return apps.filter(a =>
                        a.name.toLowerCase().includes(query) ||
                        (a.genericName && a.genericName.toLowerCase().includes(query))
                    )
                }
            }

            delegate: Rectangle {
                id: delegateRoot
                required property var modelData
                required property int index
                readonly property bool isCurrent: ListView.isCurrentItem

                width: ListView.view.width
                height: 48
                radius: 12
                color: isCurrent ? Config.bgLight : "transparent"

                //Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    spacing: 12

                    IconImage {
                        implicitSize: 32
                        asynchronous: true
                        source: Quickshell.iconPath(modelData.icon, "application-x-executable")
                    }

                    Text {
                        text: modelData.name
                        font.family: Config.font
                        font.pixelSize: 16
                        color: isCurrent ? Config.accent : Config.foreground
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        modelData.execute()
                        close()
                    }
                    onPositionChanged: (mouse) => {
                        var scenePos = mapToGlobal(mouse.x, mouse.y)
                        var last = appList.lastMouseScenePos
                        if (Math.abs(scenePos.x - last.x) > 0.5 || Math.abs(scenePos.y - last.y) > 0.5) {
                            appList.lastMouseScenePos = scenePos
                            appList.currentIndex = index
                        }
                    }
                }
            }
        }
    }
}