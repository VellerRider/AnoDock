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
import UniformTypeIdentifiers

class DragDropManager: ObservableObject {
    static let shared = DragDropManager()
    
    // 1) Dock 的临时有序数组，用于在编辑模式下重排（你之前就有的）
    var orderedDockItems: [DockItem] = []
    var orderedRecents: [DockItem] = []
    @Published var orderedItems: [DockItem] = []
    
    @Published var isDragging: Bool = false // for polling
    @Published var draggingItem: DockItem? = nil
    // for save temp item
    @Published var draggedOutItem: DockItem? = nil
    @Published var draggedEnteredDeleteZone: Bool = false
    
    private var dockObserver: DockObserver = .shared
    private var dockEditorSettings: DockEditorSettings = .shared
    
    // MARK: - Dock Reordering
    // 排序和动画的过程是同时进行的。
    
    func moveOrderedItems(from: Int, to: Int, Item: DockItem?) {
        
        // 1) 如果是外部 Finder 拖来的 .app => fromIndex = -1
        if from == -1 {
            guard let newItem = Item else { return }
            // 把新 item 插入到 orderedItems
            orderedItems.insert(newItem, at: min(to, orderedItems.count))
            
            // 同时插入到 orderedDockItems 或 orderedRecents
            if to < orderedDockItems.count {
                // 插入到 dock
                orderedDockItems.insert(newItem, at: to)
            }
            return
        }
        
        // in same area rearrange
        if (from < orderedDockItems.count && to <= orderedDockItems.count) ||
            (from >= orderedDockItems.count && to > orderedDockItems.count) {
            let draggedItem = orderedItems.remove(at: from)
            orderedItems.insert(draggedItem, at: to > from ? to - 1 : to)
            if from < orderedDockItems.count {
                orderedDockItems.remove(at: from)
                orderedDockItems.insert(draggedItem, at: to > from ? to - 1 : to)
            } else {
                let realFrom = from - orderedDockItems.count
                let realTo = to - orderedDockItems.count
                orderedRecents.remove(at: realFrom)
                orderedRecents.insert(draggedItem, at: realTo > realFrom ? realTo - 1  : realTo)
            }
        } else if from >= orderedDockItems.count && to <= orderedDockItems.count{
            // 先调整combined数组，再动分开的
            let draggedItem = orderedItems.remove(at: from)
            orderedRecents.remove(at: from - orderedDockItems.count) // use real index
            orderedDockItems.insert(draggedItem, at: to)
            orderedItems.insert(draggedItem, at: to > from ? to - 1 : to)
        } else if from < orderedDockItems.count && to >= orderedDockItems.count{
            let draggedItem = orderedItems.remove(at: from)
            orderedDockItems.remove(at: from)
            orderedItems.insert(draggedItem, at: to - 1)
            let realTo = to - orderedDockItems.count
            orderedRecents.insert(draggedItem, at: realTo - 1)
        }
        // else: in dock to recent, not implemented yet
    }
    // 将 这里 同步回 dockObserver
    func saveOrderedItems() {
        dockObserver.dockItems = orderedDockItems
        dockObserver.recentApps = orderedRecents
        dockObserver.saveDockItems()
        isDragging = false
        draggingItem = nil
        draggedEnteredDeleteZone = false
        draggedOutItem = nil
        dockObserver.refreshDock()
        // 这里不要call back updateOrderedItems了。
        // 放到refresh里面了。updateOrderedItems()
    }
    
    // 更新 orderedDockItems 到最新 dockObserver 状态
    // observer变，这里才需要变。
    func updateOrderedItems() {
        withAnimation(.dockUpdateAnimation) {
            self.orderedDockItems = dockObserver.dockItems
            self.orderedRecents = dockObserver.recentApps
            self.orderedItems = orderedDockItems + orderedRecents
        }
    }
    
    // self delete
    func removeSingleItem(_ bundleID: String) {
        withAnimation(.dockUpdateAnimation) {
            self.orderedItems.removeAll(where: { $0.bundleID == bundleID })
            self.orderedRecents.removeAll(where: { $0.bundleID == bundleID })
            self.orderedDockItems.removeAll(where: { $0.bundleID == bundleID })
            saveOrderedItems()
            dockObserver.refreshDock()
        }
    }
    
    
    // MARK: - 添加新 App 到 Dock
    // 例如通过 NSOpenPanel 选取 .app
    func manualAddApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        
        if panel.runModal() == .OK, let url = panel.url {
            if let newItem = dockObserver.createItemFromURL(url: url) {
                dockObserver.addItemToPos(newItem, nil)
                dockObserver.saveDockItems()
                dockObserver.refreshDock()
            }
        }
    }
    
    
    // MARK: - 跨列表拖拽 (从 Finder 或 Recents 拖到 Dock)
    func dropAddApp(providers: [NSItemProvider], targetIndex: Int?) -> Bool {
        for provider in providers {
            // 这里用 "public.file-url" 来判断是否是文件拖拽
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, _) in
                    guard
                        let data = item as? Data,
                        let url = URL(dataRepresentation: data, relativeTo: nil),
                        url.pathExtension == "app"
                    else {
                        print("Not an .app or not supported!")
                        return
                    }
                    
                    // 创建并插入 Dock
                    if let newItem = self.dockObserver.createItemFromURL(url: url) {
                        DispatchQueue.main.async {
                            // 放入 dock
                            self.dockObserver.addItemToPos(newItem, targetIndex)
                            self.dockObserver.saveDockItems()
                            self.dockObserver.refreshDock()
//                            self.updateOrderedItems()
                        }
                    }
                }
            }
        }
        return true
    }
    
    
    // MARK: - 切换编辑模式（示例）
    func toggleEditingMode() {
        dockEditorSettings.isEditing.toggle()
        if !dockEditorSettings.isEditing {
            // 收尾动作
            updateOrderedItems()
            dockObserver.saveDockItems()
            dockObserver.refreshDock()
        }
    }
}

