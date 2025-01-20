//
//  ReordereableForEach.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/12/25.
//

import SwiftUI
import UniformTypeIdentifiers


struct ReorderableForEach<Content: View>: View {
    @ObservedObject var dragDropManager: DragDropManager = .shared
    let items: [DockItem]
    // moveAction: (IndexSet, Int, DockItem?)
    let moveAction: (IndexSet, Int, DockItem?) -> Void
    let finishAction: () -> Void
    let content: (DockItem) -> Content
    // 拖拽过程中
    @State private var hasChangedLocation: Bool = false
    

    init(
        items: [DockItem],
        @ViewBuilder content: @escaping (DockItem) -> Content,
        moveAction: @escaping (IndexSet, Int, DockItem?) -> Void,
        finishAction: @escaping () -> Void
    ) {
        self.items = items
        self.content = content
        self.moveAction = moveAction
        self.finishAction = finishAction
    }
    
    var body: some View {
        ForEach(Array(items.enumerated()), id: \.1.id) { (index, item) in
            
            // 在 “DockItems” 与 “Recents” 的分界处插入一条线
            if index == dragDropManager.orderedDockItems.count {
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 1, height: 48)
                    .padding(.vertical, 8)
            }
            
            content(item)
                .opacity(dragDropManager.draggingItem == item ? 0 : 1)
                .onDrag {
                    dragDropManager.isDragging = true
                    dragDropManager.draggingItem = item
                    dragDropManager.draggedInDockItem = true
                    return NSItemProvider(item: "\(item.bundleID)" as NSString, typeIdentifier: UTType.dockItem.identifier)
                }
                .onDrop(
                    of: [UTType.text, UTType.fileURL, UTType.dockItem],
                    delegate: DragRelocateDelegate(
                        item: item,
                        listData: items,
                        hasChangedLocation: $hasChangedLocation,
                        moveAction: { from, to, newDockItem in
                            moveAction(from, to, newDockItem)
                        },
                        finishAction: {
                            finishAction()
                        }
                    )
                )
        }
    }
}

struct DragRelocateDelegate: DropDelegate {
    @ObservedObject var dragDropManager: DragDropManager = .shared
    @ObservedObject var dockObserver: DockObserver = .shared
    let item: DockItem
    let listData: [DockItem]
    
//    @Binding var current: DockItem?
    @Binding var hasChangedLocation: Bool
    
    // 第三个参数 DockItem? 用来表示“外部插入的新DockItem”
    var moveAction: (IndexSet, Int, DockItem?) -> Void
    var finishAction: () -> Void
    
    func dropEntered(info: DropInfo) {
        dragDropManager.isDragging = true
        let to = listData.firstIndex(of: item)
        if dragDropManager.draggingItem == nil {
            print("dragging item is nil")
            
            // 从删除区拉回来的
            if let backItem = dragDropManager.draggedOutItem {
                   DispatchQueue.main.async {
                       dragDropManager.draggedOutItem = nil
                        
                       moveAction(IndexSet(integer: -1), to!, backItem)
                       dragDropManager.draggingItem = backItem
                   }
           } else if let itemProvider = info.itemProviders(for: [UTType.fileURL]).first {
                // 外部拖入
               
                itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                    guard let data = urlData as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil),
                          let newDockItem = DockObserver.shared.createItemFromURL(url: url)
                    else { return }
                    DispatchQueue.main.async {
                        if dragDropManager.orderedItems.contains(where: { $0.bundleID == newDockItem.bundleID }) {
                            let bundleID = newDockItem.bundleID
                            dragDropManager.orderedItems.removeAll(where: { $0.bundleID == bundleID })
                            dragDropManager.orderedRecents.removeAll(where: { $0.bundleID == bundleID })
                            dragDropManager.orderedDockItems.removeAll(where: { $0.bundleID == bundleID })
                            print("can't add same item twice")
                        }
                        // 1) 插入( from = -1 表示外部新增 )
                        moveAction(IndexSet(integer: -1), to!, newDockItem)
                        print("Setting to dragging item")
                        // 2) 让它成为 current，后面再随着鼠标移动“内部拖拽”
                        dragDropManager.draggingItem = newDockItem
                    }
                }
            }
        }
//        print("Proceed normal")
        // 内部重排
        guard let currentDockItem = dragDropManager.draggingItem else { return }
        // 在 Swift 中可以这样：
        guard let from = listData.firstIndex(of: currentDockItem),
              let to = listData.firstIndex(of: item) else { return }
        
        hasChangedLocation = true
        
        if from != to && listData[to] != currentDockItem {
            moveAction(IndexSet(integer: from), to > from ? to + 1 : to, nil)
        }
    }


    func dropUpdated(info: DropInfo) -> DropProposal? {
        .init(operation: .move)
    }
    
    
    func performDrop(info: DropInfo) -> Bool {
        // 拖拽完成后，清空 current
        finishAction()
        return true
    }
}
