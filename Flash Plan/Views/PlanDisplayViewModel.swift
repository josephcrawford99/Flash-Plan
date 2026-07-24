import Observation

enum SaveStatus: Equatable {
    case idle
    case saved
    case permissionDenied
    case failed
}

@MainActor
@Observable
final class PlanDisplayViewModel {
    let plan: FloorPlan
    private let router: AppRouter
    var status: SaveStatus = .idle

    init(plan: FloorPlan, router: AppRouter) {
        self.plan = plan
        self.router = router
    }

    func save() async {
        switch await FloorPlanExporter.save(plan) {
        case .saved: status = .saved
        case .permissionDenied: status = .permissionDenied
        case .failed: status = .failed
        }
    }

    func scanAgain() {
        router.startScan()
    }
}
