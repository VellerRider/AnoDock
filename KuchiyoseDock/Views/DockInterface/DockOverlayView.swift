
/*
 The Actual dock interface.
 */
import SwiftUI
import UniformTypeIdentifiers

struct DockOverlayView: View {
    @EnvironmentObject var dockObserver: DockObserver
    @EnvironmentObject var dragDropManager: DragDropManager
    
    @ObservedObject var dockWindowState: DockWindowState = .shared
    @ObservedObject var dockWindowManager: DockWindowManager = .shared
    
    @State var inEditorTab: Bool
    @State var dockMaterial: NSVisualEffectView.Material
    @State var dockBlendingMode: NSVisualEffectView.BlendingMode
    

    init (inEditorTab: Bool, dockMaterial: NSVisualEffectView.Material, dockBlendingMode: NSVisualEffectView.BlendingMode) {
        self.inEditorTab = inEditorTab
        self.dockMaterial = dockMaterial
        self.dockBlendingMode = dockBlendingMode
    }
    
    var body: some View {
        ZStack {
            

            ZStack {
                VisualEffectView(material: dockMaterial, blendingMode: dockBlendingMode)
                    .border(Color.white.opacity(0.2), width: 0.75)
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
        .onDrop(of: [UTType.dockItem, UTType.fileURL], delegate: dropLeaveDockDelegate(inEditor: $inEditorTab))
    
    }
}
struct dropLeaveDockDelegate: DropDelegate {
    @ObservedObject var dragDropManager: DragDropManager = .shared
    @ObservedObject var dockObserver: DockObserver = .shared
    @Binding var inEditor: Bool
    func performDrop(info: DropInfo) -> Bool {
        // 如果dock中的item drop进这里，应该让他返回原地
        dragDropManager.saveOrderedItems()
        return false
    }
    
    func dropEntered(info: DropInfo) {
        if !inEditor {
            dragDropManager.draggedEnteredDeleteZone = false
            
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // "move" means we accept the drop for reordering or similar.
        // Here it's effectively "move" from the dock to 'delete zone'.
        .init(operation: .move)
    }
    
    func dropExited(info: DropInfo) {
        if dragDropManager.draggingItem != nil {
            if !inEditor {
            // 内部拖出，或者内部卡缝drop
                dragDropManager.draggedEnteredDeleteZone = true
            }
        }
    }
}



#Preview {
    let dockObserver = DockObserver.shared
    let dockWindowManager = DockWindowManager.shared
    let dragDropManager = DragDropManager.shared
    let hotKeySettings = HotKeySettings.shared
    let itemPopoverManager = ItemPopoverManager.shared
    let dockWindowState = DockWindowState.shared
    let dockEditorSettings = DockEditorSettings.shared
    DockOverlayView(inEditorTab: false, dockMaterial: .fullScreenUI, dockBlendingMode: .behindWindow)
        .environmentObject(dockObserver)
        .environmentObject(dockWindowManager)
        .environmentObject(dragDropManager)
        .environmentObject(hotKeySettings)
        .environmentObject(itemPopoverManager)
        .environmentObject(dockWindowState)
        .environmentObject(dockEditorSettings)
}
