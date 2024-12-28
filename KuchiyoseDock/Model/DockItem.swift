//
//  DockItem.swift
//  KuchiyoseDock
//
//  Model for each item or folder
//
//  Created by John Yang on 11/17/24.
//

import Foundation
import AppKit


enum DockItemType: Codable {
    case app(bundleIdentifier: String?)
    case folder(items: [DockItem])
}


struct DockItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let iconName: String // save icon
    let url: URL
    var isRunning: Bool // for apps only
    let type: DockItemType
}



// Function to save the icon to a file and return the filename
func saveIconToFile(icon: NSImage, name: String) -> String {
    let fileManager = FileManager.default
    let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let iconsURL = appSupportURL.appendingPathComponent("KuchiyoseDock/Icons", isDirectory: true)

    do {
        try fileManager.createDirectory(at: iconsURL, withIntermediateDirectories: true)
    } catch {
        print("Error creating icons directory: \(error)")
        return "" // Return empty string on error
    }

    let iconName = "\(name.replacingOccurrences(of: " ", with: "_")).png" // Create a valid filename
    let fileURL = iconsURL.appendingPathComponent(iconName)

    guard let imageData = icon.tiffRepresentation,
          let imageRep = NSBitmapImageRep(data: imageData),
          let pngData = imageRep.representation(using: .png, properties: [:]) else {
        print("Error converting icon to PNG data")
        return ""
    }

    do {
        try pngData.write(to: fileURL)
        return iconName
    } catch {
        print("Error saving icon to file: \(error)")
        return ""
    }
}

func createDockItem(from app: NSRunningApplication) -> DockItem? {
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
        iconName: iconName,
        url: url,
        isRunning: false,
        type: .app(bundleIdentifier: bundleIdentifier)
    )
}

func createDockItemFolder(name: String, url: URL, items: [DockItem]) -> DockItem? {
    // Save folder icon
    let icon = NSWorkspace.shared.icon(forFile: url.path)
    icon.size = NSSize(width: 64, height: 64)
    let iconName = saveIconToFile(icon: icon, name: name)

    return DockItem(
        id: UUID(), // Generate a unique ID
        name: name,
        iconName: iconName,
        url: url,
        isRunning: false,
        type: .folder(items: items)
    )
}
