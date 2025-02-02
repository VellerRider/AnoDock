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
    // managers and observers
    private var dockObserver: DockObserver = .shared
    private var dragDropManager: DragDropManager = .shared
    private var dockWindowState: DockWindowState = .shared
    private let dockWindowManager: DockWindowManager = .shared
    private var itemPopoverManager: ItemPopoverManager = .shared
        
    // settings
    private var dockEditorSettings: DockEditorSettings = .shared
    private var generalSettings: GeneralSettings = .shared
    private var appSettings: AppSettings = .shared
    private var hotKeySettings: HotKeySettings = .shared
    
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
        if AXIsProcessTrusted() {
            dockWindowManager.loadHostingController()// show dock at launch to initiate dockUIFrame
            dockWindowManager.updateWindowPosition()
            dockWindowManager.showDock()
        }

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
        .menuBarExtraStyle(.automatic)

        Settings {
            if !AXIsProcessTrusted() {
                    OnboardingView()
            } else {
                SettingsView()
                    .environmentObject(dockObserver)
                    .environmentObject(dockWindowManager)
                    .environmentObject(dragDropManager)
                    .environmentObject(dockWindowState)
                    .environmentObject(itemPopoverManager)
                    .environmentObject(hotKeySettings)
                    .environmentObject(dockEditorSettings)
                    .environmentObject(generalSettings)
                    .environmentObject(appSettings)
                    .environmentObject(dockEditorSettings)

                

            }
        }
    }
}


