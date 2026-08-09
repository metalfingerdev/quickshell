import QtQuick
import qs.config
import qs.services

Rectangle {
  id: button

  signal requestSurface(string name, real anchorX)

  implicitWidth: text.implicitWidth + 12
  implicitHeight: 28
  radius: Config.radius
  color: area.containsMouse ? Config.accent : Config.highlight

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    onClicked: {
      const anchorX = area.mapToItem(null, area.width / 2, 0).x
      requestSurface("volume", anchorX)
    }
  }

  Text {
    id: text
    anchors.centerIn: parent
    color: area.containsMouse ? Config.bgDark : Config.foreground
    font.family: "Maple Mono"
    font.pixelSize: 14
    text: {
      if (Pipewire.muted) return "󰝟";
      const v = Pipewire.volume;
      if (v == 0) return "󰝟";
      if (v < 0.3) return "󰕿";
      if (v < 0.6) return "󰖀";
      return "󰕾";
    }
  }
}