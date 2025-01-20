//
//  DeleteMaskView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/17/25.
//
import SwiftUI
import Foundation
import UniformTypeIdentifiers
import FluidGradient

struct DeleteMaskView: View {
    @EnvironmentObject var dragDropManager: DragDropManager
    
    var body: some View {
        // 1) Entire window area

        Rectangle()
            .fill(dragDropManager.draggedEnteredDeleteZone ? .red : Color.clear)
            
            .cornerRadius(32)
            
        
        
            
            // 2) Fill color depends on whether the drag is inside
            
            // 3) Use a custom drop delegate
            .onDrop(
                of: [UTType.dockItem, UTType.fileURL],
                delegate: DeleteZoneDropDelegate()
            )
            
            // Only allow pointer events if we are dragging from ReorderableForEach
            .allowsHitTesting(dragDropManager.draggingItem != nil)
    }
}

/// Custom DropDelegate to track dragEnter/exit and final drop
struct DeleteZoneDropDelegate: DropDelegate {
    @ObservedObject var dragDropManager: DragDropManager = .shared
    @ObservedObject var dockObserver: DockObserver = .shared
    
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        .init(operation: .move)
    }
    
    func dropEntered(info: DropInfo) {
        
        guard let item = dragDropManager.draggingItem else { return }
        withAnimation(.dockUpdateAnimation) {
            dragDropManager.orderedItems.removeAll(where: { $0.bundleID == item.bundleID })
            dragDropManager.orderedRecents.removeAll(where: { $0.bundleID == item.bundleID })
            dragDropManager.orderedDockItems.removeAll(where: { $0.bundleID == item.bundleID })
            dragDropManager.draggedOutItem = item
            dragDropManager.draggingItem = nil
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        withAnimation(.easeOut) {
            dragDropManager.saveOrderedItems()
        }
        return true
    }
}
