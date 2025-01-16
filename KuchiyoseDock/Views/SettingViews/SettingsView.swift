//
//  SettingsView.swift
//  KuchiyoseDock
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
                    Label("Dock Settings", systemImage: "pin.circle")
                }
                
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
                
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                
            OtherSettingsView()
                .tabItem {
                    Label("Other", systemImage: "line.horizontal.3.circle.fill")
                }
                
        }
        .padding()
        .modifier(WindowAnimationModifier())
    }
}

#Preview {
    let dockObserver = DockObserver.shared
    let dockWindowManager = DockWindowManager.shared
    let dragDropManager = DragDropManager.shared
    let hotKeySettings = HotKeySettings.shared
    let itemPopoverManager = ItemPopoverManager.shared
    let dockWindowState = DockWindowState.shared
    let dockEditorSettings = DockEditorSettings.shared
    SettingsView()
        .environmentObject(dockObserver)
        .environmentObject(dockWindowManager)
        .environmentObject(dragDropManager)
        .environmentObject(hotKeySettings)
        .environmentObject(itemPopoverManager)
        .environmentObject(dockWindowState)
        .environmentObject(dockEditorSettings)
}
