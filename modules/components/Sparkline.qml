import QtQuick
import QtQuick.Shapes

// A history as a line over a faint fill, oldest at the left edge and newest at the right. It always
// spans the width: the readings start when the view opens, and a few seconds drawn to scale would be
// a sliver at the edge. `max` 0: the scale follows the largest value, for rates.
Shape {
    id: root

    property var values: []
    property real max: 1
    property color color: Config.primary

    readonly property real ceiling: max > 0 ? max : Math.max(1, ...values)
    readonly property var points: {
        const step = width / Math.max(1, values.length - 1), line = 2
        return values.map((v, i) => Qt.point(i * step,
                                             line / 2 + (height - line) * (1 - Math.max(0, Math.min(1, v / ceiling)))))
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: "transparent"
        fillColor: Qt.rgba(root.color.r, root.color.g, root.color.b, 0.16)
        PathPolyline {
            path: root.points.length < 2 ? []
                : [Qt.point(root.points[0].x, root.height)].concat(root.points, [Qt.point(root.width, root.height)])
        }
    }
    ShapePath {
        strokeColor: root.points.length < 2 ? "transparent" : root.color
        strokeWidth: 2
        fillColor: "transparent"
        joinStyle: ShapePath.RoundJoin
        capStyle: ShapePath.RoundCap
        PathPolyline { path: root.points }
    }
}
