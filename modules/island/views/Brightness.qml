import QtQuick
import qs.modules.components
import qs.modules.services

Hud {
    icon: Backlight.icon
    value: Backlight.percent / 100
    onStepped: d => Backlight.set(Math.max(0, Math.min(100, Backlight.percent + 5 * d)))
}
