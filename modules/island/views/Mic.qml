import QtQuick
import qs.modules.parts
import qs.modules.services

// The microphone muted or back on (the mic key, or an app): the toast says which, as Volume does
// for the output. A click opens the Mixer, where the microphone has its own slider.
Item {
    implicitWidth: 440
    implicitHeight: 72

    VolumeSlider {
        anchors { fill: parent; margins: 10 }
        activeFocusOnTab: false
        node: Audio.source
        icon: silent ? "mic_off" : "mic"
    }
}
