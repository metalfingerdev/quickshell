import QtQuick

// A picker's handle: a disc of the colour it's on, in a white ring with a dark hairline, so it keeps an
// edge on white and on black (ColourMap, HueStrip).
Rectangle {
    width: 24
    height: 24
    radius: 12
    border.width: 3
    border.color: "#ffffff"

    Rectangle {
        anchors { fill: parent; margins: -1 }
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: "#80000000"
    }
}
