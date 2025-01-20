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
import UniformTypeIdentifiers

class DockWindowManager: ObservableObject {
    static let shared = DockWindowManager()
    private var dockObserver: DockObserver = .shared
    private var dragDropManager: DragDropManager = .shared
    private var dockWindowState: DockWindowState = .shared
    private var hostingController: NSHostingController<AnyView>?
    
    private var window: NSWindow?
    private var deleteMask: NSWindow?
    // publish position and size of dock
    @Published var dockUIFrame: CGRect = .zero
    // for deleting mask
    
    
    
    
    // MARK: - show dock
    func showDock() {
        if hostingController == nil {
            loadHostingController()
        }
        updateWindowPosition()
        guard let window = window else {
            print("Failed to create window")
            return
        }
        dockObserver.refreshDock()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            window.animator().alphaValue = 1
        }
        window.orderFront(nil)
        dockWindowState.mouseIn = true
        dockWindowState.showDockWindow = true
    }
    
    // MARK: - load HostingController
    func loadHostingController() {
        // inject environement obj for live update
        let overlayView = DockOverlayView(inEditorTab: false, dockMaterial: .fullScreenUI, dockBlendingMode: .behindWindow)
            .environmentObject(dockObserver)
            .environmentObject(dragDropManager)

        hostingController = NSHostingController(rootView: AnyView(overlayView))
    }
    // MARK: - update window position
    func updateWindowPosition() {

        let proposedSize = NSSize(width: 600, height: 600)
        let idealSize = hostingController?.sizeThatFits(in: proposedSize) ?? proposedSize
        let finalWidth = idealSize.width
        let finalHeight = idealSize.height
        
        let pointerGlobal = NSEvent.mouseLocation
        
        guard let screen = NSScreen.screens.first(where: {
            NSMouseInRect(pointerGlobal, $0.frame, false)
        }) else {
            return
        }
        let screenFrame = screen.frame
        
        let pointerLocalX = pointerGlobal.x - screenFrame.origin.x
        let pointerLocalY = pointerGlobal.y - screenFrame.origin.y
        
        let offset: CGFloat = 4
        
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
        // 5. 创建窗口
        let newFrame = NSRect(x: globalOriginX, y: globalOriginY,
                              width: finalWidth, height: finalHeight)
        // 计算 deleteMaskFrame 的新尺寸
        let deleteMaskWidth = newFrame.width * 1.5
        let deleteMaskHeight = newFrame.height * 3
        let deleteMaskX = newFrame.midX - deleteMaskWidth / 2
        let deleteMaskY = newFrame.midY - deleteMaskHeight / 2
        let deleteMaskFrame = NSRect(
            x: deleteMaskX,
            y: deleteMaskY,
            width: deleteMaskWidth,
            height: deleteMaskHeight
        )
        // save for dynamic settings width
        dockUIFrame = newFrame
        // guarantee window & deletemask exist
        if window == nil {
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
            self.window = newWindow
        }
        if deleteMask == nil {
            let deleteZone = NSWindow(
                contentRect: deleteMaskFrame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            deleteZone.backgroundColor = .clear
            let deleteView = DeleteMaskView()
                .environmentObject(dragDropManager)
            deleteZone.contentViewController = NSHostingController(rootView: deleteView)
            self.deleteMask = deleteZone
        }
        
        window?.setFrame(newFrame, display: false)// render later
        deleteMask?.setFrame(deleteMaskFrame, display: false)
        window?.addChildWindow(deleteMask!, ordered: .below)
        
    }
    
    // MARK: - hide dock
    func hideDock() {
        guard let window = window else {
            print("No window assigned")
            return
        }
        guard deleteMask != nil else {
            print("No delete mask assigned")
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.1
            window.animator().alphaValue = 0
        } completionHandler: {
            window.orderOut(nil)
        }
        dockWindowState.mouseIn = false
        dockWindowState.showDockWindow = false
    }

    

    
}
