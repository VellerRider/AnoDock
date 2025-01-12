//
//  DockObserver.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/19/24.
//


// observe dock's app, implement these functions
// 1. Track dock configuration. Check what's added to dock, or removed from dock. Only main app and folder.
// 2. Watch in-dock app when is opened or closed.
// 3. TODO: help with recent apps. track latest closed app or files.
// TODO: implement folder logic later
// TODO: implement system dock setting edit later

import Foundation
import Cocoa
import Combine

class DockObserver: NSObject, ObservableObject {
    // use dictionary to maintain apps with bundleID
    @Published var dockApps: [String: DockItem] = [:]
    // array to maintain order of apps
    @Published var dockAppOrderKeys: [String] = []

    // array for recents for order
    @Published var recentApps: [DockItem] = []
    
    private var maxRecentApps: Int { 5 }  // max limit out-of-dock recent apps
    
    private var pollTimer: Timer?
    
    override init() {
        super.init()
        
        // Observe application launch and termination notifications
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
        
        // 启动一个每秒执行的 Timer，自动调用 updateRunningStates 和 updateRecentApplications
        pollTimer = Timer.scheduledTimer(
            timeInterval: 2.5,
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

    
    // MARK: - polling to avoid some problem
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
            // in dock, just update
            if let app = self.dockApps[bundleID] {
                app.isRunning = true
            // in recent, update and lift to front
            } else if let index = self.recentApps.firstIndex(where: { $0.bundleID == bundleID }) {
                self.recentApps[index].isRunning = true
                if index != 0 {
                    let app = self.recentApps.remove(at: index)
                    self.recentApps.insert(app, at: 0)
                }
            // not in anywhere, try add it
            } else {
                self.insertIntoRecent(createDockItem(from: runningApp))
            }
            // always refresh, there is not too much cost
            self.refreshDock()
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
            // if app is in dock or recents, update it
            if let app = self.dockApps[bundleID] {
                app.isRunning = false
            } else if let index = self.recentApps.firstIndex(where: { $0.bundleID == bundleID } ) {
                self.recentApps[index].isRunning = false
            }
            // always refresh, there is not too much cost
            self.refreshDock()
        }
    }

    
    // MARK: - 将 item 插入到 recentApplications，并处理容量限制
    private func insertIntoRecent(_ newDockItem: DockItem?) {
        guard let newDockItem = newDockItem else {
            print("Error: Attempted to insert nil into recentApps")
            return
        }
        // reach max recent limit, pop last one
        if recentApps.count >= maxRecentApps {
            // 优先移除一个“未在运行的” DockItem
            if let index = recentApps.lastIndex(where: { !$0.isRunning }) {
                recentApps.remove(at: index)
            } else {
                // 如果都在运行，那就只能移除最旧的（数组第一个）
                recentApps.removeLast()
            }
        }
        // 把新 item 加到开头
        recentApps.insert(newDockItem, at: 0)
    }
    

    
    // MARK: - Initialization. Load and Save. Not for recent apps.
    // only use when open and close this app. Order is persisted using an array.
    func loadDockItems() {
        // Load from persistent storage
        let apps = DockDataManager.shared.loadDockItems()
        self.dockApps = Dictionary(uniqueKeysWithValues: apps.map { ($0.bundleID, $0) })
        // retrieve order
        self.dockAppOrderKeys = apps.map { $0.bundleID }
    }
    
    func saveDockItems() {
        // 按 dockAppOrderKeys 的顺序组合出 [DockItem]
        let appsToSave = dockAppOrderKeys.compactMap { key -> DockItem? in
            return dockApps[key]
        }
        DockDataManager.shared.saveDockItems(appsToSave)
    }
    
    
    // MARK: - Initialization to align custom dock to system dock
    // after loading custom dock, need to mirror app states.
    func syncRecentApps() {
        // sort running apps by time launched
        let runningApps = NSWorkspace.shared.runningApplications.filter{ $0.activationPolicy == .regular }
//        for app in runningApps {
//            print("App Name: \(app.localizedName ?? "Unknown")")
//            print("Bundle Identifier: \(app.bundleIdentifier ?? "Unknown")")
//            print("---")
//        }
        let sortedApps = runningApps.compactMap { app -> (NSRunningApplication, Date)? in
            guard let launchDate = app.launchDate else { return nil }
            return (app, launchDate)
        }.sorted { $0.1 > $1.1 }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for (app, _) in sortedApps {
                guard let bID = app.bundleIdentifier else { continue }
                
                if self.dockApps[bID] != nil { continue }
                
                if !self.recentApps.contains(where: { $0.bundleID == bID }) {
                    guard let newRecent = createDockItem(from: app) else {
                        print("Failed to create DockItem instance for \(String(describing: app.localizedName)) with bundleID\(bID)")
                        continue
                    }
                    self.recentApps.append(newRecent)
                }
                if self.recentApps.count == self.maxRecentApps {
                    break;
                }
            }
        }
    }
    
    // MARK: - refresh dock to handle special apps like facetime, clock, craft
    // regular cases should be handled by launch and terminate observer
    func refreshDock() {
        // 一次获取所有正在运行的App的BundleID
        let runningBundleIDs = Set(NSWorkspace.shared.runningApplications.filter{ $0.activationPolicy == .regular }.compactMap { $0.bundleIdentifier })
        for bID in dockApps.keys {
            dockApps[bID]?.isRunning = runningBundleIDs.contains(bID)
        }
        for app in recentApps {
            app.isRunning = runningBundleIDs.contains(app.bundleID)
        }
        // 总是重排recents
        // 将 isRunning=true 的 DockItem 排在前面
        // sort(by:) 是就地操作(in-place)
        recentApps.sort { lhs, rhs in
            // running 的排前面，non-running 排后面
            // 若两者同是 running 或同是非 running，则保持原位置关系并不重要时可返回 false
            // 如果需要稳定排序，需要另外实现算法或使用外部辅助空间
            lhs.isRunning && !rhs.isRunning
        }
    }
}
