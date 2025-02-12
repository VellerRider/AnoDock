//
//  ShortcutsSettingsView.swift
//  AnoDock
//
//  Setting tab for changing shortcuts
//
//  Created by John Yang on 11/17/24.
//

import SwiftUI

extension EventModifiers: @retroactive Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
    public static func ==(lhs: EventModifiers, rhs: EventModifiers) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
}

struct ShortcutsSettingsView: View {
    
    @EnvironmentObject var hotKeySettings: HotKeySettings
    @State private var selectedModifiers: EventModifiers = [.option, .shift]
    @State private var selectedKey: KeyEquivalent = .space

    let allowedModifiers: [EventModifiers] = [
        [],
        [.command],
        [.shift],
        [.option],
        [.control],
        [.command, .shift],
        [.option, .shift],
        [.control, .shift],
        [.command, .option],
        [.command, .control],
        [.option, .control],
        [.command, .option, .shift],
        [.command, .control, .shift],
        [.command, .option, .control],
        [.option, .control, .shift],
        [.command, .option, .control, .shift]
    ]

    let allowedKeys: [KeyEquivalent] = [
        .space,
        .tab,
        .return,
        .escape,
        .delete,
        KeyEquivalent("a"),
        KeyEquivalent("b"),
        KeyEquivalent("0"),
        KeyEquivalent("1"),
        KeyEquivalent("."),
        KeyEquivalent("/"),
        KeyEquivalent("`"),
    ]

    var body: some View {
        VStack(spacing: 30) {

            // Modifiers
            VStack(alignment: .center) {
                HStack(spacing: 10) {
                    Text("Current Shortcut:")
                        .frame(maxWidth: 150, alignment: .trailing)
                    Text("\(describeModifiers(hotKeySettings.keyboardShortcut?.modifiers ?? [])) \(describeKeyEquivalent(hotKeySettings.keyboardShortcut?.key ?? .init(" ")))")
                        .font(.headline)
                        .frame(maxWidth: 150)

                }
                .padding(10)
                HStack {
                    Text("Choose Modifiers:")
                        .frame(maxWidth: 150, alignment: .trailing)
                    Picker("", selection: $selectedModifiers) {
                        ForEach(allowedModifiers, id: \.self) { modSet in
                            Text(describeModifiers(modSet)).tag(modSet)
                        }
                    }
                    .frame(maxWidth: 150)
                }
                // Key
                HStack {
                    Text("Choose Key:")
                        .frame(maxWidth: 150, alignment: .trailing)
                    Picker("", selection: $selectedKey) {
                        ForEach(allowedKeys, id: \.self) { keyEq in
                            Text(describeKeyEquivalent(keyEq)).tag(keyEq)
                        }
                    }
                    .frame(maxWidth: 150)
                }
            }
            
            Button("Apply Shortcut") {
                let shortcut = KeyboardShortcut(selectedKey, modifiers: selectedModifiers)
                hotKeySettings.applyNewShortcut(shortcut)
            }
        }
        .frame(width: 300, height: 300)
        .padding(30)
        .onAppear {
            // 1) Grab the user's current saved shortcut
            if let currentShortcut = hotKeySettings.keyboardShortcut {
                selectedModifiers = currentShortcut.modifiers
                selectedKey = currentShortcut.key
            }
        }
    }
    
    
    // helper to display actual key string
    func describeModifiers(_ mods: EventModifiers) -> String {
        var parts = [String]()
        if mods.contains(.command)  { parts.append("⌘") }
        if mods.contains(.shift)    { parts.append("⇧") }
        if mods.contains(.option)   { parts.append("⌥") }
        if mods.contains(.control)  { parts.append("^") }
        if parts.isEmpty { parts.append("None") }
        return parts.joined(separator: " + ")
    }
    
    
    // helper to get String from KeyEquivalent
    func describeKeyEquivalent(_ key: KeyEquivalent) -> String {
        switch key {
        case .space:  return "Space"
        case .tab: return "Tab"
        case .return: return "Return"
        case .escape: return "Escape"
        case .delete: return "Delete"
        default:      return stringFromKeyEquivalent(key).uppercased()
        }
    }

    // Helper to convert `KeyEquivalent` to a letter/digit
    func stringFromKeyEquivalent(_ key: KeyEquivalent) -> String {
        // On recent SwiftUI, there's no direct 'character' case,
        // so we rely on `String(describing:)` or a known init:
        // E.g. "KeyEquivalent(\"a\")" => we parse out "a"
        let desc = String(describing: key)
        // If it yields KeyEquivalent("a"), we strip out quotes
        // This is a hacky approach, but works for known single chars
        if desc.contains("character: \"") {
            if let start = desc.range(of: "character: \"")?.upperBound,
               let end = desc[start...].firstIndex(of: "\"") {
                return String(desc[start..<end])
            }
        }
        return "?"
    }
}
