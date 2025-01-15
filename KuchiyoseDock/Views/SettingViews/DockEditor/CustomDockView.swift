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
    // this is especially for reorder by dragging, to create a smooth animation
    @State private var orderedDockItems: [DockItem] = []
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
                            items: orderedDockItems,
                            content: { item in
                                EditorItemView(item: item)
                                    .onLongPressGesture {
                                        toggleEditingMode()
                                    }
                            },
                            moveAction: { from, to in
                                moveTempItems(from: from.first!, to: to)
                            },
                            finishAction: {
                                saveTempItems()
                            }
                        )
                        
                        
                    }
                    .padding()
                    .onAppear {
                        updateOrderedDockItems()
                    }
                }
                .blur(radius: dockEditorSettings.isEditing ? 0.3 : 0) // 添加模糊效果
                .opacity(dockEditorSettings.isEditing ? 0.8 : 1)    // 改变透明度
            }
            .onTapGesture {
                if dockEditorSettings.isEditing {
                    toggleEditingMode()
                }
            }
            
            HStack {
                Button(action: addNewApp) {
                    Image(systemName: "plus")
                        .font(.title)
                }
                Button(action: toggleEditingMode) {
                    Image(systemName: dockEditorSettings.isEditing ? "checkmark.circle" : "pencil")
                        .font(.title)
                }
            }
        }

        // drop apps from outside
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }
}

// MARK: - Functions
extension CustomDockView {
    
    // helper for dragging 
    func moveTempItems(from: Int, to: Int) {
        let bID = orderedDockItems[from]
        orderedDockItems.remove(at: from)
        orderedDockItems.insert(bID, at: to > from ? to - 1 : to)
    }
    
    // 排序，只影响顺序。
    func saveTempItems() {
        dockObserver.dockAppOrderKeys = orderedDockItems.map {$0.bundleID }
        dockObserver.refreshDock()
        updateOrderedDockItems()
    }
    
    private func updateOrderedDockItems() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
            orderedDockItems = dockObserver.dockAppOrderKeys.compactMap { dockObserver.dockApps[$0] }
        }
    }
    
    private func toggleEditingMode() {
        if !dockEditorSettings.isEditing {
            dockEditorSettings.isEditing.toggle()
        } else {
            updateOrderedDockItems()
            dockObserver.saveDockItems()
            dockObserver.refreshDock()
            dockEditorSettings.isEditing.toggle()
        }
    }
    
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
                        DispatchQueue.main.async {// 重复逻辑日后封装
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
    
    // 按钮：手动选 .app 文件
    private func addNewApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        if panel.runModal() == .OK, let url = panel.url {
            if let newItem = createNewAppItem(from: url) {
                // 新增到字典 + 顺序数组
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
