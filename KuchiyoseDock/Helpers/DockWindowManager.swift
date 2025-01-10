//
//  DockWindowManager.swift
//  KuchiyoseDock
//
//  Created by John Yang on 12/28/24.
//

/*
 A helper class for displaying a custom dock using your existing code structure.
 */

import SwiftUI
import AppKit

class DockWindowManager {
    private var window: NSWindow?
    
    func showDock(observer: DockObserver) {
        // 1. 构建 SwiftUI overlay
        let overlayView = CustomDockOverlayView()
            .environmentObject(observer)
        
        // 2. 包装成 NSHostingController
        let hostingController = NSHostingController(rootView: overlayView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.cornerRadius = 12
        hostingController.view.layer?.masksToBounds = true
        
        // 3. 测量视图大小
        let proposedSize = NSSize(width: 600, height: 10_000)
        let idealSize = hostingController.sizeThatFits(in: proposedSize)
        let finalWidth = min(idealSize.width, 800)
        let finalHeight = min(idealSize.height, 600)
        
        // 4. 获取屏幕、鼠标位置
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let pointer = NSEvent.mouseLocation
        
        // (可以增加一个 offset，让 Dock 不至于跟鼠标点重叠)
        let offset: CGFloat = 2
        
        // 5. 先决定垂直：Dock 在鼠标的上方还是下方？
        var originY: CGFloat
        let distanceBottom = pointer.y           // 鼠标到屏幕底部距离
        let distanceTop = screenFrame.height - pointer.y  // 鼠标到屏幕顶部距离
        
        if distanceBottom >= finalHeight {
            // 下方空间够 => Dock 顶部贴鼠标 => originY = pointer.y - finalHeight
            originY = pointer.y - finalHeight - offset
        } else if distanceTop >= finalHeight {
            // 上方空间够 => Dock 底部贴鼠标 => originY = pointer.y
            originY = pointer.y + offset
        } else {
            // 上下都不够完全容纳 => 看哪边空间更大
            if distanceBottom > distanceTop {
                // 放底部
                originY = offset  // 或者贴到底边 originY = 0
            } else {
                // 放顶部
                originY = screenFrame.height - finalHeight - offset
            }
        }
        
        // 6. 再决定水平：Dock 在鼠标的左侧还是右侧？
        var originX: CGFloat
        let distanceLeft = pointer.x
        let distanceRight = screenFrame.width - pointer.x
        
        if distanceRight >= finalWidth {
            // 右侧空间够 => Dock 左边贴鼠标 => originX = pointer.x
            originX = pointer.x + offset
        } else if distanceLeft >= finalWidth {
            // 左侧空间够 => Dock 右边贴鼠标 => originX = pointer.x - finalWidth
            originX = pointer.x - finalWidth - offset
        } else {
            // 左右都不够 => 看哪边空间更大
            if distanceLeft > distanceRight {
                // 贴紧左边
                originX = offset
            } else {
                // 贴紧右边
                originX = screenFrame.width - finalWidth - offset
            }
        }
        
        // 7. 做一下 clamp，保证不出屏（如果你想允许部分出界，可忽略此步或只 clamp 部分边）
        if originX < 0 {
            originX = 0
        }
        if originX + finalWidth > screenFrame.width {
            originX = screenFrame.width - finalWidth
        }
        
        if originY < 0 {
            originY = 0
        }
        if originY + finalHeight > screenFrame.height {
            originY = screenFrame.height - finalHeight
        }
        print("dock: ", originX, originY, finalWidth, finalHeight)
        print(NSEvent.mouseLocation)
        
        // 8. 创建窗口
        let newFrame = NSRect(x: originX, y: originY,
                              width: finalWidth, height: finalHeight)
        let newWindow = NSWindow(
            contentRect: newFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        newWindow.isOpaque = false
        newWindow.backgroundColor = .clear
        newWindow.hasShadow = true
        newWindow.level = .floating
        
        newWindow.contentViewController = hostingController
        newWindow.alphaValue = 0
        newWindow.orderFront(nil)
        self.window = newWindow
        
        // 9. 简单渐入动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            newWindow.animator().alphaValue = 1
        }
    }
    
    func hideDock() {
        guard let window = window else { return }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            window.animator().alphaValue = 0
        } completionHandler: {
            window.orderOut(nil)
            self.window = nil
        }
    }
}
