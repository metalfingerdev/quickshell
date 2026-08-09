import QtQuick
import Quickshell.Io
import qs.config
import qs.services

Rectangle {
  id: button

  signal requestSurface(string name, real anchorX)

  implicitWidth: 28
  implicitHeight: 28
  radius: Config.radius
  color: area.containsMouse ? Config.accent : Config.highlight

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    onClicked: {
      const anchorX = area.mapToItem(null, area.width / 2, 0).x
      requestSurface("notif", anchorX)
    }
  }

  Text {
    anchors.centerIn: parent
    color: area.containsMouse ? Config.bgDark : Config.foreground
    font.family: "Maple Mono"
    font.pixelSize: 14
    text: "\uf0f3"
  }
}