//
//  ReorderDelegate.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/15/25.
//

/*
 A helper class for drag and drop
 */
import Foundation
import SwiftUI

class DragDropManager: ObservableObject {
    static let shared = DragDropManager()
    // Temp copy of dock item. Will not refresh dock by modifying this. Off some load.
    @Published var orderedDockItems: [DockItem] = []
    private var dockObserver: DockObserver = .shared
    private var dockEditorSettings: DockEditorSettings = .shared
    
    // MARK: - helpers for dragging and rearranging temp items
    func moveOrderedItems(from: Int, to: Int) {
        let bID = orderedDockItems[from]
        orderedDockItems.remove(at: from)
        orderedDockItems.insert(bID, at: to > from ? to - 1 : to)
    }
    
    func saveOrderedItems() {
        dockObserver.dockAppOrderKeys = orderedDockItems.map {$0.bundleID }
        dockObserver.refreshDock()
        updateOrderedDockItems()
    }
    
    // MARK: - update temp items to latest dockobserver's items
    func updateOrderedDockItems() {
        withAnimation(.dockUpdateAnimation) {
            orderedDockItems = dockObserver.dockAppOrderKeys.compactMap { dockObserver.dockApps[$0] }
        }
    }
    

    
    // MARK: - add app by drag from finder and drop in current container
    func dropAddApp(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, _) in
                    guard
                        let data = item as? Data,
                        let url = URL(dataRepresentation: data, relativeTo: nil),
                        url.pathExtension == "app"
                    else {
                        print("Not supported!")
                        return
                    }
                    
                    // 根据 .app 文件构造 DockItem
                    if let newItem = self.createNewAppItem(from: url) {
                        DispatchQueue.main.async {// 重复逻辑日后封装
                            self.addOrUpdateDockItem(newItem)
                        }
                    }
                }
            }
        }
        return true
    }

    
    // MARK: - actual logic to create new DockItem model
    private func createNewAppItem(from url: URL) -> DockItem? {
        guard url.pathExtension == "app" else { return nil }
        
        // 生成图标并保存
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 64, height: 64)
        let iconName = saveIconToFile(icon: icon, name: url.lastPathComponent)
        
        // 抽取一些信息
        let name = url.deletingPathExtension().lastPathComponent
        let bundleID = Bundle(path: url.path)?.bundleIdentifier ?? ""
        
        return DockItem(
            id: UUID(),
            name: name,
            iconName: iconName,
            url: url,
            bundleID: bundleID,
            isRunning: false
        )
    }
    // MARK: - actual add app logic
    private func addOrUpdateDockItem(_ newItem: DockItem) {
        if let index = dockObserver.recentApps.firstIndex(where: { $0.bundleID == newItem.bundleID }) {
            dockObserver.removeRecent(index)
        }
        dockObserver.addItem(newItem)
        dockObserver.saveDockItems()
        dockObserver.refreshDock()
        updateOrderedDockItems()
    }
    
    
    
    
    // MARK: functions used in dock editor
    // add app by button selecting
    func manualAddApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        if panel.runModal() == .OK, let url = panel.url {
            if let newItem = createNewAppItem(from: url) {
                // 新增到字典 + 顺序数组
                if let index = dockObserver.recentApps.firstIndex(where: { $0.bundleID == newItem.bundleID }) {
                    dockObserver.removeRecent(index)
                }
                dockObserver.addItem(newItem)
                dockObserver.saveDockItems()
                dockObserver.refreshDock()
                updateOrderedDockItems()
            }
        }
    }
    // toggle editing mode
    func toggleEditingMode() {
        if !dockEditorSettings.isEditing {
            dockEditorSettings.isEditing.toggle()
        } else {
            updateOrderedDockItems()
            dockObserver.saveDockItems()
            dockObserver.refreshDock()
            dockEditorSettings.isEditing.toggle()
        }
    }
}

extension Animation {
    static let dockUpdateAnimation = Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
}
