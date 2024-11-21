//
//  OnboardingView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import Foundation
import SwiftUI

struct OnboardingView: View {

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
                goGrantAccessibilityPermissions()
            }
            .padding()
        }
        .frame(width: 400, height: 300)
    }

    func goGrantAccessibilityPermissions() {
        // two methods to open system settings window
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
//        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)

        
    }
}
