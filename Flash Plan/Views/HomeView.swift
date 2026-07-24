import SwiftUI

struct HomeView: View {
    @Environment(AppRouter.self) private var router

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
        if RoomCaptureController.isSupported {
            Text("Scan a room to get a 2D floorplan you can save to Photos.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            if !router.scanMessage.isEmpty {
                Text(router.scanMessage)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.orange)
            }
            Spacer()
            Button("Scan a room") { router.startScan() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        } else {
            Text("Flash Plan needs an iPhone Pro with LiDAR to scan rooms.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }
}

#if DEBUG
#Preview {
    HomeView()
        .environment(AppRouter())
}
#endif
