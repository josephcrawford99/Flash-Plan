import Observation

enum Route: Equatable {
    case home
    case scanning
    case result(FloorPlan)
}

@MainActor
@Observable
final class AppRouter {
    var route: Route = .home
    var scanMessage = ""

    func startScan() {
        scanMessage = ""
        route = .scanning
    }

    func finish(_ plan: FloorPlan) {
        if plan.isEmpty {
            scanMessage = "That scan did not catch a full room. Try walking around the whole space."
            route = .home
        } else {
            route = .result(plan)
        }
    }

    func fail(_ message: String) {
        scanMessage = message
        route = .home
    }
}
