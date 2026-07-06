import Foundation
import CoreGraphics

struct Wall: Codable, Hashable {
    let start: CGPoint
    let end: CGPoint

    var length: Double {
        Double(hypot(end.x - start.x, end.y - start.y))
    }
}

enum OpeningKind: Codable {
    case door
    case window
}

struct Opening: Codable, Hashable {
    let kind: OpeningKind
    let start: CGPoint
    let end: CGPoint
}

struct FloorPlan: Codable, Hashable {
    let walls: [Wall]
    let openings: [Opening]

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
        openings: [
            Opening(kind: .door, start: CGPoint(x: 1, y: 0), end: CGPoint(x: 1.9, y: 0)),
            Opening(kind: .window, start: CGPoint(x: 4, y: 1), end: CGPoint(x: 4, y: 2))
        ]
    )
}
#endif
