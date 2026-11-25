import QtQuick
import qs.modules.components
import qs.modules.parts

Item {
    implicitWidth: 440
    implicitHeight: 72

    BrightnessSlider {
        anchors { fill: parent; margins: Config.spaceM }
        activeFocusOnTab: false
    }
}
