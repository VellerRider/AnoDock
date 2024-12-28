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
    @EnvironmentObject var appStateMonitor: AppStateMonitor
    
    var interactive: Bool = true // 默认为可交互模式
    
    var body: some View {
        VStack {
            // Try to load the icon
            if let icon = loadIconFromFile(iconName: item.iconName) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)
                    .overlay(
                        isRunning ? Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .offset(x: 25, y: 25)
                            : nil,
                        alignment: .bottomTrailing
                    )
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)
            }
            
            Text(item.name)
                .font(.caption)
                .frame(width: 70)
                .lineLimit(1)
        }
        .padding(4)
        .contextMenu(menuItems: {
            if interactive {
                contextMenuItems(item: item)
            }
        })
    }
    
    // MARK: - right click menu for the item
    @ViewBuilder
    private func contextMenuItems(item: DockItem) -> some View {
        switch item.type {
        case let .app(bundleIdentifier):
            Button("打开") {
                launchOrActivateApplication(bundleIdentifier: bundleIdentifier, url: item.url)
            }
            if isRunning {
                Button("退出") {
                    quitApplication(bundleIdentifier: bundleIdentifier)
                }
                Button("隐藏") {
                    hideApplication(bundleIdentifier: bundleIdentifier)
                }
            }
            Button("显示在 Finder 中") {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }
            
        case let .folder(items):
            // TODO: - modal pop up and show apps inside, allow user to click and open.
            Button("编辑文件夹") {
                
            }
            Button("重命名") {
                
            }
            Button("删除文件夹") {
                
            }
        }
    }
    
    // MARK: - isRunning Computed Property
    private var isRunning: Bool {
        // We only have a running state for apps
        switch item.type {
        case let .app(bundleIdentifier):
            // If there's a bundle ID, see if it's running
            guard let bundleIdentifier = bundleIdentifier else { return false }
            return appStateMonitor.runningApplications.contains(bundleIdentifier)
        case .folder:
            // Folders are never "running"
            return false
        }
    }
    
    // MARK: - Icon Loading
    private func loadIconFromFile(iconName: String?) -> NSImage? {
        guard let iconName = iconName else {
            return nil
        }
        
        let fileManager = FileManager.default
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        // Replace "YourAppName" with your actual directory name
        let appDirectory = appSupportDirectory.appendingPathComponent("YourAppName")
        let iconURL = appDirectory.appendingPathComponent(iconName)
        
        return NSImage(contentsOf: iconURL)
    }
    
    // MARK: - Launch or Activate App
    private func launchOrActivateApplication(bundleIdentifier: String?, url: URL) {
        guard let bundleIdentifier = bundleIdentifier else { return }
        
        if let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
            runningApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        } else {
            NSWorkspace.shared.openApplication(at: url,
                                               configuration: NSWorkspace.OpenConfiguration(),
                                               completionHandler: nil)
        }
    }
    
    // MARK: - Quit Application
    private func quitApplication(bundleIdentifier: String?) {
        guard let bundleIdentifier = bundleIdentifier,
              let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first else {
            return
        }
        runningApp.terminate()
    }
    
    // MARK: - Hide Application
    private func hideApplication(bundleIdentifier: String?) {
        guard let bundleIdentifier = bundleIdentifier,
              let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first else {
            return
        }
        runningApp.hide()
    }
}
