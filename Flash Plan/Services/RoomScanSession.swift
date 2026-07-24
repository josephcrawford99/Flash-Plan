import UIKit
import AVFoundation
import RoomPlan
import os

@MainActor
final class RoomCaptureController: UIViewController, RoomCaptureViewDelegate {
    static var isSupported: Bool { RoomCaptureSession.isSupported }

    var onComplete: (FloorPlan) -> Void = { _ in }
    var onFailure: (String) -> Void = { _ in }
    var onReady: () -> Void = {}

    private let captureView = RoomCaptureView(frame: .zero)
    private var isRunning = false

    override func loadView() {
        captureView.delegate = self
        view = captureView
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startIfPermitted()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stop()
    }

    func finish() {
        guard isRunning else { return }
        captureView.captureSession.stop()
        isRunning = false
    }

    func stop() {
        guard isRunning else { return }
        captureView.captureSession.stop()
        isRunning = false
    }

    private func startIfPermitted() {
        guard !isRunning else { return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            beginCapture()
        case .notDetermined:
            Task { @MainActor in
                if await AVCaptureDevice.requestAccess(for: .video) {
                    beginCapture()
                } else {
                    ScanDiagnostics.log.error("Camera access denied at prompt")
                    onFailure("Camera access is needed to scan a room.")
                }
            }
        default:
            ScanDiagnostics.log.error("Camera access previously denied or restricted")
            onFailure("Camera access is off. Enable it in Settings to scan a room.")
        }
    }

    private func beginCapture() {
        guard !isRunning, view.window != nil else { return }
        ScanDiagnostics.log.info("Starting room capture session")
        captureView.captureSession.run(configuration: RoomCaptureSession.Configuration())
        isRunning = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            guard isRunning else { return }
            onReady()
        }
    }

    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: Error?) -> Bool {
        if let error {
            ScanDiagnostics.log.error("Capture ended with error: \(error.localizedDescription, privacy: .public)")
            isRunning = false
            onFailure("That scan did not finish. Try again.")
            return false
        }
        return true
    }

    func captureView(didPresent processedResult: CapturedRoom, error: Error?) {
        isRunning = false
        if let error {
            ScanDiagnostics.log.error("Processing failed: \(error.localizedDescription, privacy: .public)")
            onFailure("That scan could not be processed. Try again.")
            return
        }
        ScanDiagnostics.log.info("Capture processed with \(processedResult.walls.count) walls")
        onComplete(RoomProjection.floorPlan(from: processedResult))
    }
}
