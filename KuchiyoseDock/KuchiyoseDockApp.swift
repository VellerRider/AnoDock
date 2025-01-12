//
//  KuchiyoseDockApp.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

/*
 App entrance
 */

import SwiftUI

@main
struct KuchiyoseDockApp: App {
    // 原有的 StateObjects
    private var dockObserver = DockObserver()
    private var hotKeySettings = HotKeySettings()
    private var dockWindowState = DockWindowState()

    // Dock overlay manager
    private let dockWindowManager = DockWindowManager()
    // delegate notification
    private lazy var notificationHandler = DockNotificationHandler(
        dockWindowManager: dockWindowManager,
        dockObserver: dockObserver,
        dockWindowState: dockWindowState
    )

    init() {
        // 让应用隐藏 Dock 图标
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // **在这里**触发 lazy 初始化
        _ = notificationHandler
        dockObserver.loadDockItems()
        dockObserver.syncRecentApps()

    }
    
    var body: some Scene {

        MenuBarExtra("KuchiyoseDock", systemImage: "dock.rectangle") {
            Divider()
            SettingsLink {
                Text("Settings")
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .menuBarExtraStyle(.window) // 或 .automatic

        Settings {
            if !AXIsProcessTrusted() {
                    OnboardingView()
            } else {
                SettingsView()
                    .environmentObject(dockObserver)
                    .environmentObject(hotKeySettings)

            }
        }
    }
}

