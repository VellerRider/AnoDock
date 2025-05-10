//
//  DockDataManager.swift
//  AnoDock
//
//  persist user data to local
//
//  Created by John Yang on 12/19/24.
//

import Foundation
import Cocoa
class DockDataManager {
    static let shared = DockDataManager()
    private let fileURL: URL
    
    init() {
        // create app support dir if it doesn't exist
        let fileManager = FileManager.default
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportDirectory.appendingPathComponent("AnoDock")
        if !fileManager.fileExists(atPath: appDirectory.path) {
            try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        }
        
        fileURL = appDirectory.appendingPathComponent("dockItems.json")
        print("File path: \(fileURL.path)")

    }
    
    func saveDockItems(_ items: [DockItem]) {
        
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL)
        } catch {
            print("Error saving Dock items: \(error)")
        }
    }
    func loadDockItems() -> [DockItem] {
        let fm = FileManager.default
        // if no file, make new one with finder init
        if !fm.fileExists(atPath: fileURL.path) {
            let defaults = makeDefaultItems()
            saveDockItems(defaults)
            return defaults
        }
        // if user got their items saved, use theirs
        guard let data = try? Data(contentsOf: fileURL),
              let items = try? JSONDecoder().decode([DockItem].self, from: data)
        else {
            return []
        }
        return items
    }
    // make finder default for new user
    private func makeDefaultItems() -> [DockItem] {
        var array: [DockItem] = []
        let finderID = "com.apple.finder"
        if let finderURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: finderID),
           let finderItem = makeItem(from: finderURL) {
            array.append(finderItem)
        }
        return array
    }
    private func makeItem(from url: URL) -> DockItem? {
        guard url.pathExtension == "app" else { return nil }
        let bundleID = Bundle(url: url)?.bundleIdentifier ?? ""
        return DockItem(
            id: UUID(),
            name: url.deletingPathExtension().lastPathComponent,
            url: url,
            bundleID: bundleID,
            isRunning: false
        )
    }
    

}
