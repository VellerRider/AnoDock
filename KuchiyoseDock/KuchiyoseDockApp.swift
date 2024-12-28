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
    @StateObject private var appStateMonitor = AppStateMonitor()
    
    // 用于热键监听
    @State private var toggleDockHotKey: HotKey?
    @State private var showCustomDock = false
    
    var body: some Scene {
        WindowGroup {
            if !AXIsProcessTrusted() {
                OnboardingView()
            } else {
                ContentView()
                    .environmentObject(dockObserver)
                    .environmentObject(appStateMonitor)
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
        Settings {
            SettingsView()
//                .environmentObject(hotkey)
//                .environmentObject(appsetting)
                .environmentObject(dockObserver)
        }
    }
    
    private func setupHotKey() {
        // 例如 cmd+shift+d
        toggleDockHotKey = HotKey(key: .d, modifiers: [.command, .shift])
        toggleDockHotKey?.keyDownHandler = {
            showCustomDock.toggle()
        }
    }
}

// 示例的自定义 Dock Overlay 视图
struct CustomDockOverlayView: View {
    let items: [DockItem]
    
    var body: some View {
        HStack {
            ForEach(items) { item in
                // 在这里使用 DockItemView 交互模式为 true
                DockItemView(item: item, interactive: true)
            }
        }
        .background(Color.black.opacity(0.8))
        .cornerRadius(10)
        .padding()
        .position(mouseLocation)
    }
    
    var mouseLocation: CGPoint {
        guard let event = CGEvent(source: nil) else { return .zero }
        return event.location
    }
}
