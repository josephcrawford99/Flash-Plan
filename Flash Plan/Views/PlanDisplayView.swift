import SwiftUI

struct PlanDisplayView: View {
    @State private var viewModel: PlanDisplayViewModel
    @Environment(\.openURL) private var openURL

    init(plan: FloorPlan, router: AppRouter) {
        _viewModel = State(initialValue: PlanDisplayViewModel(plan: plan, router: router))
    }

    var body: some View {
        VStack(spacing: 16) {
            FloorPlanView(plan: viewModel.plan)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12).stroke(.quaternary)
                }
                .padding()

            if !viewModel.status.message.isEmpty {
                Text(viewModel.status.message)
                    .font(.appCallout)
                    .foregroundStyle(viewModel.status.color)
            }

            if viewModel.status == .permissionDenied {
                Button("Open Settings") { openSettings() }
            }

            HStack(spacing: 12) {
                Button("Scan again") { viewModel.scanAgain() }
                    .buttonStyle(.bordered)
                Button("Save to Photos") { Task { await viewModel.save() } }
                    .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
            .padding(.bottom)
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

private extension SaveStatus {
    var message: String {
        switch self {
        case .idle: ""
        case .saved: "Saved to Photos."
        case .permissionDenied: "Photo access is off. Enable it in Settings to save."
        case .failed: "Could not save the image. Try again."
        }
    }

    var color: Color {
        switch self {
        case .idle: .secondary
        case .saved: .appAccent
        case .permissionDenied, .failed: .appError
        }
    }
}

#if DEBUG
#Preview {
    PlanDisplayView(plan: .sample, router: AppRouter())
}
#endif
