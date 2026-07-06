import UIKit
import RoomPlan

@MainActor
final class RoomScanSession: RoomCaptureViewDelegate {
    static var isSupported: Bool { RoomCaptureSession.isSupported }

    var onComplete: (FloorPlan) -> Void = { _ in }

    private let capture = RoomCaptureView(frame: .zero)
    var view: UIView { capture }

    init() {
        capture.delegate = self
    }

    func start() {
        capture.captureSession.run(configuration: RoomCaptureSession.Configuration())
    }

    func finish() {
        capture.captureSession.stop()
    }

    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        true
    }

    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        onComplete(RoomProjection.floorPlan(from: processedResult))
    }

    // RoomCaptureViewDelegate refines NSCoding. These satisfy it; the session is never archived.
    init?(coder: NSCoder) {}
    func encode(with coder: NSCoder) {}
}
