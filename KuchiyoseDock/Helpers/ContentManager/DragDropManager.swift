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
    
    var orderedDockItems: [DockItem] = [] // items in dock area
    var orderedRecents: [DockItem] = [] // items in recent area
    @Published var orderedItems: [DockItem] = [] // combined item array of two area
    
    @Published var isDragging: Bool = false // for polling
    @Published var draggingItem: DockItem? = nil
    // for save temp item
    @Published var draggedOutItem: DockItem? = nil
    
    @Published var draggedInDockItem: Bool = false
    
    @Published var editorOpen: Bool = false
    
    private var dockObserver: DockObserver = .shared
    private var dockEditorSettings: DockEditorSettings = .shared
    
    // MARK: - Core Dock Reordering Function
    func moveOrderedItems(from: Int, to: Int, Item: DockItem?) {
//        print("from: \(from), to: \(to)")
        
        // 1) 如果是外部 Finder 拖来的 .app => fromIndex = -1
        if from == -1 {
            guard let newItem = Item else { return }
            // 把新 item 插入到 orderedItems
            orderedItems.insert(newItem, at: min(to, orderedItems.count))
            
            // 同时插入到 orderedDockItems 或 orderedRecents
            if to < orderedDockItems.count {
                // 插入到 dock
                orderedDockItems.insert(newItem, at: to)
            } else {
                orderedRecents.insert(newItem, at: to - orderedDockItems.count)
            }
            return
        }
        
        let draggedItem = orderedItems.remove(at: from)
        // in same area rearrange
        if (from < orderedDockItems.count && to <= orderedDockItems.count) ||
            (from >= orderedDockItems.count && to > orderedDockItems.count) {
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
            orderedRecents.remove(at: from - orderedDockItems.count) // use real index
            orderedDockItems.insert(draggedItem, at: to)
            orderedItems.insert(draggedItem, at: to > from ? to - 1 : to)
        } else if from < orderedDockItems.count && to >= orderedDockItems.count{
            orderedDockItems.remove(at: from)
            orderedItems.insert(draggedItem, at: to - 1)
            let realTo = to - orderedDockItems.count
            orderedRecents.insert(draggedItem, at: realTo - 1)
        }
    }
    
    // MARK: - sync data here back to observer
    func saveOrderedItems() {
        dockObserver.dockItems = orderedDockItems
        dockObserver.recentApps = orderedRecents
        isDragging = false
        draggingItem = nil
        draggedOutItem = nil
        draggedInDockItem = false
    }
    
    // MARK: - update date here from observer
    func updateOrderedItems() {
        withAnimation(.dockUpdateAnimation) {
            self.orderedDockItems = dockObserver.dockItems
            self.orderedRecents = dockObserver.recentApps
            self.orderedItems = orderedDockItems + orderedRecents
        }
    }
    
    // self delete here and sync back to observer
    func removeSingleItem(_ bundleID: String) {
        withAnimation(.dockUpdateAnimation) {
            self.orderedItems.removeAll(where: { $0.bundleID == bundleID })
            self.orderedRecents.removeAll(where: { $0.bundleID == bundleID })
            self.orderedDockItems.removeAll(where: { $0.bundleID == bundleID })
            saveOrderedItems()
            dockObserver.saveDockItems()
            dockObserver.refreshDock()
            updateOrderedItems()
        }
    }
    
    
    
    
    // MARK: - 添加多个新 App 到 Dock
    func manualAddApps() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = true // Enable multiple selection
        
        if panel.runModal() == .OK {
            for url in panel.urls { // Iterate over all selected apps
                if let newItem = dockObserver.createItemFromURL(url: url) {
                    if orderedDockItems.contains(where: { $0.bundleID == newItem.bundleID }) {
                        continue // Skip if already in Dock
                    }
                    
                    dockObserver.addItemToPos(newItem, nil)
                }
            }
            
            dockObserver.saveDockItems()
            dockObserver.refreshDock()
            updateOrderedItems()
        }
    }
    
    
    // MARK: - toggle editing mode
    func toggleEditingMode() {
        withAnimation(.easeInOut(duration: 0.1)) {
            
            dockEditorSettings.isEditing.toggle()
            if !dockEditorSettings.isEditing {
                // wrap up
                saveOrderedItems()
                dockObserver.saveDockItems()
                dockObserver.refreshDock()
            }
        }
    }
}

