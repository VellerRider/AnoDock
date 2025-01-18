
/*
 The Actual dock interface.
 */
import SwiftUI
import UniformTypeIdentifiers

struct DockOverlayView: View {
    @EnvironmentObject var dockObserver: DockObserver
    @EnvironmentObject var dragDropManager: DragDropManager
    
    private var dockWindowState: DockWindowState = .shared
    private var dockWindowManager: DockWindowManager = .shared
    
    var inEditorTab: Bool

    init (inEditorTab: Bool) {
        self.inEditorTab = inEditorTab
    }
    
    var body: some View {
        ZStack {
            

            ZStack {
                VisualEffectView(material: .menu, blendingMode: .behindWindow)
                    .cornerRadius(24)
                
                // 1) Dock Items 区域
                HStack {
                    ReorderableForEach(
                        items: dragDropManager.orderedItems,
                        content: { item in
                            DockItemView(item: item, inEditor: inEditorTab)
                        },
                        moveAction: { from, to, item in
                            withAnimation(.dockUpdateAnimation) {
                                dragDropManager.moveOrderedItems(from: from.first!, to: to, Item: item ?? nil)
                            }
                        },
                        finishAction: {
                            withAnimation(.dockUpdateAnimation) {
                                dragDropManager.saveOrderedItems()
                            }
                        }
                    )
                }
                
                .padding(8)
            }
        }
        .fixedSize()
//        .onHover { entered in
//            if !inEditorTab {
//                dockWindowState.mouseIn = entered
//                if !entered {
//                    dockWindowManager.hideDock()
//                }
//            }
//        }
        .onAppear {
            // 同步最新 DockItem 列表到 dragDropManager
            dragDropManager.updateOrderedItems()
        }
        .onDrop(of: [UTType.dockItem], delegate: dropLeaveDockDelegate())
    }
}
struct dropLeaveDockDelegate: DropDelegate {
    @ObservedObject var dragDropManager: DragDropManager = .shared
    
    func performDrop(info: DropInfo) -> Bool {
        return false
    }
    
    func dropEntered(info: DropInfo) {
        dragDropManager.draggedEnteredDeleteZone = false
    }
    
    
    func dropExited(info: DropInfo) {
        dragDropManager.draggedEnteredDeleteZone = true
    }
}
