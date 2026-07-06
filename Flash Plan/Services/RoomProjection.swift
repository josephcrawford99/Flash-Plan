import RoomPlan
import simd

enum RoomProjection {
    static func floorPlan(from room: CapturedRoom) -> FloorPlan {
        let walls = room.walls.map { surface -> Wall in
            let (start, end) = endpoints(of: surface)
            return Wall(start: start, end: end)
        }
        let doors = room.doors.map { opening(from: $0, kind: .door) }
        let windows = room.windows.map { opening(from: $0, kind: .window) }
        let plan = FloorPlan(walls: walls, openings: doors + windows)
        return normalized(uprighted(plan))
    }

    private static func uprighted(_ plan: FloorPlan) -> FloorPlan {
        guard let longest = plan.walls.max(by: { $0.length < $1.length }) else { return plan }
        let angle = atan2(longest.end.y - longest.start.y, longest.end.x - longest.start.x)
        return rotated(plan, by: .pi / 2 - Double(angle))
    }

    private static func rotated(_ plan: FloorPlan, by radians: Double) -> FloorPlan {
        let cosR = CGFloat(cos(radians))
        let sinR = CGFloat(sin(radians))
        func turn(_ p: CGPoint) -> CGPoint {
            CGPoint(x: p.x * cosR - p.y * sinR, y: p.x * sinR + p.y * cosR)
        }
        let walls = plan.walls.map { Wall(start: turn($0.start), end: turn($0.end)) }
        let openings = plan.openings.map { Opening(kind: $0.kind, start: turn($0.start), end: turn($0.end)) }
        return FloorPlan(walls: walls, openings: openings)
    }

    private static func endpoints(of surface: CapturedRoom.Surface) -> (CGPoint, CGPoint) {
        let transform = surface.transform
        // RoomPlan is right-handed with -Z forward. Negate Z so the plan is a y-up
        // space where +y is the top of the drawing, matching PlanGeometry.point.
        let center = CGPoint(x: Double(transform.columns.3.x), y: -Double(transform.columns.3.z))
        let axis = simd_normalize(SIMD3<Float>(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z))
        let direction = CGPoint(x: Double(axis.x), y: -Double(axis.z))
        let half = Double(surface.dimensions.x) / 2
        let start = CGPoint(x: center.x - direction.x * half, y: center.y - direction.y * half)
        let end = CGPoint(x: center.x + direction.x * half, y: center.y + direction.y * half)
        return (start, end)
    }

    private static func opening(from surface: CapturedRoom.Surface, kind: OpeningKind) -> Opening {
        let (start, end) = endpoints(of: surface)
        return Opening(kind: kind, start: start, end: end)
    }

    private static func normalized(_ plan: FloorPlan) -> FloorPlan {
        let points = plan.walls.flatMap { [$0.start, $0.end] } + plan.openings.flatMap { [$0.start, $0.end] }
        guard let minX = points.map(\.x).min(), let minY = points.map(\.y).min() else { return plan }
        func shifted(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x - minX, y: p.y - minY) }
        let walls = plan.walls.map { Wall(start: shifted($0.start), end: shifted($0.end)) }
        let openings = plan.openings.map { Opening(kind: $0.kind, start: shifted($0.start), end: shifted($0.end)) }
        return FloorPlan(walls: walls, openings: openings)
    }
}
