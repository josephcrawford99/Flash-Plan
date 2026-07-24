import SwiftUI
import UIKit

struct SplashScreen: View {
    var body: some View {
        VStack {
            HStack {
                Text("Flash Plan")
                    .font(.appLargeTitle)
                Spacer()
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}
