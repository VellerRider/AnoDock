//
//  KuchiyoseDockApp.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import SwiftUI
import HotKey

@main
struct KuchiyoseDockApp: App {
    // TODO: might need to implement below items as environment objects to store settings
//    @StateObject private var hotkey = HotKeySettings()
//    @StateObject private var appsetting = AppSettings()
    @StateObject private var dockObserver = DockObserver()
//    @StateObject private var appStateMonitor = AppStateMonitor()
    
    // A small helper to manage showing/hiding a floating NSWindow for the custom dock
    private let dockWindowManager = DockWindowManager()
    
    // For toggling the custom dock overlay
    @State private var showCustomDock = false
    
    // The global hotkey
    @State private var toggleDockHotKey: HotKey?
    
//    var body: some Scene {
//        // 1. Menu bar scene
//        MenuBarExtra("Dock", systemImage: "dock.rectangle") {
//                    // Some menu items when user clicks the menu bar icon
//                    Button("Open Settings") {
//                        // Open the SwiftUI Settings window
//                        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
//                    }
//                    Divider()
//                    Button("Quit KuchiyoseDock") {
//                        NSApp.terminate(nil)
//                    }
//                }
//
//        // 2. Settings scene (optional)
//        Settings {
//            SettingsView()
//                .environmentObject(dockObserver)
//        }
//    }
    
  // MARK: - old version
    var body: some Scene {
        WindowGroup {
            if !AXIsProcessTrusted() {
                OnboardingView()
            } else {
//                ContentView()
                    SettingsView()
                    .environmentObject(dockObserver)
//                    .environmentObject(appStateMonitor)
//                    .environmentObject(customdocksetting)
//                    .environmentObject(appsetting)
//                    .environmentObject(hotkey)
                    .onAppear {
                        dockObserver.loadDockItems()
                        setupHotKey()
                    }
                    .overlay(
                        Group {
                            if showCustomDock {
                                // 显示自定义 Dock 的 overlay
                                CustomDockOverlayView(items: dockObserver.dockItems)
                            }
                        }
                    )
            }
        }
//        Settings {
//            SettingsView()
////                .environmentObject(hotkey)
////                .environmentObject(appsetting)
//                .environmentObject(dockObserver)
//        }
    }
    
    init() {
        setupHotKey()
        dockObserver.loadDockItems()
    }
    
    private func setupHotKey() {
        // Option + Shift + Space
        toggleDockHotKey = HotKey(key: .space, modifiers: [.option, .shift])
        
        toggleDockHotKey?.keyDownHandler = {
            showCustomDock.toggle()
            if showCustomDock {
                // Show the custom dock near the mouse
                dockWindowManager.showDock(items: dockObserver.dockItems)
            } else {
                // Hide it
                dockWindowManager.hideDock()
            }
        }
    }
}

