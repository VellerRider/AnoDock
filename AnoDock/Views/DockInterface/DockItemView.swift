//
//  File.swift
//  AnoDock
//  Displaying the icons and support functions like macOS dock.
//  Created by John Yang on 11/17/24.
//

// View for single item in the dock UI
import SwiftUI
import ServiceManagement


struct DockItemView: View {
    @EnvironmentObject var dockObserver: DockObserver
    @EnvironmentObject var dragDropManager: DragDropManager
    @ObservedObject var dockEditorSettings: DockEditorSettings = .shared
    
    @ObservedObject var dockWindowManager: DockWindowManager = .shared
    @ObservedObject var dockWindowState: DockWindowState = .shared
    
    @ObservedObject var item: DockItem
    
    @State private var isPressed: Bool = false
    @State private var isHovering: Bool = false
    @State private var viewBounds: CGRect = .zero // 记录view frame

    @Binding var itemFrames: [UUID: CGRect]

    
    @State var deleted: Bool = false

    
    var inEditor: Bool // in editor or not
    
    var body: some View {
        ZStack {
            loadIcon()
            
                .brightness(isPressed ? -0.2 : 0)
                .animation(.easeInOut(duration: 0.05), value: isPressed)
            
            if inEditor && dockEditorSettings.isEditing && (!dragDropManager.orderedRecents.contains(where: { $0.bundleID == item.bundleID }) || !item.isRunning) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .foregroundColor(.red)
                        .onTapGesture {
                            deleteSelf()
                        }
                }
                .frame(width: 16, height: 16)
                .position(x: 9, y: 9)
            }
            
