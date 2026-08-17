// services/BrightnessService.qml
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool available:  _max > 0
    // Visual percentage: reflects the pending drag if there is one, else confirmed device state
    readonly property int percentage: _dragPercent >= 0 ? _dragPercent : (_max > 0 ? Math.round((_current / _max) * 100) : 0)
    readonly property string lastError: _lastError

    property int _current: 0
    property int _max:     100
    property int _dragPercent: -1   // -1 = not dragging, show confirmed value
    property string _lastError: ""

    Timer {
        interval: 3000
        running:  true
        repeat:   true
        onTriggered: getCurrentProc.running = true
    }

    Component.onCompleted: {
        getMaxProc.running = true
        getCurrentProc.running = true
    }

    Process {
        id: getMaxProc
        command: ["brightnessctl", "m"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                var v = parseInt(line.trim(), 10)
                if (!isNaN(v) && v > 0) root._max = v
            }
        }
    }

    Process {
        id: getCurrentProc
        command: ["brightnessctl", "g"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                var v = parseInt(line.trim(), 10)
                if (!isNaN(v)) root._current = v
            }
        }
    }

    Timer {
        id: setDebounce
        interval: 60
        repeat: false
        onTriggered: {
            setProc._stderr = ""
            setProc.command = ["brightnessctl", "set", root._dragPercent + "%"]
            setProc.running = true
        }
    }

    // Called continuously while dragging — updates the visual instantly,
    // debounces the actual brightnessctl call.
    function setPercentage(pct) {
        pct = Math.max(1, Math.min(100, Math.round(pct)))
        _dragPercent = pct
        setDebounce.restart()
    }

    // Call this on mouse release so we fall back to confirmed device state
    // (and correctly reflect a failed set instead of sticking to the drag value).
    function commit() {
        setDebounce.stop()
        setProc._stderr = ""
        setProc.command = ["brightnessctl", "set", root._dragPercent + "%"]
        setProc.running = true
    }

    Process {
        id: setProc
        running: false
        property string _stderr: ""

        stderr: SplitParser {
            onRead: line => setProc._stderr += line + "\n"
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root._lastError = "brightnessctl set failed (exit " + exitCode + "): "
                    + (setProc._stderr.trim() || "no permission? check udev rules / video group")
                console.warn(root._lastError)
            } else {
                root._lastError = ""
            }
            root._dragPercent = -1   // release the drag override, show confirmed value
            getCurrentProc.running = true
        }
    }
}