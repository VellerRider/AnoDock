//
//  OnboardingView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import Foundation
import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool // 添加 Binding

    var body: some View {
        VStack {
            Text("Welcome to KuchiyoseDock")
                .font(.largeTitle)
                .padding()

            Text("Please enable the required permissions.")
                .multilineTextAlignment(.center)
                .padding()

            Button("Grant Permissions") {
                // 在完成权限授权后隐藏 Onboarding
                grantAccessibilityPermissions()
                showOnboarding = false
            }
            .padding()
        }
        .frame(width: 400, height: 300)
    }

    func grantAccessibilityPermissions() {
        if !AXIsProcessTrusted() {
            let options: CFDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }
}