            if item.isRunning {
                Circle()
                    .fill(Color.black.opacity(0.65))
                    .frame(width: inEditor ? 4 : 4  * dockEditorSettings.dockZoom, height: inEditor ? 4 : 4 * dockEditorSettings.dockZoom)
                    .offset(y: inEditor ? 33 : 33 * dockEditorSettings.dockZoom)
            }
        }
        


        .animation(.easeInOut, value: deleted)

        .onLongPressGesture(
            minimumDuration: inEditor ? 0.5 : .infinity,
            maximumDistance: inEditor ? 10 * dockEditorSettings.dockZoom : 50 * dockEditorSettings.dockZoom,
            perform: {
            if inEditor {
                dragDropManager.toggleEditingMode()
            }
        }, onPressingChanged: { pressing in
            isPressed = pressing
            TooltipManager.shared.hideTooltip()
            if (!pressing && !inEditor) { // if in editor, don't open app
                let mousePos = mouseLocationInWindow()
                if let rect = itemFrames[item.id] {
//                    print("Viewbound is \(rect)")
//                    print("mousePos is \(mousePos)")
                    if rect.contains(mousePos) {
                        showApplication(item: item)
                    }
                }
                
                
            }
        })
        .onHover { hovering in
            isHovering = hovering
            if !dragDropManager.isDragging && !inEditor {
                if isHovering {
                    // use parent view's itemFrames[item.id] to get real position here
                    if let rect = itemFrames[item.id] {
                        TooltipManager.shared.showTooltip(text: item.name, viewBound: rect)
                    }
                } else {
                    TooltipManager.shared.hideTooltip()
                }
            }
        }


        
        .contextMenu {
            if !dragDropManager.isDragging {
                contextMenuItems(item: item)
            }
        }
        
    }
    
    
    
    // get mouse location in window, converted to local pos
    // must use this & local geometry reader update, since long press -> drag -> not opening item relies on this
    func mouseLocationInWindow() -> CGPoint {
        let mouseScreenPos = NSEvent.mouseLocation //pos of screen
//        print("dock UI: \(dockWindowManager.dockUIFrame)");
        return CGPoint(
            x: mouseScreenPos.x - dockWindowManager.dockUIFrame.minX - dockEditorSettings.dockPadding,
            y: mouseScreenPos.y - dockWindowManager.dockUIFrame.minY
        )
    }
    // MARK: - Icon Logic
    @ViewBuilder
    private func loadIcon() -> some View {
        if let nsImage = dockObserver.getIcon(item) {
            Image(nsImage: nsImage)
                .resizable()
                .frame(width: inEditor ? 64 : dockEditorSettings.iconWidth, height: inEditor ? 64 : dockEditorSettings.iconWidth)
                .cornerRadius(inEditor ? 8 : 8 * dockEditorSettings.dockZoom)
        } else {
            Image(systemName: "app.fill")
                .resizable()
                .foregroundColor(.gray)
                .frame(width: inEditor ? 64 : dockEditorSettings.iconWidth, height: inEditor ? 64 : dockEditorSettings.iconWidth)
                .cornerRadius(inEditor ? 8 : 8 * dockEditorSettings.dockZoom)
        }
    }
    
    // MARK: - Context Menu
    @ViewBuilder
    private func contextMenuItems(item: DockItem) -> some View {

        // display all front windows

        if item.isRunning && !ProcessInfo.processInfo.isSandboxed {
            let windowElements = dockObserver.appWindows[item.bundleID]
            if windowElements != nil {
                ForEach(windowElements ?? [], id: \.self) { window in
                    if let title = getWindowTitle(window: window) {
                        Button(action: { switchToWindow(window: window) }) {
                            HStack {
                                Image(systemName: "macwindow")
                                Text(title)
                            }
                        }
                    } else {
                        Button(item.name) {
                            switchToWindow(window: window)
                        }
                    }
                }
            }
        }
        Divider()
        // keep/remove; open at login; show in finder
        optionsMenu(item: item)
        Divider()
        
        // MARK: If this app is sandboxed, all of below can't work properly
        if item.isRunning{
            if !ProcessInfo.processInfo.isSandboxed {
                Button("Show All Windows") {
                    showAllWindowsWithAppleScript(bundleID: item.bundleID)
                }
            if dockObserver.appWindowsHidden[item.bundleID] ?? false { // is hidden
                    Button("Show") {
                        showApplication(item: item)
                    }
                } else {
                    Button("Hide") { // is showing
                        hideApplication(bundleIdentifier: item.bundleID)
                    }
                }
                if !ProcessInfo.processInfo.isSandboxed {
                    Button("Quit") {
                        quitApplication(bundleIdentifier: item.bundleID)
                    }
                }
            }
        } else {
            Button("Open") {
                launchOrActivateApplication(bundleIdentifier: item.bundleID, url: item.url)
            }
        }
    }
    

    
    // switch to some window
    private func switchToWindow(window: AXUIElement) {
        launchOrActivateApplication(bundleIdentifier: item.bundleID, url: item.url)
        let raiseError = AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        if raiseError != .success {
            print("Failed to raise window: \(raiseError.rawValue)")
        }
        
        let pressError = AXUIElementPerformAction(window, kAXPressAction as CFString)
        if pressError != .success {
            print("Failed to press window: \(pressError.rawValue)")
        }
        
        let setMainError = AXUIElementSetAttributeValue(window, kAXMainAttribute as CFString, kCFBooleanTrue)
        if setMainError != .success {
            print("Failed to set window as main: \(setMainError.rawValue)")
        }
        
        let setFocusError = AXUIElementSetAttributeValue(window, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        if setFocusError != .success {
            print("Failed to set window as focused: \(setFocusError.rawValue)")
        }
        
        let setFrontmostError = AXUIElementSetAttributeValue(window, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
        if setFrontmostError != .success {
            print("Failed to set window as frontmost: \(setFrontmostError.rawValue)")
        }
        
    }
    // get AXUIElement window's title
    private func getWindowTitle(window: AXUIElement) -> String? {
        print("get title")
        var title: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &title)
        if error == .success, let title = title as? String, !title.isEmpty {
            return title
        }
        return nil
    }
    
    
    @ViewBuilder
    private func optionsMenu(item: DockItem) -> some View {
        Menu("Options") {
            
            if !dockObserver.dockItems.contains(where: { $0.bundleID == item.bundleID}) {
                Button(action: {
                    keepInDock(item)
                }) {
                    Text("Keep in Dock")
                }
                if !item.isRunning {
                    Button(action: {
                        deleteSelf()
                    }) {
                        Text("Remove from Dock")
                    }
                }
            } else {
                Button(action: {
                    deleteSelf()
                }) {
                    Text("Remove from Dock")
                }
            }

            
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
        }
        
    }
    
    // MARK: - toggle item in dock
    private func keepInDock(_ item: DockItem) {
        dockObserver.addItemToPos(item, nil)// add to last by default
        dockObserver.saveDockItems()
        dockObserver.refreshDock()
        dragDropManager.updateOrderedItems()
        
    }
    
    
    // MARK: - Delete Item
    private func deleteSelf() {
        withAnimation(.dockUpdateAnimation) {
            dragDropManager.removeSingleItem(item.bundleID)
        }
    }
    
    // MARK: - Launch/Activate
    private func launchOrActivateApplication(bundleIdentifier: String?, url: URL) {
        NSWorkspace.shared.openApplication(at: url, configuration: .init(), completionHandler: nil)
    }
    
    private func quitApplication(bundleIdentifier: String?) {
        guard let bundleIdentifier = bundleIdentifier,
              let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
        else { return }
        print("Terminating \(bundleIdentifier)")
        
        runningApp.forceTerminate()
    }
    
    private func hideApplication(bundleIdentifier: String?) {
        guard let bundleIdentifier = bundleIdentifier,
              let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
        else { return }
        runningApp.hide()
        print("App is hidden")
        dockObserver.appWindowsHidden[bundleIdentifier] = true
    }
    
    // MARK: - show application, try launch it, then activate it, unhide it.
    private func showApplication(item: DockItem) {
        let bundleIdentifier = item.bundleID
        launchOrActivateApplication(bundleIdentifier: item.bundleID, url: item.url)
        guard let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first else {
            return
        }
        if !runningApp.isActive {
            print("Activting.")
            runningApp.activate(options: .activateAllWindows)
        }
        if runningApp.isHidden {
            print("Unhiding.")
            runningApp.unhide()
            dockObserver.appWindowsHidden[bundleIdentifier] = false
            print("App showed")
        }
    }
    
    func showAllWindowsWithAppleScript(bundleID: String) {
        let appleScriptSource = """
        on showAllWindowsForApp(bundleID)
            tell application "System Events"
                -- Bring the desired app to the front
                set theApp to first application process whose bundle identifier is bundleID
                set frontmost of theApp to true

                -- Simulate the "Show All Windows" key stroke (Control + Down Arrow)
                key code 125 using control down
            end tell
        end showAllWindowsForApp

        showAllWindowsForApp("\(bundleID)")
        """

        if let script = NSAppleScript(source: appleScriptSource) {
            var error: NSDictionary?
            script.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
            }
        }
    }

}
