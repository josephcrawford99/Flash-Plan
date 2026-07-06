//
//  Flash_PlanApp.swift
//  Flash Plan
//
//  Created by Joseph Crawford on 7/6/26.
//

import SwiftUI

@main
struct Flash_PlanApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
        }
    }
}
