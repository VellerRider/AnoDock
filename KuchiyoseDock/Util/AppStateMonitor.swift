//
//  AppStateMonitor.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/20/24.
//
import Foundation
import Cocoa

class AppStateMonitor: ObservableObject {
    @Published var runningApplications: Set<String> = []

    init() {
        updateRunningApplications()
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(applicationDidLaunch(_:)), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(applicationDidTerminate(_:)), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
    }

    private func updateRunningApplications() {
        let runningApps = NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier }
        runningApplications = Set(runningApps)
    }

    @objc private func applicationDidLaunch(_ notification: Notification) {
        // 更新运行状态
        // 调用委托或通知更新界面
    }

    @objc private func applicationDidTerminate(_ notification: Notification) {
        // 更新运行状态
        // 调用委托或通知更新界面
    }
}
