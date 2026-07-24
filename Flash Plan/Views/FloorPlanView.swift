import SwiftUI

struct FloorPlanView: View {
    let plan: FloorPlan

    var body: some View {
        Canvas { context, size in
            let geometry = PlanGeometry(plan: plan, size: size)
            drawWalls(&context, geometry)
            drawWindows(&context, geometry)
            drawDoors(&context, geometry)
            drawLabels(&context, geometry, size)
            drawReadout(&context, size)
        }
        .background(.white)
    }

    private func drawWalls(_ context: inout GraphicsContext, _ geometry: PlanGeometry) {
        var path = Path()
        for wall in plan.walls {
            path.move(to: geometry.point(wall.start))
            path.addLine(to: geometry.point(wall.end))
        }
        context.stroke(path, with: .color(.black), style: StrokeStyle(lineWidth: 3, lineCap: .round))
    }

    private func drawWindows(_ context: inout GraphicsContext, _ geometry: PlanGeometry) {
        for window in plan.windows {
            var gap = Path()
            gap.move(to: geometry.point(window.start))
            gap.addLine(to: geometry.point(window.end))
            context.stroke(gap, with: .color(.white), style: StrokeStyle(lineWidth: 5))
            context.stroke(gap, with: .color(.blue), lineWidth: 2)
        }
    }

    private func drawDoors(_ context: inout GraphicsContext, _ geometry: PlanGeometry) {
        for door in plan.doors {
            let hinge = geometry.point(door.start)
            let closed = geometry.point(door.end)
            let open = geometry.point(door.swing)
            var gap = Path()
            gap.move(to: hinge)
            gap.addLine(to: closed)
            context.stroke(gap, with: .color(.white), style: StrokeStyle(lineWidth: 5))
            context.stroke(doorArc(hinge: hinge, from: closed, to: open), with: .color(.gray), lineWidth: 1)
        }
    }

    private func drawLabels(_ context: inout GraphicsContext, _ geometry: PlanGeometry, _ size: CGSize) {
        var placer = LabelPlacer(size: size)
        for wall in plan.walls {
            placer.addObstacle(geometry.point(wall.start), geometry.point(wall.end))
        }
        for window in plan.windows {
            placer.addObstacle(geometry.point(window.start), geometry.point(window.end))
        }
        for door in plan.doors {
            let hinge = geometry.point(door.start)
            placer.addObstacle(hinge, geometry.point(door.end))
            placer.addObstacle(hinge, geometry.point(door.swing))
        }
        placer.reserve(readoutRect(context, size))

        // Longest labels claim space first so wide text is placed before short text.
        for request in labelRequests(geometry).sorted(by: { $0.length > $1.length }) {
            let resolved = context.resolve(request.text)
            let center = placer.place(
                size: resolved.measure(in: size),
                anchor: request.anchor,
                normal: request.normal,
                tangent: request.tangent
            )
            context.draw(resolved, at: center)
        }
    }

    private func labelRequests(_ geometry: PlanGeometry) -> [LabelRequest] {
        var requests: [LabelRequest] = []
        for wall in plan.walls where wall.length > 0.3 {
            if let request = labelRequest(from: wall.start, to: wall.end, length: wall.length,
                                          color: Color(white: 0.35), geometry) {
                requests.append(request)
            }
        }
        for window in plan.windows {
            let length = Double(hypot(window.end.x - window.start.x, window.end.y - window.start.y))
            guard length > 0.3 else { continue }
            if let request = labelRequest(from: window.start, to: window.end, length: length,
                                          color: .blue, geometry) {
                requests.append(request)
            }
        }
        return requests
    }

    private func labelRequest(from start: CGPoint, to end: CGPoint, length: Double,
                              color: Color, _ geometry: PlanGeometry) -> LabelRequest? {
        let a = geometry.point(start)
        let b = geometry.point(end)
        let dx = b.x - a.x
        let dy = b.y - a.y
        let len = hypot(dx, dy)
        guard len > 0 else { return nil }
        let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
        var normal = CGPoint(x: -dy / len, y: dx / len)
        let outward = CGPoint(x: mid.x - geometry.center.x, y: mid.y - geometry.center.y)
        if normal.x * outward.x + normal.y * outward.y < 0 {
            normal = CGPoint(x: -normal.x, y: -normal.y)
        }
        let label = Text(lengthLabel(length))
            .font(.system(size: 11))
            .foregroundStyle(color)
        return LabelRequest(text: label, anchor: mid, normal: normal,
                            tangent: CGPoint(x: dx / len, y: dy / len), length: length)
    }

    private func drawReadout(_ context: inout GraphicsContext, _ size: CGSize) {
        context.draw(readoutText, at: CGPoint(x: size.width / 2, y: size.height - 18))
    }

