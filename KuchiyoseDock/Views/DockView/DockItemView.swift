//
//  File.swift
//  KuchiyoseDock
//  Displaying the icons and support functions like macOS dock.
//  Created by John Yang on 11/17/24.
//

// View for single item in the dock UI
import SwiftUI

struct DockItemView: View {
    let item: DockItem
    var interactive: Bool = true
    
    @State private var isHovering = false // 悬停状态

    var body: some View {
            ZStack {
                // 1. 显示主图标
                loadIcon()

                // 2. 显示指示灯（类似 macOS Dock 的小灰点）
                if isRunning {
                    Circle()
                        .fill(Color.gray) // 灰色小点
                        .frame(width: 4, height: 4)
                        .offset(y: 34) // 调整位置，使其显示在图标下方
                }
                if isHovering {
                    Text(item.name)
                        .font(.system(size: 12)) // 更大的字体
                        .padding(4)
                        .background(Color.black.opacity(0.3)) // 背景黑色，带透明度
                        .foregroundColor(.black.opacity(0.8))
                        .cornerRadius(4)
                        .offset(y: -50) // 显示在图标上方
                        .transition(.opacity) // 淡入淡出效果
                        .animation(.easeInOut(duration: 0.2), value: isHovering) // 动画效果

                }
            }
        
            .padding(4)
            // 左键点击打开项目
            .onTapGesture { openItem(item) }
            // 右键菜单
            .contextMenu(menuItems: {
                if interactive {
                    contextMenuItems(item: item)
                }
            })
            .onHover { hovering in
                isHovering = hovering // 监听鼠标悬停事件
            }
        }
    
    // MARK: - Icon Logic
    @ViewBuilder
    private func loadIcon() -> some View {
        switch item.type {
        case .app:
            if let nsImage = loadIconFromFile(iconName: item.iconName) {
                Image(nsImage: nsImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)

            } else {
                // Gray fallback if no icon
                Image(systemName: "app.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)
            }
            
        case let .folder(folderItems):
            folderThumbnail(folderItems)
                .frame(width: 64, height: 64)
                .cornerRadius(8)
        }
    }
    
    /// If folder has items, show a 3x3 mosaic; otherwise a semi-translucent box
    @ViewBuilder
    private func folderThumbnail(_ folderItems: [DockItem]) -> some View {
        if folderItems.isEmpty {
            // (FIX) Show translucent box + folder glyph
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))   // semi-transparent
                Image(systemName: "folder")
                    .foregroundColor(.gray.opacity(0.7))
                    .font(.system(size: 22))
            }
        } else {
            // up to 9 sub-items mosaic
            GeometryReader { geo in
                let cellSize = geo.size.width / 3
                let slice = folderItems.prefix(9)
                ZStack {
                    ForEach(slice.indices, id: \.self) { i in
                        let row = i / 3
                        let col = i % 3
                        if let subIcon = loadIconFromFile(iconName: slice[i].iconName) {
                            Image(nsImage: subIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: cellSize, height: cellSize)
                                .offset(
                                    x: CGFloat(col)*cellSize - geo.size.width/2 + cellSize/2,
                                    y: CGFloat(row)*cellSize - geo.size.height/2 + cellSize/2
                                )
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: cellSize, height: cellSize)
                                .offset(
                                    x: CGFloat(col)*cellSize - geo.size.width/2 + cellSize/2,
                                    y: CGFloat(row)*cellSize - geo.size.height/2 + cellSize/2
                                )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - isRunning
    private var isRunning: Bool {
        switch item.type {
        case .app:
            return item.isRunning
        case .folder:
            return false
        }
    }

    // MARK: - Left-click
    private func openItem(_ dockItem: DockItem) {
        switch dockItem.type {
        case let .app(bundleID):
            launchOrActivateApplication(bundleIdentifier: bundleID, url: dockItem.url)
        case let .folder(subItems):
            print("Folder with \(subItems.count) items. Not implemented.")
        }
    }
    
    // MARK: - Right-click menu
    @ViewBuilder
    private func contextMenuItems(item: DockItem) -> some View {
        switch item.type {
        case let .app(bundleID):
            Button("打开") {
                launchOrActivateApplication(bundleIdentifier: bundleID, url: item.url)
            }
            if isRunning {
                Button("退出") {
                    quitApplication(bundleIdentifier: bundleID)
                }
                Button("隐藏") {
                    hideApplication(bundleIdentifier: bundleID)
                }
            }
            Button("显示在 Finder 中") {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
            
        case .folder:
            Button("编辑文件夹") { }
            Button("重命名") { }
            Button("删除文件夹") { }
        }
    }

    // MARK: - Load icon from disk
    private func loadIconFromFile(iconName: String?) -> NSImage? {
        guard let iconName = iconName else { return nil }
        let fm = FileManager.default
        let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let iconsDir = supportDir.appendingPathComponent("KuchiyoseDock/Icons")
        let iconURL = iconsDir.appendingPathComponent(iconName)
        return NSImage(contentsOf: iconURL)
    }
    
    // MARK: - Launch/Activate
    private func launchOrActivateApplication(bundleIdentifier: String?, url: URL) {
        guard let bundleIdentifier = bundleIdentifier else { return }
        if let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
            runningApp.activate(options: [.activateAllWindows])
        } else {
            NSWorkspace.shared.openApplication(at: url, configuration: .init(), completionHandler: nil)
        }
    }
    
    private func quitApplication(bundleIdentifier: String?) {
        guard let bundleIdentifier = bundleIdentifier,
              let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
        else { return }
        runningApp.terminate()
    }
    
    private func hideApplication(bundleIdentifier: String?) {
        guard let bundleIdentifier = bundleIdentifier,
              let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first
        else { return }
        runningApp.hide()
    }
}
