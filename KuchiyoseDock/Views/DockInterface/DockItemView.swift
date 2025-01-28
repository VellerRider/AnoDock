//
//  File.swift
//  KuchiyoseDock
//  Displaying the icons and support functions like macOS dock.
//  Created by John Yang on 11/17/24.
//

// View for single item in the dock UI
import SwiftUI
import ServiceManagement

struct DockItemView: View {
    @EnvironmentObject var dockObserver: DockObserver
    @EnvironmentObject var dockEditorSettings: DockEditorSettings
    @EnvironmentObject var dragDropManager: DragDropManager
    
    @ObservedObject var dockWindowManager: DockWindowManager = .shared
    @ObservedObject var dockWindowState: DockWindowState = .shared
    
    @ObservedObject var item: DockItem
    
    @State private var isPressed: Bool = false
    
    @State private var viewBounds: CGRect = .zero // 记录视图范围
    @State private var verticalOffset: CGFloat = 72 // vertical offset for mouse in item detection

    @State var deleted: Bool = false

    
    var inEditor: Bool // in editor or not
    
    var body: some View {
        ZStack {
            loadIcon()
                .brightness(isPressed ? -0.2 : 0)
                .animation(.easeInOut(duration: 0.05), value: isPressed)
            
            if inEditor && dockEditorSettings.isEditing {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.red)
                    .position(x: 5, y: 5)
                    .onTapGesture {
                        deleteSelf()
                    }
                    .transition(.opacity)
            }
            
            if item.isRunning {
                Circle()
                    .fill(Color.black.opacity(0.75))
                    .frame(width: 4, height: 4)
                    .offset(y: 34)
            }
        }
        .animation(.easeInOut, value: deleted)
//        .simultaneousGesture(
////              NOT WORKING A BUG
//            LongPressGesture(minimumDuration: inEditor ? 0.75 : 3)
//                .onChanged { value in
//                    print("onChanged: \(value)")
//                }
//                .updating(self.$pressGesture) { currentState, gestureState, transaction in
//                    print("currentState: \(currentState)")
//                    print("gestureState: \(gestureState)")
//                    print("transaction: \(transaction)")
//                    gestureState = currentState
//                    if !isPressed && !inEditor {
//                        openItem(item)
//                    }
//                }
//                .onEnded { finished in
//                    print("finished: \(finished)")
//                }
//        )
        
        // 现在onPressingChanged会将app换到前台。
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        // 初始记录视图范围
                        self.viewBounds = geometry.frame(in: .global)
                        print("initial view bounds:\(self.viewBounds)")
                    }
                    .onChange(of: isPressed, { oldValue, newValue in
                        if isPressed {
                            
                            self.viewBounds = geometry.frame(in: .global)
                            print("new view bounds:\(self.viewBounds)")
                        }
                    })
            }
        )
        .onLongPressGesture(
            minimumDuration: inEditor ? 0.5 : .infinity,
            maximumDistance: inEditor ? 10 : 50,
            perform: {
            if inEditor {
                dragDropManager.toggleEditingMode()
            }
        }, onPressingChanged: { pressing in
            isPressed = pressing
            if (!pressing && !inEditor) {
                let mousePos = mouseLocationInWindow()
                print("mousePos: \(mousePos)")
                print(viewBounds.minX)
                print(viewBounds.maxX)
                print(viewBounds.minY)
                print(viewBounds.maxY)
                
                if viewBounds.contains(mousePos) {
                    openItem(item) // 如果鼠标在范围内，打开项目
                } else {
                    print("Mouse left the view bounds, skipping openItem.")
                }
                
            }
        })

        
        .contextMenu {
            if !dragDropManager.isDragging {
                contextMenuItems(item: item)
            }
        }
        
    }
    /// 获取鼠标的位置
    func mouseLocationInWindow() -> CGPoint {
        let mouseScreenPos = NSEvent.mouseLocation   // 屏幕坐标
        print("dock UI: \(dockWindowManager.dockUIFrame)");
        // 把屏幕坐标减去 window 的 origin，就得到了“窗口内”的坐标
        return CGPoint(
            x: mouseScreenPos.x - dockWindowManager.dockUIFrame.minX,
            y: mouseScreenPos.y - dockWindowManager.dockUIFrame.minY + verticalOffset
        )
    }
    // MARK: - Icon Logic
    @ViewBuilder
    private func loadIcon() -> some View {
        if let nsImage = dockObserver.getIcon(item) {
            Image(nsImage: nsImage)
                .resizable()
                .frame(width: 64, height: 64)
                .cornerRadius(8)
        } else {
            Image(systemName: "app.fill")
                .resizable()
                .foregroundColor(.gray)
                .frame(width: 64, height: 64)
                .cornerRadius(8)
        }
    }
    
    // MARK: - Context Menu
    @ViewBuilder
    private func contextMenuItems(item: DockItem) -> some View {

        // display all front windows
        if item.isRunning {
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
        // miscellaneous
        Divider()
        if item.isRunning {
            Button("Show All Windows") {
                showAllWindowsWithAppleScript(bundleID: item.bundleID)
            }
            if dockObserver.appWindowsHidden[item.bundleID] ?? false { // is hiden
                Button("Show") {
                    showApplication(bundleIdentifier: item.bundleID)
                }
            } else {
                Button("Hide") { // is showing
                    hideApplication(bundleIdentifier: item.bundleID)
                }
            }
            Button("Quit") {
                quitApplication(bundleIdentifier: item.bundleID)
            }
        } else {
            Button("Open") {
                openItem(item)
            }
        }
    }
    

    
    // switch to some window
    private func switchToWindow(window: AXUIElement) {
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
        //只要上门正确地排列了窗口顺序，直接open似乎就可以
        openItem(item)
        
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
            
            Button(action: {
                toggleKeepInDock(item) // 切换状态
            }) {
                if dockObserver.dockItems.contains(where: { $0.bundleID == item.bundleID}) {
                    Text("Remove from Dock")
                } else {
                    Text("Keep in Dock")
                }
            }
            
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
        }
        
    }
    
    // MARK: - toggle item in dock
    private func toggleKeepInDock(_ item: DockItem) {
        if dockObserver.dockItems.contains(where: { $0.bundleID == item.bundleID }) {
            dockObserver.removeItem(item.bundleID)
        } else {
            dockObserver.addItemToPos(item, nil)// add to last by default
            dockObserver.refreshDock()
        }
    }
    
    // MARK: - Left-click. Just for Apps.
    private func openItem(_ dockItem: DockItem) {
        
        launchOrActivateApplication(bundleIdentifier: dockItem.bundleID, url: dockItem.url)
    
    }
    
    // MARK: - Delete Item
    private func deleteSelf() {
        withAnimation(.dockUpdateAnimation) {
            dockObserver.removeItem(item.bundleID)
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
        dockObserver.appWindowsHidden[bundleIdentifier] = true
    }
    
    private func showApplication(bundleIdentifier: String?) {
        guard let bundleIdentifier = bundleIdentifier,
              let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
        else { return }
        runningApp.unhide()
        dockObserver.appWindowsHidden[bundleIdentifier] = false
        openItem(item)
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
