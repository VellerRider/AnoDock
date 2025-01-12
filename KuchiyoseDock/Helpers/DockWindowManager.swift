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

import SwiftUI
import AppKit

class DockWindowManager {
    private var window: NSWindow?
    
    func showDock(observer: DockObserver) {
        // 1. 构建 SwiftUI overlay
        let overlayView = CustomDockOverlayView()
            .environmentObject(observer)
        observer.refreshDock() // refresh everytime showing dock
        
        // 2. 包装成 NSHostingController
        let hostingController = NSHostingController(rootView: overlayView)
        hostingController.view.wantsLayer = true
        
        // 3. 测量视图大小（这里先简单给个 600×600）
        let proposedSize = NSSize(width: 600, height: 600)
        let idealSize = hostingController.sizeThatFits(in: proposedSize)
        let finalWidth = idealSize.width
        let finalHeight = idealSize.height
        
        // 4. 获取鼠标全局位置
        let pointerGlobal = NSEvent.mouseLocation
        
        // 5. 找到鼠标当前所在的屏幕
        guard let screen = NSScreen.screens.first(where: {
            NSMouseInRect(pointerGlobal, $0.frame, false)
        }) else {
            // 如果意外找不到，那就直接用主屏
            // 或者 return
            guard let fallbackScreen = NSScreen.main else { return }
            showDockOnScreen(
                screen: fallbackScreen,
                pointerGlobal: pointerGlobal,
                finalWidth: finalWidth,
                finalHeight: finalHeight,
                hostingController: hostingController
            )
            return
        }
        
        // 6. 真正展示 Dock
        showDockOnScreen(
            screen: screen,
            pointerGlobal: pointerGlobal,
            finalWidth: finalWidth,
            finalHeight: finalHeight,
            hostingController: hostingController
        )
    }
    
    /// 把在“某个 screen + 鼠标全局坐标”上创建窗口的逻辑单独封装一下
    private func showDockOnScreen<V: View>(
        screen: NSScreen,
        pointerGlobal: NSPoint,
        finalWidth: CGFloat,
        finalHeight: CGFloat,
        hostingController: NSHostingController<V>
    ) {
        let screenFrame = screen.frame
        
        // 注意：screenFrame.origin 不一定是 (0, 0)，多显示器下有可能是负数
        // 因此做相对计算时，要先把 pointerGlobal 转成“屏幕内坐标”：
        let pointerLocalX = pointerGlobal.x - screenFrame.origin.x
        let pointerLocalY = pointerGlobal.y - screenFrame.origin.y
        
        // offset，用于避免 Dock 紧贴鼠标
        let offset: CGFloat = 2
        
        // 1. 垂直方向
        var localOriginY: CGFloat
        let distanceBottom = pointerLocalY
        let distanceTop    = screenFrame.height - pointerLocalY
        
        if distanceBottom >= finalHeight {
            // 下方空间够 => Dock 顶部贴鼠标 => originY = pointer.y - finalHeight
            localOriginY = pointerLocalY - finalHeight - offset
        } else if distanceTop >= finalHeight {
            // 上方空间够 => Dock 底部贴鼠标 => originY = pointerLocalY + offset
            localOriginY = pointerLocalY + offset
        } else {
            // 上下都不够完全容纳 => 看哪边空间更大
            if distanceBottom > distanceTop {
                // 放屏幕底边
                localOriginY = offset
            } else {
                // 放屏幕顶边
                localOriginY = screenFrame.height - finalHeight - offset
            }
        }
        
        // 2. 水平方向
        var localOriginX: CGFloat
        let distanceLeft  = pointerLocalX
        let distanceRight = screenFrame.width - pointerLocalX
        
        if distanceRight >= finalWidth {
            // 右侧空间够 => Dock 左边贴鼠标
            localOriginX = pointerLocalX + offset
        } else if distanceLeft >= finalWidth {
            // 左侧空间够 => Dock 右边贴鼠标
            localOriginX = pointerLocalX - finalWidth - offset
        } else {
            // 左右都不够 => 看哪边空间更大
            if distanceLeft > distanceRight {
                // 贴紧左边
                localOriginX = offset
            } else {
                // 贴紧右边
                localOriginX = screenFrame.width - finalWidth - offset
            }
        }
        
        // 3. Clamp，确保不超出这块屏幕
        if localOriginX < 0 {
            localOriginX = 0
        }
        if localOriginX + finalWidth > screenFrame.width {
            localOriginX = screenFrame.width - finalWidth
        }
        if localOriginY < 0 {
            localOriginY = 0
        }
        if localOriginY + finalHeight > screenFrame.height {
            localOriginY = screenFrame.height - finalHeight
        }
        
        // 4. 把它转回全局坐标，用于创建 NSWindow
        let globalOriginX = screenFrame.origin.x + localOriginX
        let globalOriginY = screenFrame.origin.y + localOriginY
        
//        print("Dock final frame in global coords: \(globalOriginX), \(globalOriginY), \(finalWidth), \(finalHeight)")
        
        // 5. 创建窗口
        let newFrame = NSRect(x: globalOriginX, y: globalOriginY,
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
        
        // 6. 简单渐入动画
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
