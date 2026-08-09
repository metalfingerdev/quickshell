import QtQuick
import Quickshell.Io
pragma Singleton

Item {
    id: root

    // Expose the bar arrays as accessible properties
    property var leftBars: Array(32).fill(0)
    property var rightBars: Array(32).fill(0)

    Process {
        id: cavaProcess

        running: true
        command: ["sh", "-c", "printf '[general]\\nbars=64\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\ndata_format=ascii\\nascii_max_range=1000\\n' > /tmp/qs_cava.conf && cava -p /tmp/qs_cava.conf"]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function(chunk) {
                if (!chunk)
                    return ;

                let parts = chunk.split(";");
                if (parts.length >= 64) {
                    let left = [];
                    let right = [];
                    for (let i = 0; i < 32; i++) {
                        left.push(Math.max(0, parseFloat(parts[i]) / 1000));
                        right.push(Math.max(0, parseFloat(parts[32 + i]) / 1000));
                    }
                    // Update the singleton's properties
                    root.leftBars = left;
                    root.rightBars = right;
                }
            }
        }

    }

}
