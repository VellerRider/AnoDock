//
//  TooltipManager.swift
//  AnoDock
//
//  Created by John Yang on 2/1/25.
//

import Foundation
import AppKit
import SwiftUI
class TooltipManager {
    static let shared = TooltipManager()
    private var tooltipWindow: NSWindow?
    private var dockEditorSettings: DockEditorSettings = .shared

    func showTooltip(text: String, viewBound: CGRect) {
        hideTooltip()
//        print("View bound passed: \(viewBound)")
        let hostingController = NSHostingController(rootView: TooltipView(text: text))
        let tooltipSize = CGSize(width: 400, height: 200)
        let idealSize = hostingController.sizeThatFits(in: tooltipSize)
        let tooltipX =  DockWindowManager.shared.dockUIFrame.minX + viewBound.midX - idealSize.width / 2 + dockEditorSettings.dockPadding
        let tooltipY =  DockWindowManager.shared.dockUIFrame.minY + viewBound.minY + dockEditorSettings.dockPadding * 2.2
        
        let tooltipFrame = NSRect(x: tooltipX, y: tooltipY, width: idealSize.width, height: idealSize.height)
//        print("Frame is: \(tooltipFrame)")
                
        let window = NSWindow(contentRect: tooltipFrame,
                              styleMask: .borderless,
                              backing: .buffered,
                              defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentViewController = hostingController
        window.level = .floating
        window.hasShadow = true
        // ignore mouse event, don't disturb other actions
        window.ignoresMouseEvents = true
        window.orderFrontRegardless()
        self.tooltipWindow = window
    }
    
    func hideTooltip() {
        tooltipWindow?.orderOut(nil)
        tooltipWindow = nil
    }
}
