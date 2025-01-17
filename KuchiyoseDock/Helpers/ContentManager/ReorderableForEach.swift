//
//  ReordereableForEach.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/12/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct ReorderableForEach<Content: View, Item: Identifiable & Equatable>: View {
    let items: [Item]
    let content: (Item) -> Content
    let moveAction: (IndexSet, Int) -> Void
    let finishAction: () -> Void
    
    @State private var hasChangedLocation: Bool = false

    init(
        items: [Item],
        @ViewBuilder content: @escaping (Item) -> Content,
        moveAction: @escaping (IndexSet, Int) -> Void,
        finishAction: @escaping () -> Void
    ) {
        self.items = items
        self.content = content
        self.moveAction = moveAction
        self.finishAction = finishAction


    }
    
    @State private var draggingItem: Item?
    
    var body: some View {
        ForEach(items, id: \.id) { item in
            content(item)
                .padding(.horizontal, 2)
                .padding(.vertical, 1)
                .opacity(draggingItem == item ? 0 : 1) // 如果正在拖动当前项，则隐藏
                .onDrag {
                    draggingItem = item
                    return NSItemProvider(object: "\(item.id)" as NSString)
                }
                .onDrop(
                    of: [UTType.text],
                    delegate: DragRelocateDelegate(
                        item: item,
                        listData: items,
                        current: $draggingItem,
                        hasChangedLocation: $hasChangedLocation,
                        moveAction: { from, to in
                                moveAction(from, to)
                        },
                        finishAction: {
                                finishAction()
                        }
                    )
                )
        }
    }
}


struct DragRelocateDelegate<Item: Equatable>: DropDelegate {
    let item: Item
    var listData: [Item]
    @Binding var current: Item?
    @Binding var hasChangedLocation: Bool
    
    var moveAction: (IndexSet, Int) -> Void
    var finishAction: () -> Void

    func dropEntered(info: DropInfo) {
        guard item != current, let current = current else { return }
        guard let from = listData.firstIndex(of: current), let to = listData.firstIndex(of: item) else { return }
        
        hasChangedLocation = true

        if from != to && listData[to] != current {
            moveAction(IndexSet(integer: from), to > from ? to + 1 : to)
        }
    }
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        current = nil
        finishAction()
        return true
    }
}
