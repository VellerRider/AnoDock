//////
//////  DockAccessibilityUtil.swift
//////  KuchiyoseDock
//////
//////  Created by John Yang on 11/20/24.
//////
////
//import Cocoa
//
//class DockAccessibilityUtil {
//    static func getDockItems() -> [DockItem] {
//        var dockItems: [DockItem] = []
//        
//        guard let dockApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first else {
//            print("无法找到 Dock 应用程序")
//            return dockItems
//        }
//        
//        let dockAXElement = AXUIElementCreateApplication(dockApp.processIdentifier)
//        
////        var dockChildren: CFArray?
////        let result = AXUIElementCopyAttributeValue(dockAXElement, kAXChildrenAttribute as CFString, &dockChildren)
//        var dockChildren: CFTypeRef?
//        let result = AXUIElementCopyAttributeValue(dockAXElement, kAXChildrenAttribute as CFString, &dockChildren)
//        if result != AXError.success {
//            print("无法获取 Dock 的子元素")
//            return dockItems
//        }
//        
//        guard let dockItemsArray = dockChildren as? [AXUIElement] else {
//            print("无法转换 Dock 子元素为 AXUIElement 数组")
//            return dockItems
//        }
//        
//        for element in dockItemsArray {
//            var role: CFTypeRef?
//            var subrole: CFTypeRef?
//            
//            AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
//            AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subrole)
//            
//            let roleString = role as? String ?? ""
//            let subroleString = subrole as? String ?? ""
//            
//            if roleString == kAXButtonRole as String && subroleString == "AXApplicationDockItem" {
//                if let dockItem = createDockItem(from: element, type: .application) {
//                    dockItems.append(dockItem)
//                }
//            } else if roleString == kAXGroupRole as String && subroleString == "AXFolderDockItem" {
//                if let dockItem = createDockItem(from: element, type: .folder) {
//                    dockItems.append(dockItem)
//                }
//            }
//            // 可以在此处添加对其他类型的处理
//        }
//        
//        return dockItems
//    }
//    
//    private static func createDockItem(from element: AXUIElement, type: DockItemType) -> DockItem? {
//        // 获取名称
//        var title: CFTypeRef?
//        let titleResult = AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title)
//        guard titleResult == .success, let itemName = title as? String else {
//            return nil
//        }
//        
//        // 获取 URL
//        var urlRef: CFTypeRef?
//        let urlResult = AXUIElementCopyAttributeValue(element, kAXURLAttribute as CFString, &urlRef)
//        guard urlResult == .success, let url = urlRef as? NSURL else {
//            return nil
//        }
//        
//        // 获取图标并保存到本地
//        let icon = NSWorkspace.shared.icon(forFile: url.path!)
//        icon.size = NSSize(width: 64, height: 64)
//        let iconName = saveIconToFile(icon: icon, name: itemName)
//        
//        // 获取 Bundle Identifier（仅对应用程序有效）
//        var bundleIdentifier: String? = nil
//        if type == .application {
//            let bundle = Bundle(url: url as URL)
//            bundleIdentifier = bundle?.bundleIdentifier
//        }
//        
//        return DockItem(
//            id: UUID(),
//            name: itemName,
//            bundleIdentifier: bundleIdentifier,
//            iconName: iconName,
//            url: url as URL,
//            isRunning: false,
//            type: type
//        )
//    }
//    
//    private static func saveIconToFile(icon: NSImage, name: String) -> String {
//        let fileManager = FileManager.default
//        let iconName = "\(name).png"
//        if let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
//            let appDirectory = appSupportDirectory.appendingPathComponent("YourAppName") // 替换为您的应用程序名称
//            // 创建目录（如果不存在）
//            try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
//            let iconURL = appDirectory.appendingPathComponent(iconName)
//            if let iconData = icon.tiffRepresentation,
//               let bitmap = NSBitmapImageRep(data: iconData),
//               let pngData = bitmap.representation(using: .png, properties: [:]) {
//                try? pngData.write(to: iconURL)
//            }
//        }
//        return iconName
//    }
//}
