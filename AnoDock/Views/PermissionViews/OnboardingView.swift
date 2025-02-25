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

    var body: some View {
        VStack {
            Text("Welcome to AnoDock")
                .font(.largeTitle)
                .padding()

            Text("Please enable the required permissions.")
                .multilineTextAlignment(.center)
                .padding()

            Button("Grant Permissions") {
                goGrantAccessibilityPermissions()
            }
            Button("I've granted permission, Restart app") {
                NSApplication.shared.terminate(nil)
            }
            
            .padding()
        }
        .frame(width: 400, height: 300)
    }

    func goGrantAccessibilityPermissions() {
        // two methods to open system settings window
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
