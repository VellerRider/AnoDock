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

import Foundation
import Cocoa
import Combine

class DockObserver: NSObject, ObservableObject {
    @Published var dockItems: [DockItem] = []
    @Published var recentApplications: [DockItem] = []
    
    private var dockPreferencesContext = 0
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        
        // 1. Observe changes in UserDefaults for Dock preference keys
        UserDefaults.standard.addObserver(self,
                                          forKeyPath: "persistent-apps",
                                          options: [.new, .old],
                                          context: &dockPreferencesContext)
        UserDefaults.standard.addObserver(self,
                                          forKeyPath: "persistent-others",
                                          options: [.new, .old],
                                          context: &dockPreferencesContext)
        
        // 2. Observe application launch and termination notifications
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(appLaunched(_:)),
                                                          name: NSWorkspace.didLaunchApplicationNotification,
                                                          object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self,
                                                          selector: #selector(appTerminated(_:)),
                                                          name: NSWorkspace.didTerminateApplicationNotification,
                                                          object: nil)
        
        // 3. Initial load of Dock items
        loadDockItems()
    }
    
    deinit {
        // Stop observing
        UserDefaults.standard.removeObserver(self, forKeyPath: "persistent-apps")
        UserDefaults.standard.removeObserver(self, forKeyPath: "persistent-others")
        
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.removeObserver(self, name: NSWorkspace.didTerminateApplicationNotification, object: nil)
    }
    
    // MARK: - KVO for Dock Preferences
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if context == &dockPreferencesContext {
            if let newValue = change?[.newKey] {
                print("Dock items changed: \(newValue)")
                // e.g. parse persistent-apps, update dockItems, etc.
                // updateDockItemsFromPreferences()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
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
        
        // Find the DockItem with a matching .app(bundleIdentifier)
        if let index = dockItems.firstIndex(where: { dockItem in
            switch dockItem.type {
            case let .app(storedBundleID):
                return storedBundleID == bundleID
            case .folder:
                return false
            }
        }) {
            // Mark it as running
            dockItems[index].isRunning = true
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
        
        // Find the DockItem with a matching .app(bundleIdentifier)
        if let index = dockItems.firstIndex(where: { dockItem in
            switch dockItem.type {
            case let .app(storedBundleID):
                return storedBundleID == bundleID
            case .folder:
                return false
            }
        }) {
            // Mark it as not running
            dockItems[index].isRunning = false
            
            // Also add to recent applications if not already in there
            let item = dockItems[index]
            if !recentApplications.contains(where: { $0.id == item.id }) {
                recentApplications.insert(item, at: 0)
                // Limit to last 10
                if recentApplications.count > 10 {
                    recentApplications.removeLast()
                }
            }
        }
    }
    
    // MARK: - Load and Save
    func loadDockItems() {
        // Load from persistent storage
        dockItems = DockDataManager.shared.loadDockItems()
    }
    
    func saveDockItems() {
        // Save to persistent storage
        DockDataManager.shared.saveDockItems(dockItems)
    }
    
    // MARK: - Update Running States
    func updateRunningStates() {
        for i in dockItems.indices {
            switch dockItems[i].type {
            case let .app(bundleID):
                if let bundleID = bundleID {
                    dockItems[i].isRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
                }
            case .folder:
                // Folders aren't "running", so ignore
                break
            }
        }
    }
}
