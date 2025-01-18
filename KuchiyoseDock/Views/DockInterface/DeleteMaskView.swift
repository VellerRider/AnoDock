//
//  DeleteMaskView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/17/25.
//
import SwiftUI
import Foundation
import UniformTypeIdentifiers

struct DeleteMaskView: View {
    @EnvironmentObject var dragDropManager: DragDropManager
    
    var body: some View {
        // 1) Entire window area
        Rectangle()
            // 2) Fill color depends on whether the drag is inside
            .fill(dragDropManager.draggedEnteredDeleteZone
                  ? Color.red.opacity(0.2)
                  : Color.clear)
            
            // 3) Use a custom drop delegate
            .onDrop(
                of: [UTType.dockItem],
                delegate: DeleteZoneDropDelegate(dragDropManager: dragDropManager)
            )
            
            // Only allow pointer events if we are dragging from ReorderableForEach
            .allowsHitTesting(dragDropManager.draggingItem != nil)
    }
}

/// Custom DropDelegate to track dragEnter/exit and final drop
struct DeleteZoneDropDelegate: DropDelegate {
    @ObservedObject var dragDropManager: DragDropManager = .shared
    @ObservedObject var dockObserver: DockObserver = .shared
    func dropEntered(info: DropInfo) {
        dragDropManager.draggedEnteredDeleteZone = true
    }
    
    func dropExited(info: DropInfo) {
        dragDropManager.draggedEnteredDeleteZone = false
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // "move" means we accept the drop for reordering or similar.
        // Here it's effectively "move" from the dock to 'delete zone'.
        .init(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        dragDropManager.draggedEnteredDeleteZone = false
        guard let newItem = dragDropManager.draggingItem else { return false }
        withAnimation(.dockUpdateAnimation) {
            dockObserver.removeItem(newItem.bundleID)
            dragDropManager.removeSingleItem(newItem.bundleID)
        }
        return true
    }
}
