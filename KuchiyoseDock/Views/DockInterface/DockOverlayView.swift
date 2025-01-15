
/*
 The Actual dock interface.
 */
import SwiftUI

struct DockOverlayView: View {
    @EnvironmentObject var dockObserver: DockObserver
    @EnvironmentObject var dragDropManager: DragDropManager
    
    private var itemPopoverManager: ItemPopoverManager = .shared
    private var dockWindowState: DockWindowState = .shared
    private var dockWindowManager: DockWindowManager = .shared
    
    var inEditorTab: Bool

    init (inEditorTab: Bool) {
        self.inEditorTab = inEditorTab
    }
    
    var body: some View {
            ZStack {
                VisualEffectView(material: .menu, blendingMode: .behindWindow)
                    .cornerRadius(36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 36)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1) // 半透明白色边框
                    )
                
                VStack(spacing: 12) {
                    HStack {
                        ReorderableForEach(
                            items: dragDropManager.orderedDockItems,
                            content: { item in
                                DockItemView(item: item, inEditor: inEditorTab)
                            },
                            moveAction: { from, to in
                                dragDropManager.moveOrderedItems(from: from.first!, to: to)
                            },
                            finishAction: {
                                dragDropManager.saveOrderedItems()
                            }
                        )
                    }

                    
                    HStack(spacing: 8) {
                        ForEach(dockObserver.recentApps) { app in
                            DockItemView(item: app, inEditor: inEditorTab)
                        }
                    }
                    
                }
                .padding(8)
            }
            .fixedSize()
            .onHover { entered in
                dockWindowState.mouseIn = entered
                if !entered {
                    dockWindowManager.hideDock()
                }
            }
            // drop apps from outside
            .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                dragDropManager.dropAddApp(providers: providers, targetIndex: nil)// add to last
            }
            .onAppear {
                dragDropManager.updateOrderedDockItems()
            }

    }
}

