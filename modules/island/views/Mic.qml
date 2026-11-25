import QtQuick
import qs.modules.components
import qs.modules.services

// The microphone muted or back on (the mic key, or an app): the toast says which, as Volume does for the
// output. A click opens the Mixer, where the microphone has its own slider.
Hud {
    readonly property bool silent: Audio.isMuted(Audio.source)
    icon: silent ? "mic_off" : "mic"
    tone: silent ? Config.bad : Config.text
    value: silent ? 0 : Audio.level(Audio.source) / 100
    valueText: silent ? "Muted" : Audio.level(Audio.source) + "%"
    onStepped: d => Audio.setLevel(Audio.source, Math.max(0, Math.min(100, Audio.level(Audio.source) + 5 * d)))
}
