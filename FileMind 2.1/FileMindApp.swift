//
//  FileMindApp.swift
//  FileMind
//
//  Created by WessoBesso on 2025-04-24.
//

import SwiftUI

@main
struct FileMindApp: App {
    init() {
        // Configure window size once it's created
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for window in NSApplication.shared.windows {
                window.minSize = NSSize(width: 800, height: 600)
                // Optional: set maxSize too
                // window.maxSize = NSSize(width: 2000, height: 1400)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

