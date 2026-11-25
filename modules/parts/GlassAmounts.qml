import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.services

// Liquid glass's own settings for the island or the windows (`which`): the tint in full, the bend and the light.
Column {
    id: glass
    property string which: "windows"
    readonly property color tint: glass.parse(Glass.glassValue(which, "tint_color"))
    function setTint(c) { Glass.setGlass(which, "tint_color", glass.hexa(c)) }
    // "#rrggbbaa", as hyprglass and the settings keep a colour, to a colour, and back
    function parse(hex) {
        const h = String(hex ?? "").replace("#", "")
        const n = i => parseInt(h.substr(i, 2), 16) / 255
        return h.length >= 6 ? Qt.rgba(n(0), n(2), n(4), h.length >= 8 ? n(6) : 1) : Qt.rgba(0, 0, 0, 0)
    }
    function hexa(c) { return Config.hex(c) + Math.round(c.a * 255).toString(16).padStart(2, "0") }
    width: parent ? parent.width : 0
    spacing: 4

    Amount {
        text: "Tint"
        value: glass.tint.a
        onCommitted: v => glass.setTint(Qt.rgba(glass.tint.r, glass.tint.g, glass.tint.b, v))
    }
    Rectangle {
        visible: Toggles.has("hyprpicker")
        width: parent.width
        height: 56
        radius: 22
        color: Config.tile
        Label { x: Config.spaceL; anchors.verticalCenter: parent.verticalCenter; text: "Tint from the screen"; color: Config.dim }
        EyedropButton {
            anchors { right: parent.right; rightMargin: Config.spaceL; verticalCenter: parent.verticalCenter }
            onClicked: { const v = Engine.view, t = "hg:" + glass.which + ":shared:tint_color"; Engine.closeThen(() => Toggles.pickColour(t, v)) }
        }
    }
    TintBar {
        text: "Tint hue"
        value: Math.max(0, glass.tint.hslHue)
        colourAt: t => Qt.hsla(t, 0.7, 0.55, 1)
        onMoved: v => glass.setTint(Qt.hsla(v, Math.max(0.01, glass.tint.hslSaturation), glass.tint.hslLightness, glass.tint.a))
    }
    TintBar {
        text: "Tint saturation"
        value: glass.tint.hslSaturation
        colourAt: t => Qt.hsla(Math.max(0, glass.tint.hslHue), t, 0.5, 1)
        onMoved: v => glass.setTint(Qt.hsla(Math.max(0, glass.tint.hslHue), v, glass.tint.hslLightness, glass.tint.a))
    }
    TintBar {
        text: "Tint lightness"
        value: glass.tint.hslLightness
        colourAt: t => Qt.hsla(Math.max(0, glass.tint.hslHue), glass.tint.hslSaturation, t, 1)
        onMoved: v => glass.setTint(Qt.hsla(Math.max(0, glass.tint.hslHue), glass.tint.hslSaturation, v, glass.tint.a))
    }
    Amount {
        text: "Refraction"
        value: Number(Glass.glassValue(glass.which, "refraction_strength")) / 10
        valueText: Number(Glass.glassValue(glass.which, "refraction_strength")).toFixed(1)
        onCommitted: v => Glass.setGlass(glass.which, "refraction_strength", Math.round(v * 100) / 10)
    }
    Amount {
        text: "Highlight"
        value: Number(Glass.glassValue(glass.which, "specular_strength"))
        onCommitted: v => Glass.setGlass(glass.which, "specular_strength", Math.round(v * 100) / 100)
    }
    Amount {
        text: "Edge glow"
        value: Number(Glass.glassValue(glass.which, "fresnel_strength"))
        onCommitted: v => Glass.setGlass(glass.which, "fresnel_strength", Math.round(v * 100) / 100)
    }
    ListEntry {
        flat: true
        icon: "restart_alt"
        title: "Back to the look's own"
        subtitle: "Tint, refraction, highlight and glow as " + (Glass.presets.find(p => p.key === Glass.preset)?.label ?? Glass.preset) + " has them"
        onClicked: Glass.resetGlass(glass.which, ["tint_color", "refraction_strength", "specular_strength", "fresnel_strength", "blur_strength", "blur_iterations"])
    }
}
