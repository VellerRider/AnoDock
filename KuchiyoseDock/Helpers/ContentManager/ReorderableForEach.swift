//
//  ReordereableForEach.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/12/25.
//

import SwiftUI
import UniformTypeIdentifiers


struct ReorderableForEach<Content: View>: View {
    // 直接使用 [DockItem]
    let items: [DockItem]
    
    // moveAction: (IndexSet, Int, DockItem?)
    let moveAction: (IndexSet, Int, DockItem?) -> Void
    let finishAction: () -> Void
    
    let content: (DockItem) -> Content
    
    // 拖拽过程中
    @State private var hasChangedLocation: Bool = false
    @State private var draggingItem: DockItem?  // 只用 DockItem

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
            if index == DragDropManager.shared.orderedDockItems.count {
                Rectangle()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 1, height: 48)
                    .padding(.vertical, 8)
            }
            
            content(item)
                .padding(.horizontal, 2)
                .padding(.vertical, 1)
                // 如果当前在拖拽这个 item，就让它透明
                .opacity(draggingItem == item ? 0 : 1)
                .onDrag {
                    draggingItem = item
                    return NSItemProvider(object: "\(item.id)" as NSString)
                }
                .onDrop(
                    of: [UTType.text, UTType.fileURL],
                    delegate: DragRelocateDelegate(
                        item: item,
                        listData: items,
                        current: $draggingItem,
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
    let item: DockItem
    let listData: [DockItem]
    
    @Binding var current: DockItem?
    @Binding var hasChangedLocation: Bool
    
    // 第三个参数 DockItem? 用来表示“外部插入的新DockItem”
    var moveAction: (IndexSet, Int, DockItem?) -> Void
    var finishAction: () -> Void
    
    func dropEntered(info: DropInfo) {
        // 如果 current == nil，说明可能是外部拖拽
        // 外部 Finder 拖入
        if current == nil,
           let itemProvider = info.itemProviders(for: [UTType.fileURL]).first,
           let to = listData.firstIndex(of: item)
        {
            itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                guard let data = urlData as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      let newDockItem = DockObserver.shared.createItemFromURL(url: url)
                else { return }
                
                DispatchQueue.main.async {
                    // 1) 插入( from = -1 表示外部新增 )
                    moveAction(IndexSet(integer: -1), to, newDockItem)
                    
                    // 2) 让它成为 current，后面再随着鼠标移动“内部拖拽”
                    self.current = newDockItem
                }
            }
        }
            // 内部重排
            guard let currentDockItem = current else { return }
            DragDropManager.shared.isDragging = true
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
        current = nil
        finishAction()
        return true
    }
}
