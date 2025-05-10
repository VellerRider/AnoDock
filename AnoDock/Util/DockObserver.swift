//
//  DockObserver.swift
//  AnoDock
//
//  Created by John Yang on 11/19/24.
//


// observe dock's app, implement these functions
// 1. Track dock configuration. Check what's added to dock, or removed from dock. Only main app and folder.
// 2. Watch in-dock app when is opened or closed.
// 3. dealing with special apps that does not send notification when terminated

import Foundation
import Cocoa
import Combine
import AppKit
import SwiftUI

class DockObserver: NSObject, ObservableObject {
    
    
    static let shared = DockObserver()
    
    // in dock apps
    @Published var dockItems: [DockItem] = []
    
    // recent apps
    @Published var recentApps: [DockItem] = []
    
    // AXUIElement window for all apps
    @Published var appWindows: [String: [AXUIElement]] = [:]
    // if an app is hidden
    @Published var appWindowsHidden: [String: Bool] = [:]
    // track whether a pid is observed
    private var observers: [pid_t: AXObserver] = [:]

    
    // item.BundleID : icon
    var appIcons: [String: NSImage] = [:]
    
    private var runningRecents: Int = 0   // track how many running recent apps
    
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
            timeInterval: DockWindowState.shared.showDockWindow ? 15 : 3,
            target: self,
            selector: #selector(pollUpdate),
            userInfo: nil,
            repeats: true
        )
    }
    
    deinit {
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
        
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            removeObserverForApp(app)
        }
        observers.removeAll()
        pollTimer?.invalidate()
    }
    
    
    // MARK: - Timer Polling
    @objc private func pollUpdate() {
        if DragDropManager.shared.isDragging {
//            print("Skipping pollUpdate because dragging is in progress.")
            DragDropManager.shared.isDragging = false
            return
        }
//        print("polling updates..., showdock is ", DockWindowState.shared.showDockWindow)
        refreshDock()
        recycleIcons()
        DragDropManager.shared.updateOrderedItems()
    }
    
    
    // MARK: - Application Launch
    @objc private func appLaunched(_ notification: Notification) {
        DispatchQueue.main.async {
            withAnimation(.dockUpdateAnimation) {
                self.refreshDock()
                DragDropManager.shared.updateOrderedItems()
            }
        }
    }
    
    
    // MARK: - Application Termination
    @objc private func appTerminated(_ notification: Notification) {
        DispatchQueue.main.async {
            withAnimation(.dockUpdateAnimation) {
                self.refreshDock()
                DragDropManager.shared.updateOrderedItems()
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
    
    // MARK: - check if this draggedItem exist in observer
    // if not, then it's from outside and not saved yet
    func hasItem(_ bundleID: String) -> Bool {
        return (dockItems.contains(where: { $0.bundleID == bundleID }) || recentApps.contains(where: { $0.bundleID == bundleID }))
    }
    
    // MARK: - Move items in the dock
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
        appIcons.removeValue(forKey: bundleID)
    }
    
    
    // MARK: - Remove an item from recents
    func removeRecent(_ index: Int) {
        guard index >= 0, index < recentApps.count else { return }
        
        let removedItem = recentApps[index]
        recentApps.remove(at: index)
        
        appIcons.removeValue(forKey: removedItem.bundleID)
    }
    
    
    // MARK: - Add item to dock (at specific position)
    func addItemToPos(_ newItem: DockItem?, _ index: Int?) {
        guard let newItem = newItem else {
            print("Error: Attempted to add nil to dockItems")
            return
        }
        // if in recents before, remove first
        if let idx = recentApps.firstIndex(where: { $0.bundleID == newItem.bundleID }) {
            removeRecent(idx)
        }
        // insert in to index, end by default
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
        let apps = DockDataManager.shared.loadDockItems()
        self.dockItems = apps
    }
    
    func saveDockItems() {
        DockDataManager.shared.saveDockItems(dockItems)
    }
    
    

    
    
    // MARK: - refreshDock
    func refreshDock() {
        
        let runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
        // Handle window related stuff here
        for app in runningApps {
            createObserverForApp(app)
            updateAppWindows(for: app)
        }
        recycleAXObservers(runningApps: runningApps)
        recycleAppWindows(runningApps: runningApps)
        var currentRunningDic = runningApps.reduce(into: [String: NSRunningApplication]()) { result, app in
            if let bundleID = app.bundleIdentifier {
                result[bundleID] = app
            }
        }
        // turn all apps in dock isRunning if it's in curRunningDic.
        // remove that app in currentRunningDic, the ones left at last added to recent
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
        for app in currentRunningDic.values {
            guard let url = app.bundleURL else { return }
            guard let newRecent = self.createItemFromURL(url: url) else {
                print("Failed to create DockItem instance for \(String(describing: app.localizedName))")
                continue
            }
            newRecent.isRunning = true
            self.recentApps.append(newRecent)
        }
        
        
        recentApps = recentApps.enumerated()
            .sorted { lhs, rhs in
                let (lhsIndex, lhsApp) = lhs
                let (rhsIndex, rhsApp) = rhs
                // running=true sorted to front
                if lhsApp.isRunning != rhsApp.isRunning {
                    return lhsApp.isRunning && !rhsApp.isRunning
                }
                return lhsIndex < rhsIndex
            }
            .map { $0.element }
        
        // update running recents
        runningRecents = recentApps.filter { $0.isRunning }.count
        // if closedRecents >  keepClosedRecents, truncate excess.
        recentApps = Array(recentApps.prefix(runningRecents + DockEditorSettings.shared.keepClosedRecents))
        
    }
    

    
    
    // MARK: - retrieveIcons
    func retrieveIcons() {
        // load icons for all
        for item in dockItems {
            loadIconFromWorkspace(item)
        }
        for item in recentApps {
            loadIconFromWorkspace(item)
        }
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
    // MARK: - recycle icon memory
    private func recycleIcons() {
        let activeBundleIDs = Set(dockItems.map { $0.bundleID } + recentApps.map { $0.bundleID })
        let allCachedIcons = Set(appIcons.keys)
        
        for bundleID in allCachedIcons.subtracting(activeBundleIDs) {
            appIcons.removeValue(forKey: bundleID)
        }
    }
    
    // MARK: - AXObserver for app
    private func createObserverForApp(_ app: NSRunningApplication) {
        if ProcessInfo.processInfo.isSandboxed { return }
        let pid = app.processIdentifier
        guard observers[pid] == nil else { return }
        var observer: AXObserver?
        let result = AXObserverCreate(pid, axObserverCallback, &observer)
        guard result == .success, let observer else { return }

        let appElement = AXUIElementCreateApplication(pid)

        AXObserverAddNotification(observer, appElement, kAXWindowCreatedNotification as CFString, UnsafeMutableRawPointer(bitPattern: Int(pid)))
        AXObserverAddNotification(observer, appElement, kAXUIElementDestroyedNotification as CFString, UnsafeMutableRawPointer(bitPattern: Int(pid)))
        AXObserverAddNotification(observer, appElement, kAXApplicationHiddenNotification as CFString, UnsafeMutableRawPointer(bitPattern: Int(pid)))
        AXObserverAddNotification(observer, appElement, kAXApplicationShownNotification as CFString, UnsafeMutableRawPointer(bitPattern: Int(pid)))

        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer), .defaultMode)

        observers[pid] = observer
    }

    private func removeObserverForApp(_ app: NSRunningApplication) {
        if ProcessInfo.processInfo.isSandboxed { return }
        let pid = app.processIdentifier
        guard let observer = observers[pid] else { return }

        let appElement = AXUIElementCreateApplication(pid)

        AXObserverRemoveNotification(observer, appElement, kAXWindowCreatedNotification as CFString)
        AXObserverRemoveNotification(observer, appElement, kAXUIElementDestroyedNotification as CFString)
        AXObserverRemoveNotification(observer, appElement, kAXApplicationHiddenNotification as CFString)
        AXObserverRemoveNotification(observer, appElement, kAXApplicationShownNotification as CFString)

        observers.removeValue(forKey: pid)
    }
    
    // MARK: - recycle !isrunning app's AXObserver
    private func recycleAXObservers(runningApps: [NSRunningApplication]) {
        if ProcessInfo.processInfo.isSandboxed { return }
        // all running pids
        let activePids = Set(runningApps.map { $0.processIdentifier })
        
        // iterate through observers, remove if app not running
        for (pid, _) in observers {
            if !activePids.contains(pid) {
                if let app = NSRunningApplication(processIdentifier: pid) {
                    removeObserverForApp(app)
                } else {
                    observers.removeValue(forKey: pid)
                }
            }
        }
    }

    
    // MARK: - 更新单个应用窗口状态 - 从refreshdock分离，因为窗口操作不影响大局
    /// use AXUIElement  to get window status, update appWindowStatus
    func updateAppWindows(for app: NSRunningApplication) {
        if ProcessInfo.processInfo.isSandboxed { return }
        guard let bundleID = app.bundleIdentifier else { return }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        
        var windowsCF: CFArray?
        let err = AXUIElementCopyAttributeValues(appElement, kAXWindowsAttribute as CFString, 0, 100, &windowsCF)
        if err == .success, let windows = windowsCF as? [AXUIElement] {
//            print("success, \(windows.count) is retrieved")
            appWindows[bundleID] = windows
        } else {
//            print("Nah can't get window: \(err)")
            appWindows[bundleID] = []
        }
        
        var hiddenValue: CFTypeRef?
        let hideErr = AXUIElementCopyAttributeValue(appElement, kAXHiddenAttribute as CFString, &hiddenValue)
        if hideErr == .success,
           let isHidden = hiddenValue as? Bool {
            appWindowsHidden[bundleID] = isHidden
        } else {
            appWindowsHidden[bundleID] = false
        }
    }
    // MARK: - Recycle unused app windows (only for non-running apps)
    private func recycleAppWindows(runningApps: [NSRunningApplication]) {
        if ProcessInfo.processInfo.isSandboxed { return }
        let runningBundleIDs = Set(runningApps.compactMap { $0.bundleIdentifier })

        // update app window and hidden status if no longer running
        let allCachedWindows = Set(appWindows.keys)
        for bundleID in allCachedWindows.subtracting(runningBundleIDs) {
            appWindows.removeValue(forKey: bundleID)
            appWindowsHidden.removeValue(forKey: bundleID)
        }
    }
    

    
}

// MARK: - AXObserver callback
func axObserverCallback(observer: AXObserver, element: AXUIElement, notificationName: CFString, userData: UnsafeMutableRawPointer?) {
    if ProcessInfo.processInfo.isSandboxed { return }
    guard let userData else { return }
    let pid = pid_t(Int(bitPattern: userData))

    DispatchQueue.main.async {
        if let app = NSRunningApplication(processIdentifier: pid) {
            guard let bundleID = app.bundleIdentifier else { return }
            switch notificationName as String {
            case kAXUIElementDestroyedNotification, kAXWindowCreatedNotification:
                DockObserver.shared.updateAppWindows(for: app)
            case kAXApplicationHiddenNotification:
                DockObserver.shared.appWindowsHidden[bundleID] = true
            case kAXApplicationShownNotification:
                DockObserver.shared.appWindowsHidden[bundleID] = false
            default:
                break
            }
        }
    }
}
