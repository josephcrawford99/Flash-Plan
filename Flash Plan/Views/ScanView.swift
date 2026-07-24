import SwiftUI

struct ScanView: View {
    @State private var viewModel: ScanViewModel

    init(router: AppRouter) {
        _viewModel = State(initialValue: ScanViewModel(router: router))
    }

    var body: some View {
        ZStack {
            if let controller = viewModel.controller {
                RoomCaptureRepresentable(controller: controller)
                    .ignoresSafeArea()
                    .overlay(alignment: .bottom) {
                        Button("Done") { viewModel.finishScan() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .padding(.bottom, 40)
                    }
            }

            if !viewModel.isReady {
                loading
                    .transition(.opacity)
            }
        }
        .animation(.default, value: viewModel.isReady)
        .task { viewModel.prepare() }
    }

    private var loading: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemBackground))
            .ignoresSafeArea()
    }
}

private struct RoomCaptureRepresentable: UIViewControllerRepresentable {
    let controller: RoomCaptureController

    func makeUIViewController(context: Context) -> RoomCaptureController { controller }
    func updateUIViewController(_ uiViewController: RoomCaptureController, context: Context) {}
}
