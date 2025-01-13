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

class DockObserver: NSObject, ObservableObject {
    static let shared = DockObserver()
    // use dictionary to maintain apps with bundleID
    @Published var dockApps: [String: DockItem] = [:]
    // array to maintain order of apps
    @Published var dockAppOrderKeys: [String] = []
    // array for recents for order
    @Published var recentApps: [DockItem] = []
    private var runningRecents: Int = 0   // track how many running recent apps
    private var maxRecentApps: Int { 5 }  // max limit out-of-dock recent apps
    
    private var pollTimer: Timer?
    
    // snapshot for overall state change
    private var lastDockStateHash: Int = 0
    // store NSRunningApplications's bundleID
    private var lastRunningBundleIDs: Set<String> = []

    
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
            timeInterval: lastRunningBundleIDs.count > 7 ? 5 : 10,
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
        lastDockStateHash = 0
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

    // MARK: - adjust order of two items
    func moveItem(from: Int, to: Int) {
        let bID = dockAppOrderKeys[from]
        dockAppOrderKeys.remove(at: from)
        dockAppOrderKeys.insert(bID, at: to > from ? to - 1 : to)
    }
    
    // MARK: - remove in-dock item
    func removeItem(_ bundleID: String) {
        guard let index = dockAppOrderKeys.firstIndex(of: bundleID) else { return }
        dockAppOrderKeys.remove(at: index)
        dockApps.removeValue(forKey: bundleID)
        refreshDock()
    }
    
    // MARK: - 将 item 插入到 recentApplications，并处理容量限制
    private func insertIntoRecent(_ newDockItem: DockItem?) {
        guard let newDockItem = newDockItem else {
            print("Error: Attempted to insert nil into recentApps")
            return
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
        // use snapshot hash to avoid excessive refresh
        let currentDockStateHash = generateDockStateHash()
        // 如果状态未变化，则不进行刷新
        if currentDockStateHash == lastDockStateHash {
            print("No common changes detected, skipping refreshDock.")
            return
        }
        lastDockStateHash = currentDockStateHash

        // 一次获取所有正在运行的App的BundleID
        let currentRunningBundleIDs = Set(NSWorkspace.shared.runningApplications.compactMap { app in
            app.activationPolicy == .regular ? app.bundleIdentifier : nil
        })
        
        // 计算新增和移除的 bundleID
        let addedBundleIDs = currentRunningBundleIDs.subtracting(lastRunningBundleIDs)
        let removedBundleIDs = lastRunningBundleIDs.subtracting(currentRunningBundleIDs)
        
        lastRunningBundleIDs = currentRunningBundleIDs

        // 只更新发生变化的 dockApps 和 recentApps
        for bID in addedBundleIDs {
            dockApps[bID]?.isRunning = true
            if let index = recentApps.firstIndex(where: { $0.bundleID == bID }) {
                recentApps[index].isRunning = true
            }
        }
        
        for bID in removedBundleIDs {
            dockApps[bID]?.isRunning = false
            if let index = recentApps.firstIndex(where: { $0.bundleID == bID }) {
                recentApps[index].isRunning = false
            }
        }
        

        // 稳定排序：将 isRunning = true 的排前面
        recentApps = recentApps.enumerated()
            .sorted { lhs, rhs in
                let (lhsIndex, lhsApp) = lhs
                let (rhsIndex, rhsApp) = rhs
                if lhsApp.isRunning != rhsApp.isRunning {
                    return lhsApp.isRunning && !rhsApp.isRunning
                }
                return lhsIndex < rhsIndex
            }
            .map { $0.element }
        
        // 更新 runningRecents 计数
        runningRecents = recentApps.filter { $0.isRunning }.count
        
        // 如果 runningRecents 少于 maxRecentApps，则只保留前 maxRecentApps 个最近应用
        if runningRecents > maxRecentApps {
            recentApps = Array(recentApps.prefix(runningRecents))
        } else {
            recentApps = Array(recentApps.prefix(maxRecentApps))
        }
    }
    
    // MARK: - keep track of overall state change
    private func generateDockStateHash() -> Int {
        var hasher = Hasher()
        
        // 对 dockApps 的 bundleID 和 isRunning 状态进行哈希
        for (key, value) in dockApps.sorted(by: { $0.key < $1.key }) {
            hasher.combine(key)
            hasher.combine(value.isRunning)
        }
        
        // 对 dockAppOrderKeys 进行哈希
        for key in dockAppOrderKeys {
            hasher.combine(key)
        }
        
        // 对 recentApps 的 bundleID 和 isRunning 状态进行哈希
        for app in recentApps {
            hasher.combine(app.bundleID)
            hasher.combine(app.isRunning)
        }
        
        return hasher.finalize()
    }
}
