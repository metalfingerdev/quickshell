import QtQuick
import qs.modules.island
import qs.modules.components
import qs.modules.parts
import qs.modules.lock
import qs.modules.services

// Settings: what the island and the windows are made of, apart. The note under each group says what Hyprland really does.
Item {
    id: root

    readonly property int pad: 24
    readonly property int colW: 520

    implicitWidth: colW + 2 * pad
    implicitHeight: column.implicitHeight + 2 * pad

    // the Glass and blur page
    readonly property bool liquid: Glass.available && Glass.enabled
    Component.onCompleted: {
        Glass.readDescriptions()
        if (Toggles.pickBack.startsWith("hg:")) Toggles.pickBack = ""      // back from the eyedropper: it reopened this page
    }
    function hyprCurrent(key, fallback) { const o = Glass.descriptions.find(d => d.name === key); return o ? Number(o.current) : fallback }
    function hl(key, fallback) { const v = Glass.hl?.shared?.[key]; return v !== undefined ? Number(v) : hyprCurrent(key, fallback) }
    function setHl(key, value) {
        const all = Object.assign({ shared: {}, dark: {}, light: {} }, Glass.hl)
        all.shared = Object.assign({}, all.shared, { [key]: value })
        Glass.hl = all
    }
    readonly property real windowBlurShown: Glass.windowBlur >= 0 ? Glass.windowBlur
        : liquid ? Number(Glass.glassValue("windows", "blur_strength")) / 4 : hyprCurrent("decoration:blur:size", 8) / 16


    Column {
        id: column
        x: root.pad
        y: root.pad
        width: root.colW
        spacing: Config.spaceL

        Header {
            width: parent.width
            icon: "blur_on"
            title: "Glass and blur"
            subtitle: (Config.islandOpacity < 0 ? "Island like the windows" : "Island " + Math.round(Config.islandOpacity * 100) + " %")
                      + "  ·  " + (root.liquid ? "Liquid glass" : "Blur")
            onBack: Engine.back()
        }

        // Glass and blur: the island and the windows apart. A switch for a yes/no, a named choice for a kind,
        // a slider for an amount; each note says what Hyprland really does with it.
        ScrollList {
            width: parent.width
            maxHeight: Math.min(640, Engine.room - 200)
            spacing: Config.spaceL

            Column {
                width: parent.width
                spacing: Config.spaceM
                SectionLabel { text: "Material"; topPadding: Config.spaceS }
                Segmented {
                    width: parent.width
                    enabled: Glass.available
                    options: [{ key: "blur", label: "Blur", icon: "blur_on", shortcut: "b" }, { key: "glass", label: "Liquid glass", icon: "water_drop", shortcut: "g" }]
                    current: root.liquid ? "glass" : "blur"
                    onPicked: key => Glass.enabled = key === "glass"
                }
                Segmented {
                    visible: root.liquid
                    width: parent.width
                    height: visible ? implicitHeight : 0
                    options: Glass.presets
                    current: Glass.preset
                    onPicked: key => Glass.preset = key
                }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: !Glass.available ? "Liquid glass is the hyprglass plugin, which isn't loaded for this Hyprland: Hyprland's blur draws everything." : root.liquid ? "The look is where liquid glass starts; everything below changes it, for the island and the windows apart." : "Hyprland's blur. It has one blur for everything, so the island's follows the windows'."
                    color: Config.dim
                    font.pixelSize: Config.small
                }
            }

            Column {
                width: parent.width
                spacing: Config.spaceM
                SectionLabel { text: "Island"; topPadding: Config.spaceS }
                SettingTile {
                    width: parent.width
                    title: "Opacity like the windows"
                    icon: "opacity"
                    checked: Config.islandOpacity < 0
                    onFlipped: on => Config.islandOpacity = on ? -1 : Math.round(Config.windowOpacity * 100) / 100
                }
                Amount {
                    text: "Opacity"
                    enabled: Config.islandOpacity >= 0
                    value: Config.islandAlpha
                    onMoved: v => Config.islandOpacity = Math.round(v * 100) / 100
                }
                Amount {
                    text: "Cards and controls"
                    value: Config.surfaceAlpha
                    onMoved: v => Config.surfaceAlpha = Math.round(v * 100) / 100
                }
                Amount {
                    text: "Blur"
                    enabled: root.liquid
                    value: Glass.islandBlur >= 0 ? Glass.islandBlur : root.windowBlurShown
                    valueText: !root.liquid || Glass.islandBlur < 0 ? "Like the windows" : Math.round(value * 100) + "%"
                    onCommitted: v => Glass.islandBlur = Math.round(v * 100) / 100
                }
                Amount {
                    text: "Shadow"
                    value: Config.shadowStrength
                    onMoved: v => Config.shadowStrength = Math.round(v * 100) / 100
                }
                GlassAmounts { which: "island"; visible: root.liquid }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: "At 0% the island still holds its shape, so the glass and the blur stay; only its own colour is gone."
                    color: Config.dim
                    font.pixelSize: Config.small
                }
            }

            Column {
                width: parent.width
                spacing: Config.spaceM
                SectionLabel { text: "Windows"; topPadding: Config.spaceS }
                Amount {
                    text: "Opacity"
                    value: Glass.activeOpacity >= 0 ? Glass.activeOpacity : Config.windowOpacity
                    onCommitted: v => Glass.activeOpacity = Math.round(v * 100) / 100
                }
                Amount {
                    text: "Opacity when inactive"
                    value: Glass.inactiveOpacity >= 0 ? Glass.inactiveOpacity : root.hyprCurrent("decoration:inactive_opacity", Config.windowOpacity)
                    onCommitted: v => Glass.inactiveOpacity = Math.round(v * 100) / 100
                }
                Amount {
                    text: "Blur"
                    value: root.windowBlurShown
                    onCommitted: v => Glass.windowBlur = Math.round(v * 100) / 100
                }
                Amount {
                    visible: !root.liquid
                    text: "Vibrancy"
                    value: root.hl("decoration:blur:vibrancy", 0.17)
                    onCommitted: v => root.setHl("decoration:blur:vibrancy", Math.round(v * 100) / 100)
                }
                Amount {
                    visible: !root.liquid
                    text: "Brightness"
                    value: root.hl("decoration:blur:brightness", 1) / 2
                    valueText: Math.round(value * 200) + "%"
                    onCommitted: v => root.setHl("decoration:blur:brightness", Math.round(v * 200) / 100)
                }
                Amount {
                    visible: !root.liquid
                    text: "Contrast"
                    value: root.hl("decoration:blur:contrast", 0.9) / 2
                    valueText: Math.round(value * 200) + "%"
                    onCommitted: v => root.setHl("decoration:blur:contrast", Math.round(v * 200) / 100)
                }
                GlassAmounts { which: "windows"; visible: root.liquid }
                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: "Video players, Firefox and qimgv stay opaque (hypr/modules/rules.lua), so opacity doesn't show on them."
                    color: Config.dim
                    font.pixelSize: Config.small
                }
            }

            Column {
                width: parent.width
                spacing: Config.spaceM
                SectionLabel { text: "Shape and motion"; topPadding: Config.spaceS }
                Amount {
                    text: "Roundness"
                    value: Config.roundness - 0.5
                    valueText: Math.round(Config.roundness * 100) + "%"
                    onMoved: v => Config.roundness = Math.round((0.5 + v) * 20) / 20
                }
                SettingTile {
                    width: parent.width
                    title: "Reduce motion"
                    icon: "animation"
                    checked: Config.reduceMotion
                    onFlipped: on => Config.reduceMotion = on
                }
            }
        }

        KeyHints {
            width: parent.width
            keys: [["← →", "adjust"], ["B G", "material"], ["⌫", "back"], ["Esc", "close"]]
        }
    }
}
