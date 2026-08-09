// config/quickshell/bo/NetworkAdapter.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    // ── Raw devices ───────────────────────────────────────────────────────────

    readonly property var wifi:  Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected)

    // ── Connection state ──────────────────────────────────────────────────────

    readonly property bool isWired:     !!wired
    readonly property bool isWifi:      !isWired && !!activeNet
    readonly property bool connected:   isWired || isWifi
    readonly property bool wifiEnabled: Networking.wifiEnabled

    // ── Active wifi network ───────────────────────────────────────────────────

    readonly property var    activeNet:      wifi ? wifi.networks.values.find(n => n.connected) : null
    readonly property string ssid:           activeNet ? activeNet.name    : ""
    readonly property int    signalPercent:  activeNet ? Math.round(activeNet.signalStrength * 100) : 0
    readonly property int    signalBars:     {
        if (!activeNet) return 0
        var s = activeNet.signalStrength
        if (s >= 0.75) return 4
        if (s >= 0.50) return 3
        if (s >= 0.25) return 2
        return 1
    }

    // ── Wired info ────────────────────────────────────────────────────────────

    readonly property string wiredName: wired ? wired.name : ""

    // ── Icon helpers (Nerd Font) ──────────────────────────────────────────────

    readonly property string icon: {
        if (!connected)     return "󰤭"   // no connection
        if (isWired)        return "󰈀"   // ethernet
        var s = signalPercent
        if (s >= 75)        return "󰤨"   // wifi full
        if (s >= 50)        return "󰤥"   // wifi good
        if (s >= 25)        return "󰤢"   // wifi fair
        return "󰤟"                        // wifi weak
    }

    readonly property string wifiIcon: {
        if (!wifiEnabled)   return "󰤭"
        if (!activeNet)     return "󰤫"   // wifi off/disconnected
        var s = signalPercent
        if (s >= 75)        return "󰤨"
        if (s >= 50)        return "󰤥"
        if (s >= 25)        return "󰤢"
        return "󰤟"
    }

    // ── Scanning ──────────────────────────────────────────────────────────────

    readonly property bool isScanning: wifi ? wifi.scannerEnabled : false

    // All networks sorted strongest first, active one pinned to top
    readonly property var availableNetworks: {
        if (!wifi) return []
        var nets = wifi.networks.values.slice()
        nets.sort((a, b) => {
            if (a.connected && !b.connected) return -1
            if (!a.connected && b.connected) return  1
            return b.signalStrength - a.signalStrength
        })
        return nets
    }

    // Known (previously connected) networks only
    readonly property var knownNetworks: availableNetworks.filter(n => n.known)

    // ── IP addresses ──────────────────────────────────────────────────────────

    readonly property string ipv4: {
        var dev = isWired ? wired : (wifi ?? null)
        if (!dev) return ""
        var addr = dev.ipv4addresses
        return (addr && addr.length > 0) ? addr[0].address : ""
    }

    readonly property string ipv6: {
        var dev = isWired ? wired : (wifi ?? null)
        if (!dev) return ""
        var addr = dev.ipv6addresses
        return (addr && addr.length > 0) ? addr[0].address : ""
    }

    // ── Connectivity label ────────────────────────────────────────────────────

    readonly property string statusLabel: {
        if (!connected)  return "Disconnected"
        if (isWired)     return "Wired"
        if (ssid !== "") return ssid
        return "Connected"
    }

    readonly property string detailLabel: {
        if (!connected)  return ""
        if (ipv4 !== "") return ipv4
        if (ipv6 !== "") return ipv6
        return ""
    }

    // ── Actions ───────────────────────────────────────────────────────────────

    function toggleWifi()   { Networking.wifiEnabled = !Networking.wifiEnabled }
    function toggleScan()   { if (wifi) wifi.scannerEnabled = !wifi.scannerEnabled }

    function connectTo(network) {
        if (network) network.activate()
    }

    function disconnectActive() {
        if (activeNet) activeNet.deactivate()
    }

    function openSettings() {
        Qt.openUrlExternally("nm-connection-editor:")
    }

    // ── Auto-scan when wifi enabled ───────────────────────────────────────────

    onWifiEnabledChanged: {
        if (wifiEnabled && wifi && !wifi.scannerEnabled)
            wifi.scannerEnabled = true
    }

    onWifiChanged: {
        if (wifi && wifiEnabled && !wifi.scannerEnabled)
            wifi.scannerEnabled = true
    }
}