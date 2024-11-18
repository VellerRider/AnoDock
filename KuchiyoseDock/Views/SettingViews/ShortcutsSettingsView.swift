//
//  ShortcutsSettingsView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import Foundation
import SwiftUI

struct ShortcutsSettingsView: View {
    @EnvironmentObject var hotKeySettings: HotKeySettings
    @State private var currentKey: KeyboardShortcut? // 当前输入的快捷键

    var body: some View {
        Text("Placeholder")
//        VStack {
//            Toggle("Enable HotKey", isOn: $hotKeySettings.isEnabled)
//                .padding()
//
//            if hotKeySettings.isEnabled {
//                HStack {
//                    Text("Current Shortcut:")
//                    if let shortcut = hotKeySettings.keyboardShortcut {
//                        Text(describeShortcut(shortcut))
//                            .foregroundColor(.blue)
//                    } else {
//                        Text("None")
//                            .foregroundColor(.gray)
//                    }
//                }
//                .padding()
//
//                Button("Set Shortcut") {
//                    // 设置新的快捷键
//                    hotKeySettings.keyboardShortcut = currentKey
//                }
//                .keyboardShortcut(currentKey) // 实时更新输入的快捷键
//            }
//        }
//        .padding()
//        .onChange(of: hotKeySettings.keyboardShortcut) { newValue in
//            // 这里可以持久化到 UserDefaults
//            saveShortcutToDefaults(newValue)
//        }
//        .onAppear {
//            // 从 UserDefaults 加载快捷键
//            hotKeySettings.keyboardShortcut = loadShortcutFromDefaults()
//        }
    }

//    /// 将快捷键描述为字符串
//    func describeShortcut(_ shortcut: KeyboardShortcut) -> String {
//        var parts: [String] = []
//
//        if shortcut.modifiers.contains(.command) {
//            parts.append("⌘")
//        }
//        if shortcut.modifiers.contains(.shift) {
//            parts.append("⇧")
//        }
//        if shortcut.modifiers.contains(.option) {
//            parts.append("⌥")
//        }
//        if shortcut.modifiers.contains(.control) {
//            parts.append("^")
//        }
//
//        parts.append(shortcut.key.description.uppercased())
//
//        return parts.joined(separator: " + ")
//    }
//
//    /// 持久化快捷键
//    func saveShortcutToDefaults(_ shortcut: KeyboardShortcut?) {
//        guard let shortcut = shortcut else {
//            UserDefaults.standard.removeObject(forKey: "HotKeyShortcut")
//            return
//        }
//
//        let data = [
//            "key": shortcut.key.description,
//            "modifiers": shortcut.modifiers.rawValue
//        ] as [String: Any]
//        UserDefaults.standard.set(data, forKey: "HotKeyShortcut")
//    }
//
//    /// 从 UserDefaults 加载快捷键
//    func loadShortcutFromDefaults() -> KeyboardShortcut? {
//        guard let data = UserDefaults.standard.dictionary(forKey: "HotKeyShortcut"),
//              let key = data["key"] as? String,
//              let modifiers = data["modifiers"] as? UInt else {
//            return nil
//        }
//
//        guard let keyEquivalent = key.first else { return nil }
//        let keyModifiers = EventModifiers(rawValue: modifiers)
//        return KeyboardShortcut(KeyEquivalent(keyEquivalent), modifiers: keyModifiers)
//    }
}
