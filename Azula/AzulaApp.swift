//
//  AzulaApp.swift
//  Azula
//
//  Created by Lilliana on 15/05/2023.
//

import SwiftUI

@main
struct AzulaApp: App {
    var body: some Scene {
        #if os(macOS)
        WindowGroup {
            ContentView()
                .frame(width: 300, height: 475)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        
        #else
        WindowGroup {
            ContentView()
        }
        #endif
    }
}
