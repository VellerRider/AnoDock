//
//  DockWindowManager.swift
//  KuchiyoseDock
//
//  Created by John Yang on 12/28/24.
//

/*
 A helper class for displaying custom dock.
 */
import SwiftUI
import AppKit

class DockWindowManager {
    private var window: NSWindow?
    
    func showDock(items: [DockItem]) {
        // 1. Create the SwiftUI view for the custom dock
        let overlayView = CustomDockOverlayView(items: items)
        
        // 2. Wrap in an NSHostingController
        let hostingController = NSHostingController(rootView: overlayView)
        
        // Optional: make the background transparent
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.cornerRadius = 12
        hostingController.view.layer?.masksToBounds = true
        
        // 3. Calculate a window size (you can measure precisely if needed)
        let windowSize = NSSize(width: 600, height: 200)
        
        // 4. Position near mouse location
        let mouseLocation = NSEvent.mouseLocation
        // macOS coordinate system has (0,0) at the bottom-left screen corner.
        // If you want the window to appear above the mouse, shift the Y.
        
        // Typically, you might want the window's bottom to be near the cursor
        let screenHeight = NSScreen.main?.frame.height ?? 1000
        let windowOrigin = NSPoint(
            x: mouseLocation.x - windowSize.width / 2,
            y: screenHeight - mouseLocation.y - windowSize.height / 2
        )
        
        // 5. Create an NSWindow with borderless style
        let newWindow = NSWindow(
            contentRect: NSRect(origin: windowOrigin, size: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        newWindow.isReleasedWhenClosed = false
        newWindow.level = .modalPanel  // So it appears above normal windows
        newWindow.backgroundColor = .clear
        newWindow.isOpaque = false
        newWindow.hasShadow = true
        
        // 6. Assign the content
        newWindow.contentViewController = hostingController
        newWindow.makeKeyAndOrderFront(nil)
        
        self.window = newWindow
    }
    
    func hideDock() {
        window?.close()
        window = nil
    }
}
