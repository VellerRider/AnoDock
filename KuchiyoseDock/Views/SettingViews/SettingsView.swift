//
//  SettingsView.swift
//  KuchiyoseDock
//  The View for app setting 
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
            DockEditorView()
                .tabItem {
                    Label("Dock Content", systemImage: "pin.circle")
                }
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
            
            OtherSettingsView()
                .tabItem {
                    Label("Other", systemImage: "line.horizontal.3.circle.fill")
                }
            
        }
        .padding()
        .frame(width: 960, height: 540)
    }
}

#Preview {
    SettingsView()
}
