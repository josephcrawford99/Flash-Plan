import SwiftUI
import Photos

enum PhotoSaveResult {
    case saved
    case permissionDenied
    case failed
}

enum FloorPlanExporter {
    @MainActor
    static func image(for plan: FloorPlan) -> UIImage {
        let content = FloorPlanView(plan: plan)
            .frame(width: 1000, height: 1000)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 3
        return renderer.uiImage ?? UIImage()
    }

    @MainActor
    static func save(_ plan: FloorPlan) async -> PhotoSaveResult {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return .permissionDenied }
        guard let data = image(for: plan).pngData() else { return .failed }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: data, options: nil)
            }
            return .saved
        } catch {
            return .failed
        }
    }
}
