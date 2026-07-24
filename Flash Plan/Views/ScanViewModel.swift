import Observation
import UIKit

@MainActor
@Observable
final class ScanViewModel {
    private let router: AppRouter
    private(set) var controller: RoomCaptureController?
    var isReady = false

    init(router: AppRouter) {
        self.router = router
    }

    func prepare() {
        guard controller == nil else { return }
        let controller = RoomCaptureController()
        controller.onComplete = { [weak self] in self?.router.finish($0) }
        controller.onFailure = { [weak self] in self?.router.fail($0) }
        controller.onReady = { [weak self] in self?.isReady = true }
        self.controller = controller
    }

    func finishScan() {
        controller?.finish()
    }
}
