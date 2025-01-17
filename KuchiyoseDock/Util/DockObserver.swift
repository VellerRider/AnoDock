//
//  DockObserver.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/19/24.
//


// observe dock's app, implement these functions
// 1. Track dock configuration. Check what's added to dock, or removed from dock. Only main app and folder.
// 2. Watch in-dock app when is opened or closed.
// 3. dealing with special apps that does not send notification when terminated
// TODO: implement folder logic later
// TODO: implement system dock setting edit later

import Foundation
import Cocoa
import Combine
import AppKit
import SwiftUI

class DockObserver: NSObject, ObservableObject {
    static let shared = DockObserver()
    
    // 移除原来的字典 dockApps；现在只用这个数组来维护 dock 的应用和顺序
    @Published var dockItems: [DockItem] = []
    
    // 仍保留最近使用的应用
    @Published var recentApps: [DockItem] = []
    
    // item.BundleID : icon
    var appIcons: [String: NSImage] = [:]
    
    private var runningRecents: Int = 0   // track how many running recent apps
    private var maxRecentApps: Int { 5 }  // max limit out-of-dock recent apps
    
    private var pollTimer: Timer?
    
    // MARK: - Init / Deinit
    override init() {
        super.init()
        
        // Observe application launch/termination
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appLaunched(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appTerminated(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
        
        // Initial load of Dock items
        loadDockItems()
        retrieveIcons()

        
        // Polling timer
        pollTimer = Timer.scheduledTimer(
            timeInterval: recentApps.count > 7 ? 2 : 4,
            target: self,
            selector: #selector(pollUpdate),
            userInfo: nil,
            repeats: true
        )
    }
    
    deinit {
        // Stop observing
        UserDefaults.standard.removeObserver(self, forKeyPath: "persistent-apps")
        UserDefaults.standard.removeObserver(self, forKeyPath: "persistent-others")
        
        NSWorkspace.shared.notificationCenter.removeObserver(
            self,
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.removeObserver(
            self,
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
        
        pollTimer?.invalidate()
    }
    
    
    // MARK: - Timer Polling
    @objc private func pollUpdate() {
        refreshDock()
    }
    
    
    // MARK: - Application Launch
    @objc private func appLaunched(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let runningApp = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            let bundleID = runningApp.bundleIdentifier
        else {
            return
        }
        DispatchQueue.main.async {
            withAnimation(.dockUpdateAnimation) {
                // 如果已经在 dockItems 中，就更新 isRunning
                if let dockIndex = self.dockItems.firstIndex(where: { $0.bundleID == bundleID }) {
                    self.dockItems[dockIndex].isRunning = true
                    
                    // 如果在 recentApps 中，就更新并移到 front
                } else if let index = self.recentApps.firstIndex(where: { $0.bundleID == bundleID }) {
                    self.recentApps[index].isRunning = true
                    if index != 0 {
                        let app = self.recentApps.remove(at: index)
                        self.recentApps.insert(app, at: 0)
                    }
                } else {
                    // 不在 dock / recent，就创建一个新的 DockItem 插入 recent
                    guard let url = runningApp.bundleURL else { return }
                    guard let item = self.createItemFromURL(url: url) else { return }
                    self.insertIntoRecent(item)
                    self.loadIconFromWorkspace(item)
                }
                self.refreshDock()
            }
        }
    }
    
    
    // MARK: - Application Termination
    @objc private func appTerminated(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let runningApp = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            let bundleID = runningApp.bundleIdentifier
        else {
            return
        }
        DispatchQueue.main.async {
            withAnimation(.dockUpdateAnimation) {
                // 如果在 dockItems 中，则更新 isRunning
                if let dockIndex = self.dockItems.firstIndex(where: { $0.bundleID == bundleID }) {
                    self.dockItems[dockIndex].isRunning = false
                }
                // 如果在 recentApps 中
                if let index = self.recentApps.firstIndex(where: { $0.bundleID == bundleID }) {
                    self.recentApps[index].isRunning = false
                    if self.recentApps.count > self.maxRecentApps {
                        self.recentApps.remove(at: index)
                    }
                }
                
                self.refreshDock()
            }
        }
    }
    
    
    // MARK: - DockItem creation
    func createItemFromURL(url: URL) -> DockItem? {
        guard url.pathExtension == "app" else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 64, height: 64)
        
        let name = url.deletingPathExtension().lastPathComponent
        let bundleID = Bundle(path: url.path)?.bundleIdentifier ?? ""
        
        let item = DockItem(
            id: UUID(),
            name: name,
            url: url,
            bundleID: bundleID,
            isRunning: false
        )
        loadIconFromWorkspace(item)
        return item
    }
    
    
    // MARK: - Move items in the dock
    /// 用于拖拽重排 DockItem 的顺序
    func moveItem(from: Int, to: Int) {
        guard from >= 0, from < dockItems.count,
              to >= 0, to <= dockItems.count else { return }
        
        let item = dockItems.remove(at: from)
        dockItems.insert(item, at: (to > from) ? (to - 1) : to)
    }
    
    
    // MARK: - Remove an item from dock
    func removeItem(_ bundleID: String) {
    
        dockItems.removeAll(where: { $0.bundleID == bundleID })
        recentApps.removeAll(where: { $0.bundleID == bundleID })
    }
    
    
    // MARK: - Remove an item from recents
    func removeRecent(_ index: Int) {
        recentApps.remove(at: index)
    }
    
    
    // MARK: - Add item to dock (at specific position)
    func addItemToPos(_ newItem: DockItem?, _ index: Int?) {
        guard let newItem = newItem else {
            print("Error: Attempted to add nil to dockItems")
            return
        }
        // 如果之前在 recentApps，就先移除
        if let idx = recentApps.firstIndex(where: { $0.bundleID == newItem.bundleID }) {
            removeRecent(idx)
        }
        // 插入到指定位置（或末尾）
        let insertIndex = index ?? dockItems.count
        dockItems.insert(newItem, at: min(insertIndex, dockItems.count))
    }
    
    
    // MARK: - Insert item into recents
    private func insertIntoRecent(_ newDockItem: DockItem?) {
        guard let newDockItem = newDockItem else {
            print("Error: Attempted to insert nil into recentApps")
            return
        }
        recentApps.insert(newDockItem, at: 0)
    }
    
    
    // MARK: - Load / Save (Persistent)
    func loadDockItems() {
        // 从持久层加载
        let apps = DockDataManager.shared.loadDockItems()
        // 将其作为 dockItems 的当前状态
        self.dockItems = apps
    }
    
    func saveDockItems() {
        // 直接把 dockItems 持久化
        DockDataManager.shared.saveDockItems(dockItems)
    }
    
    
    // MARK: - Load icon
    private func loadIconFromWorkspace(_ item: DockItem) {
        let icon = NSWorkspace.shared.icon(forFile: item.url.path)
        icon.size = NSSize(width: 64, height: 64)
        appIcons[item.bundleID] = icon
    }
    
    func getIcon(_ item: DockItem) -> NSImage? {
        if let icon = appIcons[item.bundleID] {
            return icon
        } else {
            loadIconFromWorkspace(item)
            return appIcons[item.bundleID]
        }
    }
    
    
    // MARK: - refreshDock
    func refreshDock() {
        
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        // 使用 reduce(into:) 将 runningApps 转换为字典，键为 bundleIdentifier，值为 RunningApplication 实例
        var currentRunningDic = runningApps.reduce(into: [String: NSRunningApplication]()) { result, app in
            if let bundleID = app.bundleIdentifier {
                result[bundleID] = app
            }
        }
        // turn all apps in dock running if it's in curRunningApps.
        // remove that app in currentRunningApp, the ones left add to recent
        for item in dockItems {
            let running = currentRunningDic[item.bundleID] != nil
            if running {
                item.isRunning = true
                currentRunningDic.removeValue(forKey: item.bundleID)
            } else {
                item.isRunning = false
            }
        }
        for item in recentApps {
            let running = currentRunningDic[item.bundleID] != nil
            if running {
                item.isRunning = true
                currentRunningDic.removeValue(forKey: item.bundleID)
            } else {
                item.isRunning = false
            }
        }
        // add every one in the rest of currentRunningApp to recent.
        // 好像把syncRecent的逻辑吸收了。
        for app in currentRunningDic.values {
            guard let url = app.bundleURL else { return }
            guard let newRecent = self.createItemFromURL(url: url) else {
                print("Failed to create DockItem instance for \(String(describing: app.localizedName))")
                continue
            }
            newRecent.isRunning = true
            self.recentApps.append(newRecent)
        }
        
        
        // 让 running = true 的 recentApps 在前面
        recentApps = recentApps.enumerated()
            .sorted { lhs, rhs in
                let (lhsIndex, lhsApp) = lhs
                let (rhsIndex, rhsApp) = rhs
                // 如果 isRunning 不同，则把 running=true 的排前面
                if lhsApp.isRunning != rhsApp.isRunning {
                    return lhsApp.isRunning && !rhsApp.isRunning
                }
                // 否则保持稳定排序
                return lhsIndex < rhsIndex
            }
            .map { $0.element }
        
        // 更新 runningRecents 计数
        runningRecents = recentApps.filter { $0.isRunning }.count
        
        // 如果 runningRecents 超过 maxRecentApps
        if runningRecents > maxRecentApps {
            recentApps = Array(recentApps.prefix(runningRecents))
        } else {
            recentApps = Array(recentApps.prefix(maxRecentApps))
        }
        DragDropManager.shared.updateOrderedItems()

    }
    

    
    
    // MARK: - retrieveIcons
    func retrieveIcons() {
        // 为 dockItems 和 recentApps 中的每个 DockItem 加载图标
        for item in dockItems {
            loadIconFromWorkspace(item)
        }
        for item in recentApps {
            loadIconFromWorkspace(item)
        }
    }
}
