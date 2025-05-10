//
//  SettingsView.swift
//  AnoDock
//  The View for app setting 
//  Created by John Yang on 11/17/24.
//

import Foundation
import SwiftUI
import WindowAnimation

struct SettingsView: View {

    var body: some View {
        TabView {
            DockEditorView()
                .tabItem {
                    Label("Dock Editor", systemImage: "pin.circle")
                }
                
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
                
//            GeneralSettingsView()
//                .tabItem {
//                    Label("General", systemImage: "gear")
//                }
        }
        .padding()
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            
        }
    }
}

#Preview {
    let dockObserver = DockObserver.shared
    let dockWindowManager = DockWindowManager.shared
    let dragDropManager = DragDropManager.shared
    let hotKeySettings = HotKeySettings.shared
    let dockWindowState = DockWindowState.shared
    let dockEditorSettings = DockEditorSettings.shared
    SettingsView()
        .environmentObject(dockObserver)
        .environmentObject(dockWindowManager)
        .environmentObject(dragDropManager)
        .environmentObject(hotKeySettings)
        .environmentObject(dockWindowState)
        .environmentObject(dockEditorSettings)
}
