//
//  CustomDockView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct CustomDockView: View {
    @EnvironmentObject var dockObserver: DockObserver
    
    let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 16)
    ]
    
    var body: some View {
        VStack {
            // (FIX) Use a grid, so items wrap as the window shrinks
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(dockObserver.dockItems.indices, id: \.self) { index in
                        let item = dockObserver.dockItems[index]
                        DockItemView(item: item)
                            .onTapGesture {
                                openDockItem(item)
                            }
                            // (FIX) Draggable
                            .onDrag {
                                // Provide the item’s index or ID
                                let provider = NSItemProvider(object: "\(index)" as NSString)
                                return provider
                            }
                            .onDrop(of: [.text], isTargeted: nil) { providers in
                                handleDropReorder(providers: providers, fromIndex: index)
                            }
                    }
                }
                .padding()
            }
            
            HStack {
                // Add App
                Button(action: addNewApp) {
                    Image(systemName: "plus")
                        .font(.title)
                }
                
                // Create Folder
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
    
    // (FIX) Reorder logic for drag & drop among items
    private func handleDropReorder(providers: [NSItemProvider], fromIndex: Int) -> Bool {
        // We'll see if there's a text, presumably the old index
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
                guard let str = item as? String,
                      let oldIndex = Int(str),
                      oldIndex != fromIndex
                else { return }
                
                DispatchQueue.main.async {
                    withAnimation {
                        // Perform reorder
                        let movingItem = dockObserver.dockItems.remove(at: oldIndex)
                        dockObserver.dockItems.insert(movingItem, at: fromIndex)
                        dockObserver.saveDockItems()
                    }
                }
            }
        }
        return true
    }
    
    // (FIX) Use the same old logic for dropping .app files
    // but now we also do reordering
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    guard
                        let data = item as? Data,
                        let url = URL(dataRepresentation: data, relativeTo: nil),
                        url.pathExtension == "app"
                    else { return }
                    
                    let newItem = DockItem(
                        id: UUID(),
                        name: url.deletingPathExtension().lastPathComponent,
                        iconName: saveIconToFile(icon: NSWorkspace.shared.icon(forFile: url.path), name: url.lastPathComponent),
                        url: url,
                        isRunning: false,
                        type: .app(bundleIdentifier: Bundle(path: url.path)?.bundleIdentifier)
                    )
                    
                    DispatchQueue.main.async {
                        dockObserver.dockItems.append(newItem)
                        dockObserver.saveDockItems()
                    }
                }
            }
        }
        return true
    }
    
    private func addNewApp() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.application]
        if panel.runModal() == .OK, let url = panel.url {
            if let newItem = createNewAppItem(from: url) {
                dockObserver.dockItems.append(newItem)
                dockObserver.saveDockItems()
            }
        }
    }
    
    private func createNewAppItem(from url: URL) -> DockItem? {
        guard url.pathExtension == "app" else { return nil }
        return DockItem(
            id: UUID(),
            name: url.deletingPathExtension().lastPathComponent,
            iconName: saveIconToFile(icon: NSWorkspace.shared.icon(forFile: url.path),
                                     name: url.lastPathComponent),
            url: url,
            isRunning: false,
            type: .app(bundleIdentifier: Bundle(path: url.path)?.bundleIdentifier)
        )
    }
    
    private func createNewFolder() {
        let newFolder = DockItem(
            id: UUID(),
            name: "New Folder",
            iconName: "folderIcon.png",
            url: URL(fileURLWithPath: "/"),
            isRunning: false,
            type: .folder(items: [])
        )
        dockObserver.dockItems.append(newFolder)
        dockObserver.saveDockItems()
    }
    
    private func openDockItem(_ item: DockItem) {
        switch item.type {
        case .app:
            NSWorkspace.shared.open(item.url)
        case let .folder(items):
            print("Folder contains \(items.count) items")
        }
    }
    
    private func updateRunningStates() {
        for index in dockObserver.dockItems.indices {
            switch dockObserver.dockItems[index].type {
            case .app(let bundleIdentifier):
                if let bundleIdentifier = bundleIdentifier {
                    dockObserver.dockItems[index].isRunning =
                        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
                }
            case .folder:
                continue
            }
        }
    }
}
