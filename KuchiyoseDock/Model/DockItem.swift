//
//  DockItem.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import Foundation
import AppKit

enum DockItemType: String, Codable {
    case application
    case folder
    case recentApplication // 新增
}
struct DockItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let bundleIdentifier: String?
    let iconName: String // 保存图标文件名
    let url: URL
    var isRunning: Bool // 修改为可变的，以便更新运行状态
    let type: DockItemType
}
func createDockItem(from app: NSRunningApplication, type: DockItemType) -> DockItem? {
    guard let url = app.bundleURL else { return nil }
    let appName = app.localizedName ?? url.deletingPathExtension().lastPathComponent
    let bundleIdentifier = app.bundleIdentifier

    // 获取图标并保存到本地
    let icon = NSWorkspace.shared.icon(forFile: url.path)
    icon.size = NSSize(width: 64, height: 64)
    let iconName = saveIconToFile(icon: icon, name: appName)

    return DockItem(
        id: UUID(),
        name: appName,
        bundleIdentifier: bundleIdentifier,
        iconName: iconName,
        url: url,
        isRunning: true,
        type: type
    )
}
