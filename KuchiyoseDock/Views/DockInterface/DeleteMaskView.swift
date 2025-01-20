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
    @EnvironmentObject var dockWindowState: DockWindowState
    var body: some View {
        // 1) Entire window area
        
        ZStack {
            
            
            Rectangle()
                .fill(dragDropManager.isDragging ? Color.white.opacity(0.001) : Color.clear)
                
            
        }
        .onDrop(
            of: [UTType.dockItem, UTType.fileURL],
            delegate: DeleteZoneDropDelegate()
        )


    }
}

/// Custom DropDelegate to track dragEnter/exit and final drop
struct DeleteZoneDropDelegate: DropDelegate {
    @ObservedObject var dragDropManager: DragDropManager = .shared
    @ObservedObject var dockObserver: DockObserver = .shared
    @ObservedObject var dockWindowManager: DockWindowManager = .shared
    
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        .init(operation: .move)
    }
    
    func dropEntered(info: DropInfo) {
        guard let item = dragDropManager.draggingItem else { return }
        DispatchQueue.main.async {
            print("Item entered delete zone")
            withAnimation(.dockUpdateAnimation) {
                dragDropManager.orderedItems.removeAll(where: { $0.bundleID == item.bundleID })
                dragDropManager.orderedRecents.removeAll(where: { $0.bundleID == item.bundleID })
                dragDropManager.orderedDockItems.removeAll(where: { $0.bundleID == item.bundleID })
                dragDropManager.draggedOutItem = item
                print("Dragged out is this? \(dragDropManager.draggedOutItem == item)")
                dragDropManager.draggingItem = nil
            }
        }
    }
    
    func performDrop(info: DropInfo) -> Bool {
        DispatchQueue.main.async {
            withAnimation(.easeOut) {
                // after dropping, send notification of hide deletemask
                dragDropManager.saveOrderedItems()
            }
        }
        return true
    }
}
