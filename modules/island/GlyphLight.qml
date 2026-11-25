import QtQuick
import QtQuick.Shapes
import qs.modules.components
import qs.modules.services

// Drawn inside the island's surface, which clips, so the stroke is inset by half its width: on the edge
// it would show half of itself. Three paths, so every light starts where it should with plain trims:
// a loop from the top centre (a notification's run) and the two sides from the bottom centre up to the
// top (the charger, and how far an activity has got).
Shape {
    id: root

    property real topRadius: 0
    property real bottomRadius: 0
    property real stroke: 3

    // charge, progress: how far up the sides; run: where the segment is, laps in its integer part
    property real rise: 0
    property real lap: 0
    property string kind: ""
    readonly property real level: Glyph.enabled && Activities.working ? Activities.level : -1
    readonly property bool lit: kind !== "" || level >= 0
    readonly property color tone: kind === "critical" ? Config.bad : Config.primary

    preferredRendererType: Shape.CurveRenderer

    function flash(k) {
        kind = k
        sweep.restart()
    }
    Connections {
        target: Glyph
        function onFlashed(kind) { root.flash(kind) }
    }

    SequentialAnimation {
        id: sweep
        PropertyAction { target: root; property: "opacity"; value: 1 }
        PropertyAction { target: root; properties: "rise,lap"; value: 0 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "rise"; to: 1; duration: Config.durationSweep; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "lap"; to: root.kind === "critical" ? 2 : 1; duration: Config.durationSweep * (root.kind === "critical" ? 2 : 1) }
        }
        NumberAnimation { target: root; property: "opacity"; to: 0; duration: Config.durationMedium }
        PropertyAction { target: root; property: "kind"; value: "" }
        PropertyAction { target: root; property: "opacity"; value: 1 }
    }

    // SVG, so a corner of radius 0 (a notch's top) can be a plain line
    readonly property real i: stroke / 2
    readonly property real rt: Math.max(0, Math.min(topRadius - i, width / 2 - i, height / 2 - i))
    readonly property real rb: Math.max(0, Math.min(bottomRadius - i, width / 2 - i, height / 2 - i))
    function corner(r, sweep, x, y) { return r > 0 ? ` A ${r} ${r} 0 0 ${sweep} ${x} ${y}` : ` L ${x} ${y}` }
    function side(dir) {
        const w = width, h = height, mid = w / 2, edge = dir > 0 ? w - i : i
        return `M ${mid} ${h - i} L ${edge - dir * rb} ${h - i}` + corner(rb, dir > 0 ? 0 : 1, edge, h - i - rb)
             + ` L ${edge} ${i + rt}` + corner(rt, dir > 0 ? 0 : 1, edge - dir * rt, i) + ` L ${mid} ${i}`
    }
    function loop() {
        const w = width, h = height
        return `M ${w / 2} ${i} L ${w - i - rt} ${i}` + corner(rt, 1, w - i, i + rt)
             + ` L ${w - i} ${h - i - rb}` + corner(rb, 1, w - i - rb, h - i)
             + ` L ${i + rb} ${h - i}` + corner(rb, 1, i, h - i - rb)
             + ` L ${i} ${i + rt}` + corner(rt, 1, i + rt, i) + " Z"
    }

    readonly property bool sides: kind === "charge" || (kind === "" && level >= 0)
    readonly property real reach: kind === "charge" ? rise : level

    component Light: ShapePath {
        strokeWidth: root.stroke
        strokeColor: root.tone
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
    }

    Light {
        strokeColor: root.sides ? root.tone : "transparent"
        trim.end: root.reach
        PathSvg { path: root.sides ? root.side(1) : "" }
    }
    Light {
        strokeColor: root.sides ? root.tone : "transparent"
        trim.end: root.reach
        PathSvg { path: root.sides ? root.side(-1) : "" }
    }
    // a fifth of the way round, centred on where it is
    Light {
        strokeColor: root.kind === "run" || root.kind === "critical" ? root.tone : "transparent"
        trim.start: 0
        trim.end: 0.2
        trim.offset: (root.lap + 0.9) % 1
        PathSvg { path: root.kind === "run" || root.kind === "critical" ? root.loop() : "" }
    }
}
