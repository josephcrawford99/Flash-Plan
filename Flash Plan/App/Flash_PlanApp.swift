//
//  Flash_PlanApp.swift
//  Flash Plan
//
//  Created by Joseph Crawford on 7/6/26.
//

import SwiftUI

@main
struct Flash_PlanApp: App {
    @State private var router = AppRouter()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch router.route {
                case .home:
                    HomeView()
                case .scanning:
                    ScanView(router: router)
                case .result(let plan):
                    PlanDisplayView(plan: plan, router: router)
                }
                if showSplash {
                    SplashScreen()
                        .transition(.opacity)
                }
            }
            .environment(router)
            .task {
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation { showSplash = false }
            }
        }
    }
}
