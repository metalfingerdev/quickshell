import QtQuick

// A yes/no, as the Control Centre has them: a wide tile with its icon in a circle and its state under the name.
// On, the whole tile takes the accent and rounds out to a pill. A click, Space or Enter flips it.
QuickTile {
    id: root

    property bool checked: false
    property string detail: ""               // under the name; "On" or "Off" when there's nothing to add
    signal flipped(bool on)

    on: checked
    subtitle: detail !== "" ? detail : checked ? "On" : "Off"
    implicitHeight: 60
    radius: on ? height / 2 : 22
    Behavior on radius { Motion {} }
    onToggled: flipped(!checked)
}
