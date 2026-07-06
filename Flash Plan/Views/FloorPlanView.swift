import SwiftUI

struct FloorPlanView: View {
    let plan: FloorPlan

    var body: some View {
        Canvas { context, size in
            let geometry = PlanGeometry(plan: plan, size: size)
            drawWalls(&context, geometry)
            drawOpenings(&context, geometry)
            drawLengths(&context, geometry)
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

    private func drawOpenings(_ context: inout GraphicsContext, _ geometry: PlanGeometry) {
        for opening in plan.openings {
            let start = geometry.point(opening.start)
            let end = geometry.point(opening.end)
            var gap = Path()
            gap.move(to: start)
            gap.addLine(to: end)
            context.stroke(gap, with: .color(.white), style: StrokeStyle(lineWidth: 5))

            switch opening.kind {
            case .door:
                context.stroke(doorArc(from: start, to: end), with: .color(.gray), lineWidth: 1)
            case .window:
                context.stroke(gap, with: .color(.blue), lineWidth: 2)
            }
        }
    }

    private func drawLengths(_ context: inout GraphicsContext, _ geometry: PlanGeometry) {
        for wall in plan.walls where wall.length > 0.3 {
            let midpoint = CGPoint(x: (wall.start.x + wall.end.x) / 2, y: (wall.start.y + wall.end.y) / 2)
            let label = Text(lengthLabel(wall.length))
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            context.draw(label, at: geometry.point(midpoint))
        }
    }

    private func drawReadout(_ context: inout GraphicsContext, _ size: CGSize) {
        let label = Text("Area \(areaLabel(plan.area))    Perimeter \(lengthLabel(plan.perimeter))")
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.primary)
        context.draw(label, at: CGPoint(x: size.width / 2, y: size.height - 18))
    }

    private func doorArc(from start: CGPoint, to end: CGPoint) -> Path {
        let radius = hypot(end.x - start.x, end.y - start.y)
        let angle = atan2(end.y - start.y, end.x - start.x)
        var path = Path()
        path.move(to: end)
        path.addArc(
            center: start,
            radius: radius,
            startAngle: .radians(Double(angle)),
            endAngle: .radians(Double(angle) - .pi / 2),
            clockwise: true
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

#Preview {
    FloorPlanView(plan: .sample)
}
