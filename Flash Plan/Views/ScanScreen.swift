import SwiftUI

struct ScanScreen: View {
    @Environment(AppModel.self) private var model
    @State private var session = RoomScanSession()

    var body: some View {
        CaptureViewBridge(view: session.view)
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                Button("Done") { session.finish() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom, 40)
            }
            .onAppear {
                session.onComplete = { model.finish($0) }
                session.start()
            }
    }
}

private struct CaptureViewBridge: UIViewRepresentable {
    let view: UIView

    func makeUIView(context: Context) -> UIView { view }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
