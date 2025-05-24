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
    @State private var permissionSlides: Int = 0
    private var imgName = ["ax_0", "ax_1", "ax_2", "ax_3", "ax_4"]
    var body: some View {
        VStack {
            Text("Welcome to AnoDock")
                .font(.largeTitle)
                .padding(.top, 20)
            ZStack {
                    Image(imgName[permissionSlides])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .transition(.slide)
            }
            .frame(width: 650, height: 450)
            Text("Please enable the required permissions.")
                .multilineTextAlignment(.center)
            HStack {
                
                Button("Grant Permissions") {
                    ProcessInfo.processInfo.isSandboxed ? giveAccessibilityManual() : giveAccessibilitySyspromp()
                }
                Button("I've granted permission, restart the app") {
                    restartApp()
                }
                .disabled(!isTrusted)
            }
            .padding(.bottom, 20)
        }
        .frame(width: 750, height: 600)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
                let trusted = AXIsProcessTrusted()
                if trusted {
                    isTrusted = true
                    timer?.invalidate()
                } else {
                    withAnimation(.spring) {
                        permissionSlides = (permissionSlides + 1) % imgName.count
                    }
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }


    
    private func giveAccessibilityManual() {
        if let url = URL(string:
        "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) {
            NSWorkspace.shared.open(url)
        }
    }
    private func giveAccessibilitySyspromp() {
        let promptFlag = kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString
        let myDict: CFDictionary = NSDictionary(dictionary: [promptFlag: true])
        AXIsProcessTrustedWithOptions(myDict)
    }
    
    func restartApp() {
        let bundlePath = Bundle.main.bundlePath

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", "sleep 0.1; open \"\(bundlePath)\""]

        try? task.run()
        exit(0)
    }
}

#Preview {
    OnboardingView()
}