    private var readoutText: Text {
        Text("Area \(areaLabel(plan.area))    Perimeter \(lengthLabel(plan.perimeter))")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.black)
    }

    private func readoutRect(_ context: GraphicsContext, _ size: CGSize) -> CGRect {
        let textSize = context.resolve(readoutText).measure(in: size)
        let center = CGPoint(x: size.width / 2, y: size.height - 18)
        return CGRect(x: center.x - textSize.width / 2, y: center.y - textSize.height / 2,
                      width: textSize.width, height: textSize.height)
    }

    private func doorArc(hinge: CGPoint, from closed: CGPoint, to open: CGPoint) -> Path {
        let radius = hypot(closed.x - hinge.x, closed.y - hinge.y)
        let closedAngle = atan2(closed.y - hinge.y, closed.x - hinge.x)
        let openAngle = atan2(open.y - hinge.y, open.x - hinge.x)
        var delta = openAngle - closedAngle
        while delta > .pi { delta -= 2 * .pi }
        while delta < -.pi { delta += 2 * .pi }
        var path = Path()
        path.move(to: closed)
        path.addArc(
            center: hinge,
            radius: radius,
            startAngle: .radians(Double(closedAngle)),
            endAngle: .radians(Double(closedAngle + delta)),
            clockwise: delta < 0
        )
        return path
    }
}

private struct PlanGeometry {
    private let bounds: CGRect
    private let scale: CGFloat
    private let offset: CGSize

    init(plan: FloorPlan, size: CGSize) {
        let padding: CGFloat = 40
        let points = plan.walls.flatMap { [$0.start, $0.end] }
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        let minX = xs.min() ?? 0
        let minY = ys.min() ?? 0
        let width = max((xs.max() ?? 1) - minX, 0.001)
        let height = max((ys.max() ?? 1) - minY, 0.001)
        bounds = CGRect(x: minX, y: minY, width: width, height: height)
        scale = min((size.width - padding * 2) / width, (size.height - padding * 2) / height)
        offset = CGSize(width: (size.width - width * scale) / 2, height: (size.height - height * scale) / 2)
    }

    func point(_ p: CGPoint) -> CGPoint {
        CGPoint(
            x: (p.x - bounds.minX) * scale + offset.width,
            y: (bounds.maxY - p.y) * scale + offset.height
        )
    }

    // Canvas-space center of the drawn plan, used to push length labels off the
    // wall toward the exterior rather than into the room.
    var center: CGPoint { point(CGPoint(x: bounds.midX, y: bounds.midY)) }
}

private struct LabelRequest {
    let text: Text
    let anchor: CGPoint
    let normal: CGPoint
    let tangent: CGPoint
    let length: Double
}

// Places measured labels so they clear the plan geometry, the readout, and each
// other. Candidates are tried outward-first, then inward, then slid along the wall;
// when nothing fits the least-bad position is used (best-effort).
private struct LabelPlacer {
    private let bounds: CGRect
    private var obstacles: [(CGPoint, CGPoint)] = []
    private var occupied: [CGRect] = []

    private let gaps: [CGFloat] = [10, 16, 22, 30, 40]
    private let slides: [CGFloat] = [0, 14, -14, 28, -28]
    private let margin: CGFloat = 4

    init(size: CGSize) {
        bounds = CGRect(origin: .zero, size: size).insetBy(dx: 4, dy: 4)
    }

    mutating func addObstacle(_ a: CGPoint, _ b: CGPoint) {
        obstacles.append((a, b))
    }

    mutating func reserve(_ rect: CGRect) {
        occupied.append(rect)
    }

    mutating func place(size labelSize: CGSize, anchor: CGPoint, normal: CGPoint, tangent: CGPoint) -> CGPoint {
        var best: (center: CGPoint, rect: CGRect, score: CGFloat)?
        for candidate in candidates(anchor: anchor, normal: normal, tangent: tangent) {
            let rect = CGRect(x: candidate.x - labelSize.width / 2, y: candidate.y - labelSize.height / 2,
                              width: labelSize.width, height: labelSize.height)
            let inBounds = bounds.contains(rect)
            let clearance = clearance(of: rect)
            if inBounds && clearance >= margin {
                occupied.append(rect)
                return candidate
            }
            let score = clearance - (inBounds ? 0 : 1000)
            if best == nil || score > best!.score {
                best = (candidate, rect, score)
            }
        }
        occupied.append(best!.rect)
        return best!.center
    }

    private func candidates(anchor: CGPoint, normal: CGPoint, tangent: CGPoint) -> [CGPoint] {
        var result: [CGPoint] = []
        for direction in [normal, CGPoint(x: -normal.x, y: -normal.y)] {
            for gap in gaps {
                for slide in slides {
                    result.append(CGPoint(
                        x: anchor.x + direction.x * gap + tangent.x * slide,
                        y: anchor.y + direction.y * gap + tangent.y * slide
                    ))
                }
            }
        }
        return result
    }

