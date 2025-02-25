//
//  AnoDockApp.swift
//  AnoDock
//
//  Created by John Yang on 11/17/24.
//

/*
 App entrance
 */

import SwiftUI

@main
struct AnoDockApp: App {
    // managers and observers
    private var dockObserver: DockObserver = .shared
    private var dragDropManager: DragDropManager = .shared
    private var dockWindowState: DockWindowState = .shared
    private let dockWindowManager: DockWindowManager = .shared
        
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
        NSApplication.shared.setActivationPolicy(.accessory)
        
        _ = notificationHandler
        if AXIsProcessTrusted() {
            dockWindowManager.loadHostingController()// show dock at launch to initiate dockUIFrame
            dockWindowManager.updateWindowPosition()
            dockWindowManager.showDock() // if only call once, first showDock will not correctly compute tooltipview and item pos for clicking
            dockWindowManager.showDock() // call again so frame pos can be correctly intialized
        }

    }
    	
    var body: some Scene {
        
        

        MenuBarExtra("AnoDock", systemImage: "dock.rectangle") {
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
            if !checkAccessibilityPermission() {
                    OnboardingView()
            } else {
                SettingsView()
                    .environmentObject(dockObserver)
                    .environmentObject(dockWindowManager)
                    .environmentObject(dragDropManager)
                    .environmentObject(dockWindowState)
                    .environmentObject(hotKeySettings)
                    .environmentObject(dockEditorSettings)
                    .environmentObject(generalSettings)
                    .environmentObject(appSettings)
                    .environmentObject(dockEditorSettings)

                

            }
        }
    }
    
    private func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}


