// services/BatteryService.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    // ── Public state ──────────────────────────────────────────────────────────

    readonly property var    device:     UPower.displayDevice
    readonly property bool   isPresent:  device !== null && device.ready && device.isLaptopBattery
    readonly property int    percentage: isPresent ? Math.round(device.percentage * 100) : 0
    readonly property bool   isCharging: isPresent && device.state === UPowerDeviceState.Charging
    readonly property bool   isFull:     percentage >= 100
    readonly property bool   isCritical: percentage < 10 && !isCharging

    // Time-to-empty / time-to-full in seconds (-1 = unknown)
    readonly property real timeToEmpty: isPresent ? device.timeToEmpty : -1
    readonly property real timeToFull:  isPresent ? device.timeToFull  : -1

    // Human-readable time string e.g. "1h 23m"
    readonly property string timeString: {
        var secs = isCharging ? timeToFull : timeToEmpty
        if (secs <= 0 || !isPresent) return ""
        var h = Math.floor(secs / 3600)
        var m = Math.floor((secs % 3600) / 60)
        if (h > 0 && m > 0) return h + "h " + m + "m"
        if (h > 0)           return h + "h"
        return m + "m"
    }

    // Status label e.g. "Charging · 42m to full" / "1h 23m remaining"
    readonly property string statusLabel: {
        if (!isPresent)  return "No battery"
        if (isCharging)  return timeString !== "" ? "Charging · " + timeString + " to full" : "Charging"
        if (isFull)      return "Full"
        return timeString !== "" ? timeString + " remaining" : percentage + "%"
    }

    // Nerd-font icon (same logic as your original, kept as codepoints)
    readonly property string icon: {
        if (isCharging)      return String.fromCodePoint(983172)
        if (isFull)          return String.fromCodePoint(983161)
        if (percentage < 10) return String.fromCodePoint(983171)
        return String.fromCodePoint(983162 + (Math.floor(percentage / 10) - 1))
    }
}