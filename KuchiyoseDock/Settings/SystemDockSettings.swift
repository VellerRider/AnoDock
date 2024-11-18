//
//  DockSettings.swift
//  KuchiyoseDock
//
//  Store user's dock setting in their macOS system setting.
//
//  Created by John Yang on 11/17/24.
//

import Foundation

enum DockPosition: String, Codable {
    case left
    case right
    case bottom

    // 从字符串解析 DockPosition，如果无法识别返回默认值（bottom）
    static func fromSystemValue(_ value: String) -> DockPosition {
        switch value {
        case "left": return .left
        case "right": return .right
        default: return .bottom
        }
    }
}

class SystemDockSettings : ObservableObject {
    @Published var autohide: Bool = false
    @Published var size: CGFloat = 0.0
    @Published var magnification: CGFloat = 0.0
    @Published var position: DockPosition = .bottom

    init() {
        loadSystemDockSettings()
    }

    /// 从系统获取 Dock 设置
    func loadSystemDockSettings() {
        let dockDefaults = UserDefaults(suiteName: "com.apple.dock")

        // 自动隐藏
        if let autohideValue = dockDefaults?.bool(forKey: "autohide") {
            autohide = autohideValue
        }

        // 大小（范围通常是 0.0 到 1.0）
        if let sizeValue = dockDefaults?.float(forKey: "tilesize") {
            size = CGFloat(sizeValue)
        }

        // 放大倍率（范围通常是 1.0 到 2.0）
        if let magnificationValue = dockDefaults?.float(forKey: "magnification") {
            magnification = CGFloat(magnificationValue)
        }

        // Dock 的位置
        if let positionValue = dockDefaults?.string(forKey: "orientation") {
            position = DockPosition.fromSystemValue(positionValue)
        }
    }

    /// 保存设置到系统
    func saveSystemDockSettings() {
        let dockDefaults = UserDefaults(suiteName: "com.apple.dock")

        // 保存设置
        dockDefaults?.set(autohide, forKey: "autohide")
        dockDefaults?.set(Float(size), forKey: "tilesize")
        dockDefaults?.set(Float(magnification), forKey: "magnification")
        dockDefaults?.set(position.rawValue, forKey: "orientation")

        // 应用更改（需要重新加载 Dock）
        _ = runShellCommand("killall Dock")
    }

    /// 运行 shell 命令（用于重启 Dock）
    private func runShellCommand(_ command: String) -> String? {
        let process = Process()
        process.launchPath = "/bin/zsh"
        process.arguments = ["-c", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
}
