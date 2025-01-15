//
//  CustomDockView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//
/*
 The interface to edit custom dock.
 */
import SwiftUI
import UniformTypeIdentifiers

struct CustomDockView: View {
    @EnvironmentObject var dockObserver: DockObserver
    @EnvironmentObject var itemPopoverManager: ItemPopoverManager
    @EnvironmentObject var dockEditorSettings: DockEditorSettings
    @EnvironmentObject var dragDropManager: DragDropManager
    // this is especially for reorder by dragging, to create a smooth animation
    let columns = [
        GridItem(.adaptive(minimum: 64), spacing: 4)
    ]
    
    var body: some View {
        VStack {
            ZStack{
                // 用 ScrollView + LazyVGrid 来展示
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 4) {
                        // 根据 dockAppOrderKeys 保证顺序
                        ReorderableForEach(
                            items: dragDropManager.orderedDockItems,
                            content: { item in
                                EditorItemView(item: item)
                                    .onLongPressGesture {
                                        dragDropManager.toggleEditingMode()
                                    }
                            },
                            moveAction: { from, to in
                                dragDropManager.moveOrderedItems(from: from.first!, to: to)
                            },
                            finishAction: {
                                dragDropManager.saveOrderedItems()
                            }
                        )
                        
                        
                    }
                    .padding()
                    .onAppear {
                        dragDropManager.updateOrderedDockItems()
                    }
                }
                .blur(radius: dockEditorSettings.isEditing ? 0.3 : 0) // 添加模糊效果
                .opacity(dockEditorSettings.isEditing ? 0.8 : 1)    // 改变透明度
            }
            .onTapGesture {
                if dockEditorSettings.isEditing {
                    dragDropManager.toggleEditingMode()
                }
            }
            
            HStack {
                Button(action: dragDropManager.manualAddApp) {
                    Image(systemName: "plus")
                        .font(.title)
                }
                Button(action: dragDropManager.toggleEditingMode) {
                    Image(systemName: dockEditorSettings.isEditing ? "checkmark.circle" : "pencil")
                        .font(.title)
                }
            }
        }

        // drop apps from outside
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            dragDropManager.dropAddApp(providers: providers)
        }
    }
}
