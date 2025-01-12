//
//  DockDataManager.swift
//  KuchiyoseDock
//
//  persist user data to local
//
//  Created by John Yang on 12/19/24.
//

import Foundation

class DockDataManager {
    static let shared = DockDataManager()
    private let fileURL: URL
    
    init() {
        let fileManager = FileManager.default
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportDirectory.appendingPathComponent("KuchiyoseDock")
        
        // 创建应用支持目录（如果不存在）
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
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try JSONDecoder().decode([DockItem].self, from: data)
            return items
        } catch {
            print("Error loading Dock items: \(error)")
            return []
        }
    }
}
