//
//  DockItem.swift
//  KuchiyoseDock
//
//  Model for each item or folder
//
//  Created by John Yang on 11/17/24.
//


// Now only support app. TODO: Implement folder model later

import Foundation
import AppKit



class DockItem: Identifiable, Codable, Hashable, ObservableObject {
    let id: UUID
    let name: String
    let iconName: String // save icon
    let url: URL
    let bundleID: String
    @Published var isRunning: Bool // for apps only
    
    
    // make this codable
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case iconName
        case url
        case bundleID
        case isRunning
    }
    
    required init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        url = try c.decode(URL.self, forKey: .url)
        iconName = try c.decode(String.self, forKey: .iconName)
        bundleID = try c.decode(String.self, forKey: .bundleID)
        isRunning = try c.decode(Bool.self, forKey: .isRunning)
    }
    
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(url, forKey: .url)
        try c.encode(iconName, forKey: .iconName)
        try c.encode(bundleID, forKey: .bundleID)
        try c.encode(isRunning, forKey: .isRunning)
    }
    
    init(id: UUID, name: String, iconName: String, url: URL, bundleID: String, isRunning: Bool) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.url = url
        self.bundleID = bundleID
        self.isRunning = isRunning
    }
    
    // make this hashable
    static func == (lhs: DockItem, rhs: DockItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // 只用 id
    }
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
    guard let bundleIdentifier = app.bundleIdentifier else {
        print("Error: bundleIdentifier is nil for app \(appName)")
        return nil
    }
    // 获取图标并保存到本地
    let icon = NSWorkspace.shared.icon(forFile: url.path)
    icon.size = NSSize(width: 64, height: 64)
    let iconName = saveIconToFile(icon: icon, name: appName)

    return DockItem(
        id: UUID(),
        name: appName,
        iconName: iconName,
        url: url,
        bundleID: bundleIdentifier,
        isRunning: false
    )
}
