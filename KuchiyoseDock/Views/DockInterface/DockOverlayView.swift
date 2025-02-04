
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
    @State var dockMaterial: NSVisualEffectView.Material
    @State var dockBlendingMode: NSVisualEffectView.BlendingMode
    
    @State private var itemFrames: [UUID: CGRect] = [:]

    
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
                        }
                    )
                    .border(Color.black, width: 0.5)
                    
                }
                .padding(8)
                .coordinateSpace(name: "DockOverlayCoordSpace")

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
        // 监听所有 item 坐标的变化
        .onPreferenceChange(ItemFrameKey.self) { newFrames in
            self.itemFrames = newFrames
        }
        .onDrop(of: [UTType.dockItem, UTType.fileURL], delegate: dropLeaveDockDelegate(inEditor: $inEditorTab))



    
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
    let dockWindowState = DockWindowState.shared
    let dockEditorSettings = DockEditorSettings.shared
    DockOverlayView(inEditorTab: false, dockMaterial: .fullScreenUI, dockBlendingMode: .behindWindow)
        .environmentObject(dockObserver)
        .environmentObject(dockWindowManager)
        .environmentObject(dragDropManager)
        .environmentObject(hotKeySettings)
        .environmentObject(dockWindowState)
        .environmentObject(dockEditorSettings)
}
