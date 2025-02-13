//
//  HotKeySettings.swift
//  AnoDock
//
//  Created by John Yang on 11/17/24.
//
import SwiftUI
import HotKey  // Soffes' HotKey library

class HotKeySettings: ObservableObject {
    @Published var keyboardShortcut: KeyboardShortcut?
    
    @Published var globalHotKey: HotKey? {
        didSet {
            print("globalHotKey updated to \(String(describing: globalHotKey?.keyCombo))")
        }
    }
    static let shared = HotKeySettings()
    private let userDefaultsKey = "HotKeyShortcut"
    
    init() {
        // 1) Attempt to load user's saved shortcut from disk
        loadFromUserDefaults()
        
        // 2) If no saved shortcut, or it was invalid, use the default
        if keyboardShortcut == nil {
            // default: Option + Shift + Space
            keyboardShortcut = KeyboardShortcut(.tab, modifiers: [.option])
        }
        
        // 3) Update the Soffes HotKey to reflect the final (saved or default) shortcut
        updateHotKey()
    }
    
    // MARK: - Load/Save
    
    /// Saves the user's chosen `keyboardShortcut` to UserDefaults (no "off" state).
    func saveToUserDefaults() {
        guard let shortcut = keyboardShortcut else {
            // If something weird happened and there's no shortcut,
            // revert to default. This shouldn't happen if "no hotkey" is impossible.
            resetToDefaultShortcut()
            return
        }
        
        let data: [String: Any] = [
            "key": describeKeyEquivalent(shortcut.key),
            "modifiers": shortcut.modifiers.rawValue
        ]
        
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
    
    /// Loads the user's chosen shortcut from UserDefaults. Returns nil if none or invalid.
    func loadFromUserDefaults() {
        let defaults = UserDefaults.standard
        guard
            let dict = defaults.dictionary(forKey: userDefaultsKey),
            let keyString = dict["key"] as? String,
            let rawModifiers = dict["modifiers"] as? UInt
        else {
            keyboardShortcut = nil
            return
        }
        
        let modifiers = EventModifiers(rawValue: Int(rawModifiers))
        
        // Convert the stored keyString back into a KeyEquivalent
        // e.g. "A" -> KeyEquivalent("a"), "Space" -> .space
        if let eq = parseKeyEquivalent(keyString) {
            keyboardShortcut = KeyboardShortcut(eq, modifiers: modifiers)
        } else {
            keyboardShortcut = nil
        }
    }
    
    // MARK: - Public Methods
    
    /// If user picks a new KeyboardShortcut, call this to store & apply it.
    func applyNewShortcut(_ shortcut: KeyboardShortcut) {
        // 1) Update the SwiftUI format
        self.keyboardShortcut = shortcut
        // 2) Persist it
        self.saveToUserDefaults()
        // 3) Activate it system-wide
        self.updateHotKey()
    }
    
    /// Called whenever `keyboardShortcut` changes, to rebuild the Soffes HotKey.
    func updateHotKey() {
        guard let shortcut = keyboardShortcut else {
            resetToDefaultShortcut()
            return
        }
        
        // Convert SwiftUI's KeyboardShortcut => Soffes Key + Modifiers
        let charString = describeKeyEquivalent(shortcut.key).lowercased()
        
        // Map to Soffes Key. E.g. "a" -> .a, "space" -> .space, etc.
        guard let mappedKey = mapStringToSoffesKey(charString) else {
            resetToDefaultShortcut()
            return
        }
        
        // Map SwiftUI EventModifiers => Soffes KeyModifiers
        let soffesMods = mapEventModifiersToSoffesModifiers(shortcut.modifiers)
        
        // Create a brand-new HotKey. (Soffes requires a new instance each time.)
        let newHotKey = HotKey(key: mappedKey, modifiers: soffesMods)
        
        // Hook up the actual callback
        newHotKey.keyDownHandler = {
            NotificationCenter.default.post(name: NSNotification.Name("SummonDock"), object: nil)
        }
        
        // Publish the newly created hotkey
        self.globalHotKey = newHotKey
    }
    
    // MARK: - Helpers
    
    private func resetToDefaultShortcut() {
        // If no user-provided shortcut, fallback
        keyboardShortcut = KeyboardShortcut(.space, modifiers: [.control])
        saveToUserDefaults()
        updateHotKey()
    }
    
    /// Convert your stored string (like "A", "SPACE") to a SwiftUI KeyEquivalent
    private func parseKeyEquivalent(_ s: String) -> KeyEquivalent? {
        switch s.lowercased() {
        case "space":  return .space
        case "tab": return .tab
        case "return": return .return
        case "escape": return .escape
        case "delete": return .delete
        default:
            // If single letter or digit, we can do KeyEquivalent("a")
            if let firstChar = s.lowercased().first {
                return KeyEquivalent(firstChar)
            }
            return nil
        }
    }
    
    /// Convert SwiftUI's KeyEquivalent to a user-friendly string
    private func describeKeyEquivalent(_ key: KeyEquivalent) -> String {
        switch key {
        case .space:  return "Space"
        case .tab: return "Tab"
        case .return: return "Return"
        case .escape: return "Escape"
        case .delete: return "Delete"
        default:
            let desc = String(describing: key)
            if let start = desc.range(of: "character: \"")?.upperBound,
               let end = desc[start...].firstIndex(of: "\"") {
                return String(desc[start..<end]).uppercased()
            }
            return "?"
        }
    }

    
    /// Map the string (like "a", "b", "space") => Soffes Key
    private func mapStringToSoffesKey(_ s: String) -> Key? {
        print(s)
        switch s {
        case "space":  return .space
        case "tab": return .tab
        case "return": return .return
        case "escape": return .escape
        case "delete": return .delete
        
        // For letters
        case "a": return .a
        case "b": return .b
        case "c": return .c
        // etc. You can define more or do a dictionary.
        
        // Digits?
        case "0": return .zero
        case "1": return .one
        case ".": return .period
        case "/": return .slash
        case "`": return .grave
        // etc.
            
        
        default: return nil
        }
    }
    
    /// Map SwiftUI's EventModifiers => Soffes KeyModifiers
    private func mapEventModifiersToSoffesModifiers(_ mods: EventModifiers) -> NSEvent.ModifierFlags {
        var result: NSEvent.ModifierFlags = []
        if mods.contains(.command)  { result.insert(.command) }
        if mods.contains(.shift)    { result.insert(.shift) }
        if mods.contains(.option)   { result.insert(.option) }
        if mods.contains(.control)  { result.insert(.control) }
        return result
    }
}
