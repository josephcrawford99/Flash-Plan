import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        switch model.route {
        case .home:
            HomeScreen()
        case .scanning:
            ScanScreen()
        case .result(let plan):
            ResultScreen(plan: plan)
        }
    }
}
