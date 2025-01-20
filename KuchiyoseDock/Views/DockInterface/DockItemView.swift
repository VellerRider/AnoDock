//
//  File.swift
//  KuchiyoseDock
//  Displaying the icons and support functions like macOS dock.
//  Created by John Yang on 11/17/24.
//

// View for single item in the dock UI
import SwiftUI
import Pow
import ServiceManagement

struct DockItemView: View {
    @EnvironmentObject var dockObserver: DockObserver
    @EnvironmentObject var dockEditorSettings: DockEditorSettings
    @EnvironmentObject var dragDropManager: DragDropManager
    @ObservedObject var item: DockItem
    @State var isHovering: Bool = false
    @State var deleted: Bool = false
    
    var inEditor: Bool // in editor or not
    
    var body: some View {
        ZStack {
            ZStack {
                loadIcon()
                
                
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
            }
            
            if item.isRunning {
                Circle()
                    .fill(Color.black.opacity(0.75))
                    .frame(width: 4, height: 4)
                    .offset(y: 34)
            }
        }
        .animation(.easeInOut, value: deleted)
        .onTapGesture {
            openItem(item)
        }
        .onLongPressGesture(perform: {
            if inEditor {
                dragDropManager.toggleEditingMode()
            }
        })
        .contextMenu {
            contextMenuItems(item: item)
        }
        .onHover { hovering in
            isHovering = hovering
        }
        
        
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
    
    // MARK: - Folder Thumbnail
    @ViewBuilder
    private func folderThumbnail(_ folderItems: [DockItem]) -> some View {
        if folderItems.isEmpty {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                Image(systemName: "folder")
                    .foregroundColor(.gray.opacity(0.7))
                    .font(.system(size: 22))
            }
        } else {
            GeometryReader { geo in
                let cellSize = geo.size.width / 3
                let slice = folderItems.prefix(9)
                ZStack {
                    ForEach(slice.indices, id: \.self) { i in
                        let row = i / 3
                        let col = i % 3
                        if let subIcon = dockObserver.getIcon(slice[i]) {
                            Image(nsImage: subIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: cellSize, height: cellSize)
                                .offset(
                                    x: CGFloat(col) * cellSize - geo.size.width / 2 + cellSize / 2,
                                    y: CGFloat(row) * cellSize - geo.size.height / 2 + cellSize / 2
                                )
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: cellSize, height: cellSize)
                                .offset(
                                    x: CGFloat(col) * cellSize - geo.size.width / 2 + cellSize / 2,
                                    y: CGFloat(row) * cellSize - geo.size.height / 2 + cellSize / 2
                                )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Context Menu
    @ViewBuilder
    private func contextMenuItems(item: DockItem) -> some View {
        // display all front windows
        if item.isRunning {
            applicationWindowItems(item: item)
        }
        Divider()
        // keep/remove; open at login; show in finder
        optionsMenu(item: item)
        // miscellaneous
        Divider()
        if item.isRunning {
            Button("Show All Windows") {
                // 难搞
            }
            Button("Hide") {
                hideApplication(bundleIdentifier: item.bundleID)
            }
            Button("Quit") {
                quitApplication(bundleIdentifier: item.bundleID)
            }
        } else {
            Button("Show Recents") {
                // 够呛能做
            }
            Button("Open") {
                openItem(item)
            }
        }
    }
    
    @ViewBuilder
    private func applicationWindowItems(item: DockItem) -> some View {
        let windows = getApplicationWindows(bundleIdentifier: item.bundleID)
        if !windows.isEmpty {
            ForEach(windows, id: \.self) { windowTitle in
                Button(windowTitle) {
                    switchToWindow(bundleIdentifier: item.bundleID, windowTitle: windowTitle)
                }
            }
        }
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
    
    // 具体实现逻辑
    private func toggleKeepInDock(_ item: DockItem) {
        if dockObserver.dockItems.contains(where: { $0.bundleID == item.bundleID }) {
            dockObserver.removeItem(item.bundleID)
        } else {
            dockObserver.addItemToPos(item, nil)// add to last by default
            dockObserver.refreshDock()
        }
    }
    
    
    @ViewBuilder
    private func basicActionsMenu(item: DockItem) -> some View {
        if item.isRunning {
            Button("Show All Windows") {
                launchOrActivateApplication(bundleIdentifier: item.bundleID, url: item.url)
            }
            Button("Hide") {
                hideApplication(bundleIdentifier: item.bundleID)
            }
            Button("Quit") {
                quitApplication(bundleIdentifier: item.bundleID)
            }
        }
    }
    
    
    // 切换到指定窗口
    private func switchToWindow(bundleIdentifier: String?, windowTitle: String) {
        // TODO: 切换窗口的实现，这需要更深层次的 Accessibility API 使用。
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
        runningApp.terminate()
    }
    
    private func hideApplication(bundleIdentifier: String?) {
        guard let bundleIdentifier = bundleIdentifier,
              let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
        else { return }
        runningApp.hide()
    }
    
    private func getApplicationWindows(bundleIdentifier: String?) -> [String] {
        guard let bundleIdentifier = bundleIdentifier else { return [] }
        
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        guard let app = runningApps.first else { return [] }
        
        var windows: [String] = []
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)
        if result == .success, let arrayRef = value {
            // We know it's a CFArray, so cast it directly to [AXUIElement].
            if let axWindowArray = arrayRef as? [AXUIElement] {
                for axWindow in axWindowArray {
                    var title: CFTypeRef?
                    if AXUIElementCopyAttributeValue(axWindow, kAXTitleAttribute as CFString, &title) == .success,
                       let titleString = title as? String,
                       !titleString.isEmpty {
                        windows.append(titleString)
                    }
                }
            }
            return windows
        }
        return []
    }
}
