//
//  DockNotificationHandler.swift
//  KuchiyoseDock
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
        
        // 注册通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(toggleDockWindow),
            name: Notification.Name("SummonDock"),
            object: nil
        )
    }
    
    @objc private func toggleDockWindow() {
        if !dockWindowState.showDockWindow {
            dockWindowManager.showDock()
        } else {
            dockWindowManager.hideDock()

        }
    }
    
    deinit {
        // 移除通知
        NotificationCenter.default.removeObserver(self, name: Notification.Name("SummonDock"), object: nil)
    }
}
