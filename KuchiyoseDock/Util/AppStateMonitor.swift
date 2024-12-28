//
//  AppStateMonitor.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/20/24.
//


// maintain a array of current running apps

import Foundation
import Cocoa

class AppStateMonitor: ObservableObject {
    @Published var runningApplications: Set<String> = [] // 发布属性，存储正在运行的应用程序的 Bundle Identifier

    private var runningAppObservations = [NSRunningApplication: NSKeyValueObservation]() // 存储对每个运行中应用的 KVO 观察者，用于及时更新状态

    init() {
        updateRunningApplications() // 初始化时更新运行的应用列表
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(applicationDidLaunch(_:)), name: NSWorkspace.didLaunchApplicationNotification, object: nil) // 监听应用启动通知
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(applicationDidTerminate(_:)), name: NSWorkspace.didTerminateApplicationNotification, object: nil) // 监听应用终止通知
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self) // 移除通知观察者
        runningAppObservations.values.forEach { $0.invalidate() } // 移除 KVO 观察者，防止内存泄漏
    }

    private func updateRunningApplications() {
        let runningApps = NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier } // 获取所有运行中应用的 Bundle Identifier
        runningApplications = Set(runningApps) // 更新 runningApplications 集合
        for app in NSWorkspace.shared.runningApplications {
            observeRunningApp(app)
        }
    }

    private func observeRunningApp(_ app: NSRunningApplication) {
        let observation = app.observe(\.isFinishedLaunching, options: [.new]) { [weak self] (app, change) in // 观察 isFinishedLaunching 属性
            guard let self = self, app.isFinishedLaunching else { return } // 确保应用完全启动
            DispatchQueue.main.async { // 在主线程更新 UI
                self.updateRunningApplications()
            }
        }
        runningAppObservations[app] = observation // 存储观察者
    }

    @objc private func applicationDidLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }
        DispatchQueue.main.async { // 在主线程更新 UI
            self.runningApplications.insert(bundleID) // 将新启动的应用添加到集合
            self.observeRunningApp(app)
        }
    }

    @objc private func applicationDidTerminate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }
        DispatchQueue.main.async { // 在主线程更新 UI
            self.runningApplications.remove(bundleID) // 将终止的应用从集合中移除
            self.runningAppObservations.removeValue(forKey: app)?.invalidate() // 移除对应的 KVO 观察者
        }
    }
}
