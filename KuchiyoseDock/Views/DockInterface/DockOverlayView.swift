
/*
 DockOverlayView.swift
 
 The Actual dock interface.
 */
import SwiftUI
import UniformTypeIdentifiers



// 上报各个 DockItem 的视图坐标用的 PreferenceKey
struct ItemFrameKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]
    
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        // 合并多个子视图上报的值
        value.merge(nextValue()) { $1 }
    }
}

struct DockOverlayView: View {
    @EnvironmentObject var dockObserver: DockObserver
    @EnvironmentObject var dragDropManager: DragDropManager
    
    @ObservedObject var dockWindowState: DockWindowState = .shared
    @ObservedObject var dockWindowManager: DockWindowManager = .shared
    @ObservedObject var dockEditorSettings: DockEditorSettings = .shared
    
    @State var inEditorTab: Bool
    
    @State private var itemFrames: [UUID: CGRect] = [:]

    
    init (inEditorTab: Bool) {
        self.inEditorTab = inEditorTab
    }
    
    var body: some View {
        ZStack {
            

            ZStack {
                VisualEffectView(material: inEditorTab ? .menu : .fullScreenUI, blendingMode: .behindWindow)

    

                
                HStack(spacing: inEditorTab ? 6 : 6 * dockEditorSettings.dockZoom) {
                    ReorderableForEach(
                        items: dragDropManager.orderedItems,
                        content: { item in
                            DockItemView(item: item, itemFrames: $itemFrames, inEditor: inEditorTab)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .preference(
                                                key: ItemFrameKey.self,
                                                value: [item.id: geo.frame(in: .named("DockOverlayCoordSpace"))]
                                            )
                                    }
                                )
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
                        },
                        inEditor: inEditorTab
                    )
                }
                .padding(inEditorTab ? 6 : 6 * dockEditorSettings.dockZoom)
                .coordinateSpace(name: "DockOverlayCoordSpace")

            }
            .cornerRadius(inEditorTab ? 24 : 24 * dockEditorSettings.dockZoom)
            .padding(inEditorTab ? 36 : dockEditorSettings.dockPadding)
        }
        .fixedSize()
        .onHover { entered in
            if !inEditorTab {
                dockWindowState.mouseIn = entered
                if dockEditorSettings.cursorClose {
                    if !entered && !dragDropManager.isDragging {
                        dockWindowManager.hideDock()
                    }
                }
            }
        }
        // use pref key to listen dockitem change of pos
        .onPreferenceChange(ItemFrameKey.self) { newFrames in
            self.itemFrames = newFrames
        }
        .onDrop(of: [UTType.dockItem, UTType.fileURL], delegate: dropLeaveDockDelegate())
        .animation(.linear, value: dockEditorSettings.dockZoom)
        .shadow(radius: inEditorTab ? 3 : 0)


    
    }
}
struct dropLeaveDockDelegate: DropDelegate {
    @ObservedObject var dragDropManager: DragDropManager = .shared
    @ObservedObject var dockObserver: DockObserver = .shared
    @ObservedObject var dockWindowManager: DockWindowManager = .shared
    @ObservedObject var dockWindowState: DockWindowState = .shared
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // By this you inform user that something will be just relocated
        // So the tiny green symbol is not showing anymore
       return DropProposal(operation: .move)
    }

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
    let dockWindowState = DockWindowState.shared
    let dockEditorSettings = DockEditorSettings.shared
    DockOverlayView(inEditorTab: false)
        .environmentObject(dockObserver)
        .environmentObject(dockWindowManager)
        .environmentObject(dragDropManager)
        .environmentObject(hotKeySettings)
        .environmentObject(dockWindowState)
        .environmentObject(dockEditorSettings)
}
