import CoreGraphics
import RoomPlan
import simd

enum RoomProjection {
    static func floorPlan(from room: CapturedRoom) -> FloorPlan {
        let walls = room.walls.map { surface -> Wall in
            let (start, end) = endpoints(of: surface)
            return Wall(start: start, end: end)
        }
        let windows = room.windows.map { surface -> Window in
            let (start, end) = endpoints(of: surface)
            return Window(start: start, end: end)
        }
        let interior = centroid(of: walls)
        let doors = room.doors.map { surface -> Door in
            let (start, end) = endpoints(of: surface)
            return Door(start: start, end: end, swing: swing(start: start, end: end, toward: interior))
        }
        let plan = FloorPlan(walls: walls, doors: doors, windows: windows)
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
        let move = { (p: CGPoint) in
            CGPoint(x: p.x * cosR - p.y * sinR, y: p.x * sinR + p.y * cosR)
        }
        return transformed(plan, by: move)
    }

    private static func normalized(_ plan: FloorPlan) -> FloorPlan {
        let points = plan.walls.flatMap { [$0.start, $0.end] }
            + plan.doors.flatMap { [$0.start, $0.end, $0.swing] }
            + plan.windows.flatMap { [$0.start, $0.end] }
        guard let minX = points.map(\.x).min(), let minY = points.map(\.y).min() else { return plan }
        return transformed(plan) { CGPoint(x: $0.x - minX, y: $0.y - minY) }
    }

    private static func transformed(_ plan: FloorPlan, by move: (CGPoint) -> CGPoint) -> FloorPlan {
        FloorPlan(
            walls: plan.walls.map { $0.transformed(by: move) },
            doors: plan.doors.map { $0.transformed(by: move) },
            windows: plan.windows.map { $0.transformed(by: move) }
        )
    }

    private static func endpoints(of surface: CapturedRoom.Surface) -> (CGPoint, CGPoint) {
        let transform = surface.transform
        let center = planPoint(transform.columns.3)
        let direction = planAxis(transform.columns.0)
        let half = Double(surface.dimensions.x) / 2
        let start = CGPoint(x: center.x - direction.x * half, y: center.y - direction.y * half)
        let end = CGPoint(x: center.x + direction.x * half, y: center.y + direction.y * half)
        return (start, end)
    }

    // The one and only world->plan mapping. RoomPlan is right-handed with -Z forward;
    // plan space is y-up (top of drawing = +y). This reflection is applied here alone.
    private static func planPoint(_ c: SIMD4<Float>) -> CGPoint {
        CGPoint(x: Double(c.x), y: -Double(c.z))
    }

    private static func planAxis(_ c: SIMD4<Float>) -> CGPoint {
        let a = simd_normalize(SIMD3<Float>(c.x, c.y, c.z))
        return CGPoint(x: Double(a.x), y: -Double(a.z))
    }

    private static func centroid(of walls: [Wall]) -> CGPoint {
        let points = walls.flatMap { [$0.start, $0.end] }
        guard !points.isEmpty else { return .zero }
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }

    // The door leaf's open tip: hinged at start, swung a quarter turn into the room.
    // Interior side is the side of the door's wall where the room centroid lies, so the
    // swing is correct regardless of the projection's handedness.
    private static func swing(start: CGPoint, end: CGPoint, toward interior: CGPoint) -> CGPoint {
        let axis = CGPoint(x: end.x - start.x, y: end.y - start.y)
        let width = hypot(axis.x, axis.y)
        guard width > 0 else { return start }
        var perp = CGPoint(x: -axis.y / width, y: axis.x / width)
        let toInterior = CGPoint(x: interior.x - start.x, y: interior.y - start.y)
        if perp.x * toInterior.x + perp.y * toInterior.y < 0 {
            perp = CGPoint(x: -perp.x, y: -perp.y)
        }
        return CGPoint(x: start.x + perp.x * width, y: start.y + perp.y * width)
    }
}
