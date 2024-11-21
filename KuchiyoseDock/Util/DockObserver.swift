//
//  DockObserver.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/19/24.
//

import Foundation
import Cocoa

// observe dock's app, implement two functions
// 1. check what's added to dock, or removed from dock. Only main app and folder.
// 2. check in-dock app when is opened or closed.
class DockObserver: NSObject {
    private var dockPreferencesContext = 0
    
    override init() {
        super.init()
        // Start observing the Dock's persistent apps
        UserDefaults.standard.addObserver(self, forKeyPath: "persistent-apps", options: [.new, .old], context: &dockPreferencesContext)
        UserDefaults.standard.addObserver(self, forKeyPath: "persistent-others", options: [.new, .old], context: &dockPreferencesContext)
    }
    
    deinit {
        // Remove observers when deinitialized
        UserDefaults.standard.removeObserver(self, forKeyPath: "persistent-apps")
        UserDefaults.standard.removeObserver(self, forKeyPath: "persistent-others")
    }
    
    // Handle preference changes
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if context == &dockPreferencesContext {
            if let newValue = change?[.newKey] {
                print("Dock items changed: \(newValue)")
                // Update your custom Dock UI accordingly
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}


