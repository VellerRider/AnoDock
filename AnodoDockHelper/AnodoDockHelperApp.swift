//
//  AnodoDockHelperApp.swift
//  AnodoDockHelper
//
//  Created by John Yang on 1/20/25.
//
import SwiftUI

@main
struct AnodoDockHelperApp: App {
    var body: some Scene {
        WindowGroup {
            EmptyView()
            .onAppear {
                // The moment the helper launches, spawn the main app:
                launchMainApp()
                // Then quit the helper if you don't need it running.
                DispatchQueue.main.async {
                    NSApplication.shared.terminate(nil)
                }
        }
        }
    }

    func launchMainApp() {
        let mainAppPath = "/Applications/KuchiyoseDock.app" // or find the path more elegantly if needed
        let url = URL(fileURLWithPath: mainAppPath)
        NSWorkspace.shared.openApplication(at: url,
                                           configuration: .init(),
                                           completionHandler: nil)
    }
}
