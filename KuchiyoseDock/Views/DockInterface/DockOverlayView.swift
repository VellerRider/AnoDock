
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
    @ObservedObject var dockEditorSettings: DockEditorSettings = .shared
    
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
            .border(Color.white.opacity(0.2), width: 0.75)
            .cornerRadius(24)
            .padding(36)
            .shadow(color: dragDropManager.draggedOutItem != nil ? Color.accentColor : Color.clear,
                    radius: dragDropManager.draggedOutItem != nil ? 12 : 0)
        }
        .fixedSize()
//        .onHover { entered in
//            if !inEditorTab {
//                dockWindowState.mouseIn = entered
//                if dockEditorSettings.cursorClose {
//                    if !entered && !dragDropManager.isDragging {
//                        dockWindowManager.hideDock()
//                    }
//                }
//            }
//        }
        .onDrop(of: [UTType.dockItem, UTType.fileURL], delegate: dropLeaveDockDelegate(inEditor: $inEditorTab))
        .onAppear {
            // 同步最新 DockItem 列表到 dragDropManager
            dragDropManager.updateOrderedItems()
            
        }


    
    }
}
struct dropLeaveDockDelegate: DropDelegate {
    @ObservedObject var dragDropManager: DragDropManager = .shared
    @ObservedObject var dockObserver: DockObserver = .shared
    @ObservedObject var dockWindowManager: DockWindowManager = .shared
    @ObservedObject var dockWindowState: DockWindowState = .shared
    @Binding var inEditor: Bool
    func performDrop(info: DropInfo) -> Bool {
        // 如果dock中的item drop进这里，应该让他返回原地
        dragDropManager.saveOrderedItems()
        return false
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
