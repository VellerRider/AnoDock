//
//  SettingsView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            EditDockView()
                .tabItem {
                    Label("Dock Content", systemImage: "pin.circle")
                }
            
            DockSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "line.horizontal.3.circle.fill")
                }
            
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
        }
        .padding()
        .frame(width: 960, height: 540)
    }
}

#Preview {
    SettingsView()
}
