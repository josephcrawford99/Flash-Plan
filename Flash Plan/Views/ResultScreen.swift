import SwiftUI

struct ResultScreen: View {
    let plan: FloorPlan
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL
    @State private var status = SaveStatus.idle

    var body: some View {
        VStack(spacing: 16) {
            FloorPlanView(plan: plan)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12).stroke(.quaternary)
                }
                .padding()

            if !status.message.isEmpty {
                Text(status.message)
                    .font(.callout)
                    .foregroundStyle(status.color)
            }

            if status == .permissionDenied {
                Button("Open Settings") { openSettings() }
            }

            HStack(spacing: 12) {
                Button("Scan again") { model.startScan() }
                    .buttonStyle(.bordered)
                Button("Save to Photos") { save() }
                    .buttonStyle(.borderedProminent)
            }
            .controlSize(.large)
            .padding(.bottom)
        }
    }

    private func save() {
        Task {
            switch await FloorPlanExporter.save(plan) {
            case .saved: status = .saved
            case .permissionDenied: status = .permissionDenied
            case .failed: status = .failed
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

private enum SaveStatus: Equatable {
    case idle
    case saved
    case permissionDenied
    case failed

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
        case .saved: .green
        default: .secondary
        }
    }
}
