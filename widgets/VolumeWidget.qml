import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config

Item {
  property var close: function() {}

  MouseArea {
    anchors.fill: parent
    onClicked: close()
  }

  ColumnLayout {
    anchors.centerIn: parent
    spacing: 8

    Text {
      Layout.alignment: Qt.AlignHCenter
      text: "Volume"
      color: Config.foreground
      font.family: "Maple Mono"
      font.pixelSize: 48
      font.weight: Font.Light
    }

  }
}
