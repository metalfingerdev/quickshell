import QtQuick

// Every hue along a capsule, red to red, with a knob on the one chosen (ColourMap, Theme's surface hue).
ColourBar {
    property real hue: 0
    value: hue
    step: 1 / 120
    title: "Hue"
    colourAt: t => Qt.hsva(t, 1, 1, 1)
}
