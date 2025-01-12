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
    
    /// 改为使用 dockAppOrderKeys (String 数组) 来保持顺序。
    /// 通过索引 + key 查到具体的 dockApps[key]
    let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 16)
    ]
    
    var body: some View {
        VStack {
            // 用 ScrollView + LazyVGrid 来展示
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    // 根据 dockAppOrderKeys 保证顺序
                    ForEach(Array(dockObserver.dockAppOrderKeys.enumerated()), id: \.element) { (index, key) in
                        // 从字典里取出 DockItem
                        if let item = dockObserver.dockApps[key] {
                            DockItemView(item: item)
                                .onTapGesture {
                                    openDockItem(item)
                                }
                                // 使其可以被拖拽
                                .onDrag {
                                    // 拖拽时传递 "oldIndex" 过去，以便 onDrop 时获取
                                    let provider = NSItemProvider(object: "\(index)" as NSString)
                                    return provider
                                }
                                // 接收拖拽
                                .onDrop(of: [.text], isTargeted: nil) { providers in
                                    handleDropReorder(providers: providers, toIndex: index)
                                }
                        }
                    }
                }
                .padding()
            }
            
            // 只有一个按钮：Add App (已去掉 Folder 相关逻辑)
            HStack {
                Button(action: addNewApp) {
                    Image(systemName: "plus")
                        .font(.title)
                }
            }
        }

        // 如果需要从外部拖入 .app 文件，可以在整个 VStack/ScrollView 上扩展 .onDrop
        // 如果你想支持把文件拖到空白处就添加，也可以：
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            handleDrop(providers: providers)
        }
    }
}

// MARK: - Functions
extension CustomDockView {
    
    // 拖拽重排逻辑
    private func handleDropReorder(providers: [NSItemProvider], toIndex: Int) -> Bool {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
                guard let str = item as? String,
                      let oldIndex = Int(str),
                      oldIndex != toIndex
                else { return }
                
                DispatchQueue.main.async {
                    withAnimation {
                        // 在 dockAppOrderKeys 里重排
                        let movingKey = dockObserver.dockAppOrderKeys.remove(at: oldIndex)
                        dockObserver.dockAppOrderKeys.insert(movingKey, at: toIndex)
                        dockObserver.saveDockItems()
                    }
                }
            }
        }
        return true
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
                        DispatchQueue.main.async {
                            // 加入字典
                            dockObserver.dockApps[newItem.bundleID] = newItem
                            // 加到顺序数组末尾（或想加到别的地方可以自己改逻辑）
                            dockObserver.dockAppOrderKeys.append(newItem.bundleID)
                            dockObserver.saveDockItems()
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
                dockObserver.dockApps[newItem.bundleID] = newItem
                dockObserver.dockAppOrderKeys.append(newItem.bundleID)
                dockObserver.saveDockItems()
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
    
    // 打开某个 DockItem（这里不再区分 folder/app）
    private func openDockItem(_ item: DockItem) {
        // 简单打开对应 URL（如果是 app，会直接启动；如果是别的文件夹，也会在 Finder 打开）
        NSWorkspace.shared.open(item.url)
    }
}
