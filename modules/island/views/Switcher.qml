import QtQuick
import qs.modules.parts
import qs.modules.components

// A capsule as tall as the clock, so the island only stretches sideways.
Item {
    implicitWidth: dots.implicitWidth + 40
    implicitHeight: 36

    // the glass may be clear: what the capsule shows sits on a capsule of its own
    Rectangle {
        anchors { fill: parent; margins: Config.spaceXs }
        radius: height / 2
        color: Config.tile
    }

    WorkspaceDots {
        id: dots
        anchors.centerIn: parent
        clickable: true
    }
}
