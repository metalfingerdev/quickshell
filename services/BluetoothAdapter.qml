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

    // Global error surfaced to the UI (e.g. failed connect/pair). Cleared on next successful op.
    property string lastError: ""

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
            if (running) {
                _seen = []
            } else {
                // Finished — prune devices no longer reported by bluetoothctl,
                // unless they're mid-operation (busy) which means they're likely
                // fresh entries not yet reflected in the next poll.
                var seen = _seen
                var kept = []
                for (var i = 0; i < root.devices.length; i++) {
                    var d = root.devices[i]
                    if (seen.indexOf(d.address) !== -1 || d.busy) {
                        kept.push(d)
                    } else {
                        d.destroy()
                    }
                }
                if (kept.length !== root.devices.length) {
                    root.devices = kept
                }
            }
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
        property int    _battery:    -1

        stdout: SplitParser {
            onRead: line => {
                var t = line.trim()
                if (t.startsWith("Connected:")) infoProc._connected = t.includes("yes")
                if (t.startsWith("Paired:"))    infoProc._paired    = t.includes("yes")
                if (t.startsWith("Trusted:"))   infoProc._trusted   = t.includes("yes")
                if (t.startsWith("Battery Percentage:")) {
                    // Format: "Battery Percentage: 0x5a (90)"
                    var m = t.match(/\((\d+)\)/)
                    infoProc._battery = m ? parseInt(m[1], 10) : -1
                }
            }
        }

        onRunningChanged: {
            if (running) {
                _connected = false
                _paired    = false
                _trusted   = false
                _battery   = -1
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
                existing.battery   = infoProc._battery
                existing.name      = infoProc.pendingName
            } else {
                var dev = deviceComponent.createObject(root, {
                    address:   addr,
                    name:      infoProc.pendingName,
                    connected: infoProc._connected,
                    paired:    infoProc._paired,
                    trusted:   infoProc._trusted,
                    battery:   infoProc._battery
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
            id: dev

            property string address:   ""
            property string name:      ""
            property bool   connected: false
            property bool   paired:    false
            property bool   trusted:   false
            property int    battery:   -1 // -1 = unknown/not reported

            // UI-facing state
            property bool   busy:  false
            property string error: ""

            function connect() {
                error = ""
                busy = true
                if (!paired) {
                    // Pair (and trust) first, then connect once pairing finishes.
                    opProc.steps = [
                        ["pair", address],
                        ["trust", address],
                        ["connect", address]
                    ]
                } else {
                    opProc.steps = [["connect", address]]
                }
                opProc.runNext()
            }

            function disconnect() {
                error = ""
                busy = true
                opProc.steps = [["disconnect", address]]
                opProc.runNext()
            }

            function forget() {
                error = ""
                busy = true
                opProc.steps = [["remove", address]]
                opProc.runNext()
            }

            // Runs a sequence of bluetoothctl subcommands against this device,
            // stopping and surfacing an error if any step fails.
            property QtObject opProc: QtObject {
                property var steps: []
                property string _lastOutput: ""

                function runNext() {
                    if (steps.length === 0) {
                        dev.busy = false
                        if (dev.address) {
                            showProc.running    = true
                            devicesProc.running = true
                        }
                        return
                    }
                    var step = steps.shift()
                    _lastOutput = ""
                    proc.command = ["bluetoothctl"].concat(step)
                    proc.running = true
                }

                property Process proc: Process {
                    running: false
                    stdout: SplitParser {
                        onRead: line => { opProc._lastOutput += line + "\n" }
                    }
                    onRunningChanged: {
                        if (running) return
                        var out = opProc._lastOutput.toLowerCase()
                        if (out.indexOf("fail") !== -1 || out.indexOf("error") !== -1) {
                            dev.error = "Operation failed: " + opProc._lastOutput.trim()
                            root.lastError = dev.error
                            dev.busy = false
                            opProc.steps = []
                            showProc.running    = true
                            devicesProc.running = true
                            return
                        }
                        if (step_was_remove(opProc)) {
                            // Device removed — drop it from the list immediately.
                            var kept = []
                            for (var i = 0; i < root.devices.length; i++) {
                                if (root.devices[i].address !== dev.address) kept.push(root.devices[i])
                            }
                            root.devices = kept
                            dev.destroy()
                            return
                        }
                        opProc.runNext()
                    }
                }

                function step_was_remove(op) {
                    // Best-effort check: if the last issued command was "remove".
                    return op.proc.command.indexOf("remove") !== -1
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
        if (root._scanning) {
            // "scan on" blocks until killed — stop it by tearing down the process.
            scanProc.running = false
            root._scanning = false
            offProc.command = ["bluetoothctl", "scan", "off"]
            offProc.running = true
        } else {
            scanProc.command = ["bluetoothctl", "scan", "on"]
            scanProc.running = true
            root._scanning = true
        }
    }

    function openSettings() {
        Qt.openUrlExternally("bluetooth:")
    }

    Process {
        id: powerProc
        running: false
        onRunningChanged: if (!running) showProc.running = true
    }

    // Long-running "scan on" process. Killed by setting running: false.
    Process {
        id: scanProc
        running: false
        onRunningChanged: {
            showProc.running    = true
            devicesProc.running = true
        }
    }

    // Fire-and-forget "scan off" to make sure the adapter actually stops,
    // since killing scanProc only detaches our process, it doesn't guarantee
    // bluetoothd stopped discovery.
    Process {
        id: offProc
        running: false
        onRunningChanged: if (!running) { showProc.running = true; devicesProc.running = true }
    }
}