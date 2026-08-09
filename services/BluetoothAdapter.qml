// services/BluetoothAdapter.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── Public state ──────────────────────────────────────────────────────────

    readonly property bool available:  _available
    readonly property bool powered:    _powered
    readonly property bool connected:  devices.some ? devices.some(d => d.connected) : false
    readonly property bool isScanning: _scanning

    property bool _available: false
    property bool _powered:   false
    property bool _scanning:  false

    property list<QtObject> devices: []

    // ── Poll timer ────────────────────────────────────────────────────────────

    Timer {
        interval: 3000
        running:  true
        repeat:   true
        onTriggered: {
            showProc.running = true
            devicesProc.running = true
        }
    }

    Component.onCompleted: {
        showProc.running = true
        devicesProc.running = true
    }

    // ── bluetoothctl show — adapter state ─────────────────────────────────────

    Process {
        id: showProc
        command: ["bluetoothctl", "show"]
        running: false

        stdout: SplitParser {
            onRead: line => showProc.handleLine(line)
        }

        property string _buf: ""

        function handleLine(line) {
            var t = line.trim()
            if (t.startsWith("Powered:"))    root._powered   = t.includes("yes")
            if (t.startsWith("Discovering")) root._scanning  = t.includes("yes")
            if (t.startsWith("Controller"))  root._available = true
        }
    }

    // ── bluetoothctl devices — device list ────────────────────────────────────

    Process {
        id: devicesProc
        command: ["bluetoothctl", "devices"]
        running: false

        stdout: SplitParser {
            onRead: line => devicesProc.handleLine(line)
        }

        property var _seen: []

        function handleLine(line) {
            // Format: "Device AA:BB:CC:DD:EE:FF Name Here"
            var m = line.trim().match(/^Device\s+([0-9A-F:]+)\s+(.+)$/)
            if (!m) return
            var addr = m[1]
            var name = m[2]
            _seen.push(addr)
            // Kick off info fetch for each device
            infoFetcher.fetch(addr, name)
        }

        onRunningChanged: {
            if (running) _seen = []
        }
    }

    // ── Per-device info fetcher ───────────────────────────────────────────────

    QtObject {
        id: infoFetcher

        property var queue:   []
        property bool active: false

        function fetch(addr, name) {
            queue.push({ addr: addr, name: name })
            if (!active) next()
        }

        function next() {
            if (queue.length === 0) {
                active = false
                return
            }
            active = true
            var item = queue.shift()
            infoProc.addr = item.addr
            infoProc.pendingName = item.name
            infoProc.command = ["bluetoothctl", "info", item.addr]
            infoProc.running = true
        }
    }

    Process {
        id: infoProc
        running: false

        property string addr:        ""
        property string pendingName: ""
        property bool   _connected:  false
        property bool   _paired:     false
        property bool   _trusted:    false

        stdout: SplitParser {
            onRead: line => {
                var t = line.trim()
                if (t.startsWith("Connected:")) infoProc._connected = t.includes("yes")
                if (t.startsWith("Paired:"))    infoProc._paired    = t.includes("yes")
                if (t.startsWith("Trusted:"))   infoProc._trusted   = t.includes("yes")
            }
        }

        onRunningChanged: {
            if (running) {
                _connected = false
                _paired    = false
                _trusted   = false
                return
            }
            // Process finished — upsert device into root.devices
            var addr = infoProc.addr
            var existing = null
            for (var i = 0; i < root.devices.length; i++) {
                if (root.devices[i].address === addr) {
                    existing = root.devices[i]
                    break
                }
            }
            if (existing) {
                existing.connected = infoProc._connected
                existing.paired    = infoProc._paired
                existing.trusted   = infoProc._trusted
                existing.name      = infoProc.pendingName
            } else {
                var dev = deviceComponent.createObject(root, {
                    address:   addr,
                    name:      infoProc.pendingName,
                    connected: infoProc._connected,
                    paired:    infoProc._paired,
                    trusted:   infoProc._trusted
                })
                root.devices = root.devices.concat([dev])
            }
            infoFetcher.next()
        }
    }

    // ── Device component ──────────────────────────────────────────────────────

    Component {
        id: deviceComponent

        QtObject {
            property string address:   ""
            property string name:      ""
            property bool   connected: false
            property bool   paired:    false
            property bool   trusted:   false

            function connect() {
                connectProc.command = ["bluetoothctl", "connect", address]
                connectProc.running = true
            }

            function disconnect() {
                connectProc.command = ["bluetoothctl", "disconnect", address]
                connectProc.running = true
            }

            property Process connectProc: Process {
                running: false
                onRunningChanged: {
                    if (!running) {
                        showProc.running    = true
                        devicesProc.running = true
                    }
                }
            }
        }
    }

    // ── Public methods ────────────────────────────────────────────────────────

    function togglePower() {
        powerProc.command = ["bluetoothctl", "power", root._powered ? "off" : "on"]
        powerProc.running = true
        root._powered = !root._powered  // optimistic
    }

    function toggleDiscovery() {
        scanProc.command = ["bluetoothctl", root._scanning ? "scan off" : "scan on"]
        scanProc.running = true
    }

    function openSettings() {
        Qt.openUrlExternally("bluetooth:")
    }

    Process {
        id: powerProc
        running: false
        onRunningChanged: if (!running) showProc.running = true
    }

    Process {
        id: scanProc
        running: false
        command: ["bluetoothctl", "scan", "on"]
        onRunningChanged: if (!running) showProc.running = true
    }
}