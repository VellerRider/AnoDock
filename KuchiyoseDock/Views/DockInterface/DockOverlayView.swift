
/*
 The Actual dock interface.
 */
import SwiftUI

struct DockOverlayView: View {
    @EnvironmentObject var dockObserver: DockObserver
    private var itemPopoverManager: ItemPopoverManager = .shared
    private var dockWindowState: DockWindowState = .shared
    private var dockWindowManager: DockWindowManager = .shared
    
    // buffer move operation's load when drag and drop
    @State private var orderedDockItems: [DockItem] = []

    
    var body: some View {
            ZStack {
                VisualEffectView(material: .menu, blendingMode: .behindWindow)
                    .cornerRadius(36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 36)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1) // 半透明白色边框
                    )
                
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        ReorderableForEach(
                            items: orderedDockItems,
                            content: { item in
                                DockItemView(item: item)
                            },
                            moveAction: { from, to in
                                moveTempItems(from: from.first!, to: to)
                            },
                            finishAction: {
                                saveTempItems()
                            }
                        )
                    }
                    .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                        handleDrop(providers: providers)
                    }
                    
                    HStack(spacing: 8) {
                        ForEach(dockObserver.recentApps) { app in
                            DockItemView(item: app)
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
            .onAppear {
                updateOrderedDockItems()
            }

    }
}

extension DockOverlayView {
    func moveTempItems(from: Int, to: Int) {
        let bID = orderedDockItems[from]
        orderedDockItems.remove(at: from)
        orderedDockItems.insert(bID, at: to > from ? to - 1 : to)
    }
    
    // 之后再封装这些暴露逻辑
    func saveTempItems() {
        dockObserver.dockAppOrderKeys = orderedDockItems.map {$0.bundleID }
        dockObserver.refreshDock()
    }
    
    private func updateOrderedDockItems() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
            orderedDockItems = dockObserver.dockAppOrderKeys.compactMap { dockObserver.dockApps[$0] }
        }
    }
    
    /*---------
     editor drop 添加之后 dock ui 不变， 原因： 这里的临时orderedItem没有更新
     TODO: 将这些代码逻辑，以及ordereditem全部封装起来。
     ----------*/
    // 接收从 Finder 等处拖进 .app 文件的逻辑
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, _) in
                    guard
                        let data = item as? Data,
                        let url = URL(dataRepresentation: data, relativeTo: nil),
                        url.pathExtension == "app"
                    else { return }
                    
                    // 根据 .app 文件构造 DockItem
                    if let newItem = createNewAppItem(from: url) {
                        DispatchQueue.main.async {
                            if let index = dockObserver.recentApps.firstIndex(where: { $0.bundleID == newItem.bundleID }) {
                                dockObserver.removeRecent(index)
                            }
                            dockObserver.addItem(newItem)
                            dockObserver.saveDockItems()
                            dockObserver.refreshDock()
                            updateOrderedDockItems()
                        }
                    }
                }
            }
        }
        return true
    }
    
    // 根据本地 .app 路径创建 DockItem
    private func createNewAppItem(from url: URL) -> DockItem? {
        guard url.pathExtension == "app" else { return nil }
        
        // 生成图标并保存
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: 64, height: 64)
        let iconName = saveIconToFile(icon: icon, name: url.lastPathComponent)
        
        // 抽取一些信息
        let name = url.deletingPathExtension().lastPathComponent
        let bundleID = Bundle(path: url.path)?.bundleIdentifier ?? ""
        
        return DockItem(
            id: UUID(),
            name: name,
            iconName: iconName,
            url: url,
            bundleID: bundleID,
            isRunning: false
        )
    }
}
