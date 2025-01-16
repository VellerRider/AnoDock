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
    

    // MARK: - add item to specified place, last by default
    private func addItemToPos(_ newItem: DockItem, _ index: Int?) {
        if let index = dockObserver.recentApps.firstIndex(where: { $0.bundleID == newItem.bundleID }) {
            dockObserver.removeRecent(index)
        }
        dockObserver.addItemToPos(newItem, index)// if not index, then add to last
        dockObserver.saveDockItems()
        dockObserver.refreshDock()
        updateOrderedDockItems()
    }
    // MARK: - removed an ordered item
    func removeOrderedItem(_ bundleID: String) {
        orderedDockItems.removeAll(where: { $0.bundleID == bundleID })
    }
    
    
    
    
    // MARK: - functions used in dock editor
    // add app by button selecting, to last place
    func manualAddApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        if panel.runModal() == .OK, let url = panel.url {
            if let newItem = dockObserver.createItemFromURL(url: url) {
                addItemToPos(newItem, nil)
            }
        }
    }
    // MARK: - add app by drag from finder and drop in current container
    // if not dropped between apps, add to last
    func dropAddApp(providers: [NSItemProvider], targetIndex: Int?) -> Bool {
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
                    
                    if let newItem = self.dockObserver.createItemFromURL(url: url) {
                        DispatchQueue.main.async {
                            self.addItemToPos(newItem, targetIndex ?? self.orderedDockItems.count)
                        }
                    }
                }
            }
        }
        return true
    }
    
    // MARK: - toggle editing mode
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


