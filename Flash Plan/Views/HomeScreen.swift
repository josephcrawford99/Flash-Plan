import SwiftUI

struct HomeScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "ruler")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Flash Plan")
                .font(.largeTitle.bold())
            content
            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    private var content: some View {
        if model.isSupported {
            Text("Scan a room to get a 2D floorplan you can save to Photos.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if !model.scanMessage.isEmpty {
                Text(model.scanMessage)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.orange)
            }
            Spacer()
            Button("Scan a room") { model.startScan() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        } else {
            Text("Flash Plan needs an iPhone Pro with LiDAR to scan rooms.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }
}
