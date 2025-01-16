////
////  EditorItemView.swift
////  KuchiyoseDock
////
////  Created by John Yang on 1/12/25.
////
//
//import Foundation
//import SwiftUI
//
//struct EditorItemView: View {
//    @EnvironmentObject var dockObserver: DockObserver
//    @EnvironmentObject var dockEditorSettings: DockEditorSettings
//    @ObservedObject var item: DockItem
//    @State var deleted: Bool = false
//    var body: some View {
//            ZStack {
//                // 1. 显示主图标
//                
//                loadIcon()
//                if dockEditorSettings.isEditing {
//                    // 删除按钮
//                    Button(action: {
//                        deleteSelf()
//                    }) {
//                        Image(systemName: "minus.circle.fill")
//                    }
//                    .position(x: 10, y: 10)
//                    .transition(.scale)
//                }
//                
//                // 2. 显示指示灯（类似 macOS Dock 的小灰点）
//                if item.isRunning {
//                    Circle()
//                        .fill(Color.gray) // 灰色小点
//                        .frame(width: 4, height: 4)
//                        .offset(y: 34) // 调整位置，使其显示在图标下方
//                }
//            }
//            .opacity(deleted ? 0.3 : 1) // 调整透明度
//            .blur(radius: deleted ? 5 : 0) // 模糊效果
//            .animation(.easeInOut, value: deleted)
//            
//            .help(item.name)
//
//
//        
//
//        }
//    
//    // MARK: - Icon Logic. Just for apps
//    @ViewBuilder
//    private func loadIcon() -> some View {
//        if let nsImage = loadIconFromFile(iconName: item.iconName) {
//            Image(nsImage: nsImage)
//                .resizable()
//                .frame(width: 64, height: 64)
//                .cornerRadius(8)
//
//        } else {
//            // Gray fallback if no icon
//            Image(systemName: "app.fill")
//                .resizable()
//                .foregroundColor(.gray)
//                .frame(width: 64, height: 64)
//                .cornerRadius(8)
//        }
//        
//    }
//    
//    // If folder has items, show a 3x3 mosaic; otherwise a semi-translucent box
//    @ViewBuilder
//    private func folderThumbnail(_ folderItems: [DockItem]) -> some View {
//        if folderItems.isEmpty {
//            // (FIX) Show translucent box + folder glyph
//            ZStack {
//                Rectangle()
//                    .fill(Color.gray.opacity(0.2))   // semi-transparent
//                Image(systemName: "folder")
//                    .foregroundColor(.gray.opacity(0.7))
//                    .font(.system(size: 22))
//            }
//        } else {
//            // up to 9 sub-items mosaic
//            GeometryReader { geo in
//                let cellSize = geo.size.width / 3
//                let slice = folderItems.prefix(9)
//                ZStack {
//                    ForEach(slice.indices, id: \.self) { i in
//                        let row = i / 3
//                        let col = i % 3
//                        if let subIcon = loadIconFromFile(iconName: slice[i].iconName) {
//                            Image(nsImage: subIcon)
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: cellSize, height: cellSize)
//                                .offset(
//                                    x: CGFloat(col)*cellSize - geo.size.width/2 + cellSize/2,
//                                    y: CGFloat(row)*cellSize - geo.size.height/2 + cellSize/2
//                                )
//                        } else {
//                            Rectangle()
//                                .fill(Color.gray.opacity(0.3))
//                                .frame(width: cellSize, height: cellSize)
//                                .offset(
//                                    x: CGFloat(col)*cellSize - geo.size.width/2 + cellSize/2,
//                                    y: CGFloat(row)*cellSize - geo.size.height/2 + cellSize/2
//                                )
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//
//    // MARK: - Load icon from disk
//    private func loadIconFromFile(iconName: String?) -> NSImage? {
//        guard let iconName = iconName else { return nil }
//        let fm = FileManager.default
//        let supportDir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
//        let iconsDir = supportDir.appendingPathComponent("KuchiyoseDock/Icons")
//        let iconURL = iconsDir.appendingPathComponent(iconName)
//        return NSImage(contentsOf: iconURL)
//    }
//    
//    // MARK: - delete item
//    private func deleteSelf() {
//        dockObserver.removeItem(item.bundleID)
//        deleted.toggle()
//    }
//}
