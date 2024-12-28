//
//  DockObserver.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/19/24.
//


// observe dock's app, implement these functions
// 1. check what's added to dock, or removed from dock. Only main app and folder.
// 2. check in-dock app when is opened or closed.
// 3. help with recent apps. track latest closed app or files.

import Foundation
import Cocoa
import Combine

// DockObserver 将监听系统应用的启动和退出，维护 dockItems 和 recentApplications
class DockObserver: NSObject, ObservableObject {
    @Published var dockItems: [DockItem] = []
    @Published var recentApplications: [DockItem] = []
    
    private var dockPreferencesContext = 0
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        
        // 开始监听 Dock 的偏好变化（如 persistent-apps, persistent-others）
        UserDefaults.standard.addObserver(self, forKeyPath: "persistent-apps", options: [.new, .old], context: &dockPreferencesContext)
        UserDefaults.standard.addObserver(self, forKeyPath: "persistent-others", options: [.new, .old], context: &dockPreferencesContext)
        
        // 监听应用的启动和终止
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(appLaunched(_:)), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(appTerminated(_:)), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
        
        // 初始化加载 Dock Items（如有需要）
        loadDockItems()
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "persistent-apps")
        UserDefaults.standard.removeObserver(self, forKeyPath: "persistent-others")
        
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didTerminateApplicationNotification, object: nil)
    }
    
    // 监听 Dock 配置变化
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if context == &dockPreferencesContext {
            if let newValue = change?[.newKey] {
                print("Dock items changed: \(newValue)")
                // 根据需要更新 dockItems
                // 例如：重新解析 persistent-apps 配置，然后更新 dockItems
                // updateDockItemsFromPreferences()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // 应用启动事件
    @objc private func appLaunched(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let runningApp = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        // 应用启动后，检查该应用是否在 dockItems 中，如果在则更新 isRunning
        if let index = dockItems.firstIndex(where: { $0.bundleIdentifier == runningApp.bundleIdentifier }) {
            dockItems[index].isRunning = true
        }
    }
    
    // 应用终止事件
    @objc private func appTerminated(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let runningApp = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        // 应用退出后，如果在 dockItems 中存在，则更新 isRunning 并将其加入 recentApplications
        if let index = dockItems.firstIndex(where: { $0.bundleIdentifier == runningApp.bundleIdentifier }) {
            let item = dockItems[index]
            dockItems[index].isRunning = false
            
            // 将该应用插入 recentApplications 的头部
            if !recentApplications.contains(where: { $0.id == item.id }) {
                recentApplications.insert(item, at: 0)
                // 控制 recentApplications 的数量，如只保留最近 10 个
                if recentApplications.count > 10 {
                    recentApplications.removeLast()
                }
            }
        }
    }
    
    // 加载 dockItems 的逻辑（如从持久化存储加载）
    func loadDockItems() {
         dockItems = DockDataManager.shared.loadDockItems()
    }
    
    // 如果需要在 Dock Items 变化时持久化
    func saveDockItems() {
         DockDataManager.shared.saveDockItems(dockItems)
    }
    
    // 可在合适的时机调用该函数，查看当前运行的应用，更新 dockItems 的 isRunning 状态
    func updateRunningStates() {
        for i in dockItems.indices {
            if let bundleIdentifier = dockItems[i].bundleIdentifier {
                dockItems[i].isRunning = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).count > 0
            }
        }
    }
}

