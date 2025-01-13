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
            DockEditorView()
                .tabItem {
                    Label("Dock Content", systemImage: "pin.circle")
                }
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
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
    let dockObserver = DockObserver()
    let hotKeySettings = HotKeySettings()
    let itemPopoverManager = ItemPopoverManager()
    let dockWindowState = DockWindowState()
    let dockEditorSettings = DockEditorSettings()
    SettingsView()
        .environmentObject(dockObserver)
        .environmentObject(hotKeySettings)
        .environmentObject(itemPopoverManager)
        .environmentObject(dockWindowState)
        .environmentObject(dockEditorSettings)
}