    private func clearance(of rect: CGRect) -> CGFloat {
        var minDistance = CGFloat.greatestFiniteMagnitude
        for (a, b) in obstacles {
            minDistance = min(minDistance, rectSegmentDistance(rect, a, b))
        }
        for other in occupied {
            minDistance = min(minDistance, rectRectDistance(rect, other))
        }
        return minDistance
    }
}

private func rectRectDistance(_ r1: CGRect, _ r2: CGRect) -> CGFloat {
    if r1.intersects(r2) { return 0 }
    let dx = max(0, max(r1.minX - r2.maxX, r2.minX - r1.maxX))
    let dy = max(0, max(r1.minY - r2.maxY, r2.minY - r1.maxY))
    return hypot(dx, dy)
}

private func rectSegmentDistance(_ rect: CGRect, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
    if rect.contains(a) || rect.contains(b) { return 0 }
    let corners = [
        CGPoint(x: rect.minX, y: rect.minY), CGPoint(x: rect.maxX, y: rect.minY),
        CGPoint(x: rect.maxX, y: rect.maxY), CGPoint(x: rect.minX, y: rect.maxY)
    ]
    var minDistance = CGFloat.greatestFiniteMagnitude
    for i in 0..<4 {
        minDistance = min(minDistance, segmentSegmentDistance(a, b, corners[i], corners[(i + 1) % 4]))
    }
    return minDistance
}

private func segmentSegmentDistance(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint, _ d: CGPoint) -> CGFloat {
    if segmentsIntersect(a, b, c, d) { return 0 }
    return min(
        min(pointSegmentDistance(a, c, d), pointSegmentDistance(b, c, d)),
        min(pointSegmentDistance(c, a, b), pointSegmentDistance(d, a, b))
    )
}

private func pointSegmentDistance(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
    let dx = b.x - a.x
    let dy = b.y - a.y
    let lengthSquared = dx * dx + dy * dy
    guard lengthSquared > 0 else { return hypot(p.x - a.x, p.y - a.y) }
    let t = max(0, min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / lengthSquared))
    return hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy))
}

private func segmentsIntersect(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint) -> Bool {
    func orientation(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
        (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
    }
    let d1 = orientation(p3, p4, p1)
    let d2 = orientation(p3, p4, p2)
    let d3 = orientation(p1, p2, p3)
    let d4 = orientation(p1, p2, p4)
    return ((d1 > 0) != (d2 > 0)) && ((d3 > 0) != (d4 > 0))
}

private let unitFormatter: MeasurementFormatter = {
    let formatter = MeasurementFormatter()
    formatter.unitOptions = .providedUnit
    formatter.numberFormatter.maximumFractionDigits = 1
    return formatter
}()

private let usesMetric = Locale.current.measurementSystem == .metric

private func lengthLabel(_ meters: Double) -> String {
    let measurement = Measurement(value: meters, unit: UnitLength.meters)
    return unitFormatter.string(from: usesMetric ? measurement : measurement.converted(to: .feet))
}

private func areaLabel(_ squareMeters: Double) -> String {
    let measurement = Measurement(value: squareMeters, unit: UnitArea.squareMeters)
    return unitFormatter.string(from: usesMetric ? measurement : measurement.converted(to: .squareFeet))
}

#Preview("Sample") {
    FloorPlanView(plan: .sample)
}

#Preview("Concave") {
    FloorPlanView(plan: .concaveSample)
}

private extension FloorPlan {
    // Exercises the label solver: a concave L-shape with two near-parallel walls,
    // two windows, and a door, so labels must deconflict with geometry and each other.
    static var concaveSample: FloorPlan {
        let corners: [CGPoint] = [
            CGPoint(x: 0, y: 0), CGPoint(x: 5.2, y: 0), CGPoint(x: 5.2, y: 1.8),
            CGPoint(x: 2.1, y: 1.8), CGPoint(x: 2.1, y: 4.6), CGPoint(x: 0, y: 4.6)
        ]
        var walls: [Wall] = []
        for i in 0..<corners.count {
            walls.append(Wall(start: corners[i], end: corners[(i + 1) % corners.count]))
        }
        let doors = [Door(start: CGPoint(x: 1, y: 0), end: CGPoint(x: 2, y: 0), swing: CGPoint(x: 1, y: 1))]
        let windows = [
            Window(start: CGPoint(x: 0, y: 1.5), end: CGPoint(x: 0, y: 3)),
            Window(start: CGPoint(x: 3, y: 1.8), end: CGPoint(x: 4.2, y: 1.8))
        ]
        return FloorPlan(walls: walls, doors: doors, windows: windows)
    }
}
