//
//  HotKeySettings.swift
//  KuchiyoseDock
//
//  Reference of user's current keyboard shortcut
//  to summon dock.
//  Created by John Yang on 11/17/24.
//
import SwiftUI
import Foundation

class HotKeySettings: ObservableObject {
    @Published var isEnabled: Bool
    @Published var keyboardShortcut: KeyboardShortcut?

    init(isEnabled: Bool = false, keyboardShortcut: KeyboardShortcut? = nil) {
        self.isEnabled = isEnabled
        self.keyboardShortcut = keyboardShortcut
    }
}
