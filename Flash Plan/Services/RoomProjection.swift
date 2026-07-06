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
        return normalized(FloorPlan(walls: walls, openings: doors + windows))
    }

    private static func endpoints(of surface: CapturedRoom.Surface) -> (CGPoint, CGPoint) {
        let transform = surface.transform
        let center = CGPoint(x: Double(transform.columns.3.x), y: Double(transform.columns.3.z))
        let axis = simd_normalize(SIMD3<Float>(transform.columns.0.x, transform.columns.0.y, transform.columns.0.z))
        let direction = CGPoint(x: Double(axis.x), y: Double(axis.z))
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
