//
//  DockNotificationHandler.swift
//  AnoDock
//
//  Created by John Yang on 1/12/25.
//

import Foundation
import SwiftUI

class DockNotificationHandler: NSObject {
    private let dockWindowManager: DockWindowManager
    private let dockObserver: DockObserver
    private let dockWindowState: DockWindowState
    
    init(dockWindowManager: DockWindowManager, dockObserver: DockObserver, dockWindowState: DockWindowState) {
        self.dockWindowManager = dockWindowManager
        self.dockObserver = dockObserver
        self.dockWindowState = dockWindowState
        super.init()
        
        // register notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toggleDockWindow),
            name: Notification.Name("SummonDock"),
            object: nil
        )
        
    }
    
    @objc private func toggleDockWindow() {
        // if no permission granted just do nothing
        if !AXIsProcessTrusted() { return }
        if !dockWindowState.showDockWindow {
            dockWindowManager.showDock()
            dockWindowState.showDockWindow = true
        } else {
            dockWindowManager.hideDock()
            dockWindowState.showDockWindow = false
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SummonDock"), object: nil)

    }
}
