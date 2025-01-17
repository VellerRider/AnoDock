
/*
 The Actual dock interface.
 */
import SwiftUI

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
            // 背景模糊等
            VisualEffectView(material: .menu, blendingMode: .behindWindow)
                .cornerRadius(36)
                .overlay(
                    RoundedRectangle(cornerRadius: 36)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                    dragDropManager.dropAddApp(providers: providers, targetIndex: nil)// add to last
                }
            
            VStack(spacing: 12) {
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
            }
            .padding(8)
        }
        .fixedSize()
        .onHover { entered in
            if !inEditorTab {
                dockWindowState.mouseIn = entered
                if !entered {
                    dockWindowManager.hideDock()
                }
            }
        }
        .onAppear {
            // 同步最新 DockItem 列表到 dragDropManager
            dragDropManager.updateOrderedItems()
        }
    }
}
