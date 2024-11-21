//
//  File.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import SwiftUI

struct DockItemView: View {
    let item: DockItem
    @EnvironmentObject var appStateMonitor: AppStateMonitor
    
    var body: some View {
        VStack {
            if let icon = loadIconFromFile(iconName: item.iconName) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .cornerRadius(8)
                    .overlay(
                        isRunning ? Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                            .offset(x: 25, y: 25) : nil,
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
        .contextMenu {
            if item.type == .application || item.type == .recentApplication {
                Button("打开") {
                    launchOrActivateApplication(item: item)
                }
                if isRunning {
                    Button("退出") {
                        quitApplication(item: item)
                    }
                    Button("隐藏") {
                        hideApplication(item: item)
                    }
                }
                Button("显示在 Finder 中") {
                    NSWorkspace.shared.activateFileViewerSelecting([item.url])
                }
            } else if item.type == .folder {
                Button("打开") {
                    NSWorkspace.shared.open(item.url)
                }
                Button("显示在 Finder 中") {
                    NSWorkspace.shared.activateFileViewerSelecting([item.url])
                }
            }
            // 其他菜单项...
        }
    }
    
    private func loadIconFromFile(iconName: String?) -> NSImage? {
        guard let iconName = iconName else {
            return nil
        }
        
        let fileManager = FileManager.default
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportDirectory.appendingPathComponent("YourAppName") // 替换为您的应用程序名称
        let iconURL = appDirectory.appendingPathComponent(iconName)
        
        return NSImage(contentsOf: iconURL)
    }
    
    private var isRunning: Bool {
        guard let bundleIdentifier = item.bundleIdentifier else {
            return false
        }
        return appStateMonitor.runningApplications.contains(bundleIdentifier)
    }
    
    private func launchOrActivateApplication(item: DockItem) {
        if let bundleIdentifier = item.bundleIdentifier {
            if let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
                runningApp.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            } else {
                NSWorkspace.shared.openApplication(at: item.url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            }
        }
    }
    
    private func quitApplication(item: DockItem) {
        if let bundleIdentifier = item.bundleIdentifier,
           let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
            runningApp.terminate()
        }
    }
    
    private func hideApplication(item: DockItem) {
        if let bundleIdentifier = item.bundleIdentifier,
           let runningApp = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first {
            runningApp.hide()
        }
    }
}
