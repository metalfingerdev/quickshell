import QtQuick
import qs.modules.components
import qs.modules.services

Hud {
    readonly property int level: Audio.level(Audio.sink)
    readonly property bool silent: Audio.isMuted(Audio.sink)
    icon: Audio.levelIcon(level, silent)
    value: silent ? 0 : level / 100
    valueText: silent ? "Muted" : level + "%"
    onStepped: d => Audio.setLevel(Audio.sink, Math.max(0, Math.min(100, level + 5 * d)))
}
