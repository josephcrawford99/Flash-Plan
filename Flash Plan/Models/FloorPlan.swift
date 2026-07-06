import Foundation
import CoreGraphics

protocol PlanFeature {
    func transformed(by move: (CGPoint) -> CGPoint) -> Self
}

struct Wall: Codable, Hashable, PlanFeature {
    let start: CGPoint
    let end: CGPoint

    var length: Double {
        Double(hypot(end.x - start.x, end.y - start.y))
    }

    func transformed(by move: (CGPoint) -> CGPoint) -> Wall {
        Wall(start: move(start), end: move(end))
    }
}

struct Door: Codable, Hashable, PlanFeature {
    let start: CGPoint
    let end: CGPoint
    let swing: CGPoint

    var width: Double {
        Double(hypot(end.x - start.x, end.y - start.y))
    }

    func transformed(by move: (CGPoint) -> CGPoint) -> Door {
        Door(start: move(start), end: move(end), swing: move(swing))
    }
}

struct Window: Codable, Hashable, PlanFeature {
    let start: CGPoint
    let end: CGPoint

    func transformed(by move: (CGPoint) -> CGPoint) -> Window {
        Window(start: move(start), end: move(end))
    }
}

struct FloorPlan: Codable, Hashable {
    let walls: [Wall]
    let doors: [Door]
    let windows: [Window]

    var isEmpty: Bool { walls.isEmpty }

    var perimeter: Double {
        walls.reduce(0) { $0 + $1.length }
    }

    var area: Double {
        let corners = orderedCorners
        guard corners.count >= 3 else { return 0 }
        let shoelace = corners.indices.reduce(0.0) { sum, i in
            let a = corners[i]
            let b = corners[(i + 1) % corners.count]
            return sum + Double(a.x * b.y - b.x * a.y)
        }
        return abs(shoelace) / 2
    }

    private var orderedCorners: [CGPoint] {
        var corners: [CGPoint] = []
        for point in walls.flatMap({ [$0.start, $0.end] }) {
            let isNew = !corners.contains { hypot($0.x - point.x, $0.y - point.y) < 0.05 }
            if isNew { corners.append(point) }
        }
        guard !corners.isEmpty else { return corners }
        let sum = corners.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        let centroid = CGPoint(x: sum.x / CGFloat(corners.count), y: sum.y / CGFloat(corners.count))
        return corners.sorted {
            atan2($0.y - centroid.y, $0.x - centroid.x) < atan2($1.y - centroid.y, $1.x - centroid.x)
        }
    }
}

#if DEBUG
extension FloorPlan {
    static let sample = FloorPlan(
        walls: [
            Wall(start: CGPoint(x: 0, y: 0), end: CGPoint(x: 4, y: 0)),
            Wall(start: CGPoint(x: 4, y: 0), end: CGPoint(x: 4, y: 3)),
            Wall(start: CGPoint(x: 4, y: 3), end: CGPoint(x: 0, y: 3)),
            Wall(start: CGPoint(x: 0, y: 3), end: CGPoint(x: 0, y: 0))
        ],
        doors: [
            Door(start: CGPoint(x: 1, y: 0), end: CGPoint(x: 1.9, y: 0), swing: CGPoint(x: 1, y: 0.9))
        ],
        windows: [
            Window(start: CGPoint(x: 4, y: 1), end: CGPoint(x: 4, y: 2))
        ]
    )
}
#endif
