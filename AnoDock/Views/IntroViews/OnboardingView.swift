//
//  OnboardingView.swift
//  AnoDock
//
//  Ask new user for permission.
// 
//  Created by John Yang on 11/17/24.
//

import Foundation
import SwiftUI

struct OnboardingView: View {

    @State private var isTrusted = AXIsProcessTrusted()
    @State private var timer: Timer?
    
    var body: some View {
        VStack {
            Text("Welcome to AnoDock")
                .font(.largeTitle)
                .padding()

            Text("Please enable the required permissions.")
                .multilineTextAlignment(.center)
                .padding()

            Button("Grant Permissions") {
                if !AXIsProcessTrusted() {
                    checkAccessibilityPermission()
                }
            }
            Button("I've granted permission, restart the app") {
                restartApp()
            }
            .disabled(!isTrusted)
            
            .padding()
        }
        .frame(width: 400, height: 300)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                let trusted = AXIsProcessTrusted()
                if trusted {
                    isTrusted = true
                    timer?.invalidate()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }


    
    private func checkAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    private func restartApp() {
        let bundleURL = URL(fileURLWithPath: Bundle.main.bundlePath)
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: bundleURL,
                                           configuration: config,
                                           completionHandler: nil)
        NSApp.terminate(nil)
    }
}
