//
//  CustomDockView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct CustomDockView: View {
    @State private var dockItems: [DockItem] = DockDataManager.shared.loadDockItems()
    @StateObject private var appStateMonitor = AppStateMonitor()
    
    var body: some View {
        VStack {
            HStack {
                ForEach(dockItems) { item in
                    DockItemView(item: item)
                        .environmentObject(appStateMonitor)
                        .onTapGesture {
                            openDockItem(item)
                        }
                }
            }
            .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
                handleDrop(providers: providers)
            }
            
            HStack {
                // Add App Button
                Button(action: addNewApp) {
                    Image(systemName: "plus")
                        .font(.title)
                }
                
                // Create Folder Button
                Button(action: createNewFolder) {
                    Image(systemName: "folder.badge.plus")
                        .font(.title)
                }
            }
        }
        .onAppear {
            updateRunningStates()
        }
    }
    
    // drag and drop apps to this view to modify custom dock
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    guard let data = item as? Data,
                          let url = URL(dataRepresentation: data, relativeTo: nil),
                          url.pathExtension == "app" else { return }

                    let newItem = DockItem(
                        id: UUID(),
                        name: url.deletingPathExtension().lastPathComponent,
                        iconName: saveIconToFile(icon: NSWorkspace.shared.icon(forFile: url.path), name: url.lastPathComponent),
                        url: url,
                        isRunning: false,
                        type: .app(bundleIdentifier: Bundle(path: url.path)?.bundleIdentifier)
                    )
                    
                    DispatchQueue.main.async {
                        dockItems.append(newItem)
                        DockDataManager.shared.saveDockItems(dockItems)
                    }
                }
            }
        }
        return true
    }
    
    // add apps to custom dock using button
    private func addNewApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType.application]
        if panel.runModal() == .OK, let url = panel.url {
            if let newItem = createDockItem(from: url) {
                dockItems.append(newItem)
                DockDataManager.shared.saveDockItems(dockItems)
            }
        }
    }
    
    // helper function to create a dock item
    private func createDockItem(from url: URL) -> DockItem? {
        guard url.pathExtension == "app" else { return nil }
        return DockItem(
            id: UUID(),
            name: url.deletingPathExtension().lastPathComponent,
            iconName: saveIconToFile(icon: NSWorkspace.shared.icon(forFile: url.path), name: url.lastPathComponent),
            url: url,
            isRunning: false,
            type: .app(bundleIdentifier: Bundle(path: url.path)?.bundleIdentifier)
        )
    }
    
    // create a new folder to custom dock using button
    private func createNewFolder() {
        let newFolder = DockItem(
            id: UUID(),
            name: "New Folder",
            iconName: "folderIcon.png",
            url: URL(fileURLWithPath: "/"), // Placeholder folder path
            isRunning: false,
            type: .folder(items: [])
        )
        
        print("New Folder Created: \(newFolder.name)")
        dockItems.append(newFolder)
        DockDataManager.shared.saveDockItems(dockItems)
    }
    
//    // add folders to dock using drag and drop
//    private func addFolder(from url: URL) {
//        let newFolder = DockItem(
//            id: UUID(),
//            name: url.lastPathComponent,
//            iconName: "folderIcon.png", // Replace with logic to save the actual folder icon
//            url: url,
//            isRunning: false,
//            type: .folder(items: [])
//        )
//        
//        // Add the folder to your data
//        // This is where you might save the folder contents
//        DispatchQueue.main.async {
//            // Add folder handling logic here
//            print("Folder Added: \(newFolder.name)")
//        }
//    }
        
    // open app in dock editor, not necessary
    private func openDockItem(_ item: DockItem) {
        switch item.type {
        case .app:
            NSWorkspace.shared.open(item.url)
        // placeholder
        case .folder(let items):
            print("Folder contains \(items.count) items")
        }
    }
    
    private func updateRunningStates() {
        for index in dockItems.indices {
            switch dockItems[index].type {
            case .app(let bundleIdentifier):
                if let bundleIdentifier = bundleIdentifier {
                    dockItems[index].isRunning = !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
                }
            case .folder:
                // No action needed for folders
                continue
            }
        }
    }
}
