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
    @State private var selectedTab = 0

    private var frameSize: CGSize {
        switch selectedTab {
        case 0: return CGSize(width: 880, height: 660)
        case 1: return CGSize(width: 500, height: 400)
        case 2: return CGSize(width: 700, height: 450)
        case 3: return CGSize(width: 750, height: 480)
        default: return CGSize(width: 880, height: 660)
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DockEditorView()
                .tabItem {
                    Label("Dock Settings", systemImage: "pin.circle")
                }
                .tag(0)
            ShortcutsSettingsView()
                .tabItem {
                    Label("Shortcuts", systemImage: "keyboard")
                }
                .tag(1)
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(2)
            OtherSettingsView()
                .tabItem {
                    Label("Other", systemImage: "line.horizontal.3.circle.fill")
                }
                .tag(3)
        }
        .padding()
        .frame(width: frameSize.width, height: frameSize.height)
        .modifier(WindowAnimationModifier())
    }
}

#Preview {
    let dockObserver = DockObserver.shared
    let dragDropManager = DragDropManager.shared
    let hotKeySettings = HotKeySettings.shared
    let itemPopoverManager = ItemPopoverManager.shared
    let dockWindowState = DockWindowState.shared
    let dockEditorSettings = DockEditorSettings.shared
    SettingsView()
        .environmentObject(dockObserver)
        .environmentObject(dragDropManager)
        .environmentObject(hotKeySettings)
        .environmentObject(itemPopoverManager)
        .environmentObject(dockWindowState)
        .environmentObject(dockEditorSettings)
}
