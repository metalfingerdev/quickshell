import QtQuick

// One quantity in a settings page: the Control Centre's slider, its name inside the track, its value at the end.
Slider {
    property string text: ""
    title: text
    width: parent ? parent.width : implicitWidth
    height: visible ? implicitHeight : 0
    step: 0.01
}
