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
    @StateObject private var systemdocksetting = SystemDockSettings() // 使用 @StateObject 来管理 DockSettings
    @StateObject private var hotkey = HotKeySettings()
    @StateObject private var customdocksetting = CustomDockSettings()
    @StateObject private var appsetting = AppSettings()
    @State private var showOnboarding = true // 控制是否显示引导界面

    var body: some Scene {
        WindowGroup {
            if showOnboarding {
                OnboardingView(showOnboarding: $showOnboarding) // 引导用户授权
                    .environmentObject(appsetting)
            } else {
                EmptyView() // 不显示任何视图，应用后台运行
            }
        }
        Settings {
            SettingsView() // SwiftUI 原生设置窗口
                .environmentObject(systemdocksetting)
                .environmentObject(hotkey)
                .environmentObject(customdocksetting)
                .environmentObject(appsetting)
        }
    }

}


#Preview {
    ContentView()
        .environmentObject(SystemDockSettings())
        .environmentObject(HotKeySettings())
        .environmentObject(CustomDockSettings())
        .environmentObject(AppSettings())
}
