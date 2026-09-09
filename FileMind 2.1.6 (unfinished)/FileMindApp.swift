//
//  FileMindApp.swift
//  FileMind
//
//  Created by WessoBesso on 2025-04-24.
//

import SwiftUI

@main
struct FileMindApp: App {
    @StateObject private var appState = AppState.shared

    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for window in NSApplication.shared.windows {
                window.minSize = NSSize(width: 800, height: 600)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState) // 👈 inject the AppState
        }
    }
}
