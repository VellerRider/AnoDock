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
    @StateObject private var dockObserver = DockObserver()
    @StateObject private var hotKeySettings = HotKeySettings()// the global hotkey is inside this
//    @StateObject private var appsetting = AppSettings()
//    @StateObject private var appStateMonitor = AppStateMonitor()
    
    // A small helper to manage showing/hiding a floating NSWindow for the custom dock
    private let dockWindowManager = DockWindowManager()
    @State private var showDockWindow: Bool = false
    var body: some Scene {
        WindowGroup {
            if !AXIsProcessTrusted() {
                OnboardingView()
            } else {
//                ContentView()
                    SettingsView()
                    .environmentObject(dockObserver)
                    .environmentObject(hotKeySettings)
//                    .environmentObject(appStateMonitor)
//                    .environmentObject(customdocksetting)
//                    .environmentObject(appsetting)
                    .onAppear {
                        dockObserver.loadDockItems()
                        dockObserver.syncRecentApps()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SummonDock"))) { _ in
                        if (!showDockWindow) {
                            dockWindowManager.showDock(observer: dockObserver)
                        } else {
                            dockWindowManager.hideDock()
                        }
                        showDockWindow.toggle()
                        
                        // This is where you'd "summon the dock" in your UI
                        // e.g. toggle an overlay or call a function
                    }
            }
        }
//        Settings {
//            SettingsView()
//                .environmentObject(hotkey)
//                .environmentObject(appsetting)
//                .environmentObject(dockObserver)
//        } 
    }
    

}

