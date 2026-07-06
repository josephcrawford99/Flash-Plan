import SwiftUI

struct ScanScreen: View {
    @Environment(AppModel.self) private var model
    @State private var controller = RoomCaptureController()

    var body: some View {
        RoomCaptureRepresentable(controller: controller)
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                Button("Done") { controller.finish() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom, 40)
            }
            .onAppear {
                controller.onComplete = { model.finish($0) }
                controller.onFailure = { model.fail($0) }
            }
    }
}

private struct RoomCaptureRepresentable: UIViewControllerRepresentable {
    let controller: RoomCaptureController

    func makeUIViewController(context: Context) -> RoomCaptureController { controller }
    func updateUIViewController(_ uiViewController: RoomCaptureController, context: Context) {}
}
