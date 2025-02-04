//
//  TooltipManager.swift
//  KuchiyoseDock
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
    /// 显示工具提示
    /// - Parameters:
    ///   - text: 要显示的文字（例如当前 view 的名称）
    ///   - viewBound: 当前 view 在全局坐标中的 CGRect
    func showTooltip(text: String, viewBound: CGRect) {
        // 如果已有提示窗口，则先隐藏
        hideTooltip()
//        print("View bound passed: \(viewBound)")
        // 固定提示框大小（你也可以根据文字计算尺寸）
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
        // 使用浮动窗口级别，确保提示框显示在最前面
        window.level = .floating
        // 忽略鼠标事件，避免阻挡下面的交互
        window.ignoresMouseEvents = true
        window.orderFrontRegardless()
        self.tooltipWindow = window
    }
    
    /// 隐藏提示框
    func hideTooltip() {
        tooltipWindow?.orderOut(nil)
        tooltipWindow = nil
    }
}
