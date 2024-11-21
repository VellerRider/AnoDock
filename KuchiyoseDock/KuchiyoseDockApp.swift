//
//  KuchiyoseDockApp.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import Foundation
import SwiftUI

@main
struct KuchiyoseDockApp: App {
    @StateObject private var hotkey = HotKeySettings()
    @StateObject private var customdocksetting = DockSettings()
    @StateObject private var appsetting = AppSettings()


    
    @EnvironmentObject var dockObserver: DockPreferencesObserver
    @StateObject private var appStateMonitor = AppStateMonitor()
    
    var body: some Scene {
        WindowGroup {
            if (!AXIsProcessTrusted()) {
                OnboardingView()
            } else {
                ContentView()
                    .environmentObject(dockObserver)
                    .onAppear {
                    // 加载本地保存的 Dock 项目
                    dockObserver.loadDockItemsFromLocal()
                    }
            }
        }
        Settings {
            SettingsView()
                .environmentObject(systemdocksetting)
                .environmentObject(hotkey)
                .environmentObject(customdocksetting)
                .environmentObject(appsetting)
        }
    }

}


