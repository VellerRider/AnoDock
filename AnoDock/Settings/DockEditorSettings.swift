//
//  DockEditorSettings.swift
//  AnoDock
//
//  Created by John Yang on 1/13/25.
//

import Foundation

class DockEditorSettings: ObservableObject {
    
    @Published var cursorClose: Bool {
        didSet {
            UserDefaults.standard.set(cursorClose, forKey: "cursorClose")
        }
    }
    
    @Published var dockZoom: Double {
        didSet {
            print("zoom updated to: \(dockZoom)")
            UserDefaults.standard.set(dockZoom, forKey: "dockZoom")
        }
    }
    @Published var dockPadding: CGFloat {
        didSet {
            print("Padding updated to: \(dockPadding)")
            UserDefaults.standard.set(dockPadding, forKey: "dockPadding")
        }
    }

    @Published var iconWidth: CGFloat {
        didSet {
            print("iconWidth updated to: \(iconWidth)")
            UserDefaults.standard.set(iconWidth, forKey: "iconWidth")
        }
    }
    
    @Published var dockStyle: String {
        didSet {
            UserDefaults.standard.set(dockStyle, forKey: "dockStyle")
        }
    }
    
    @Published var keepClosedRecents: Int {
        didSet {
            UserDefaults.standard.set(keepClosedRecents, forKey: "keepClosedRecents")
        }
    }
    
    @Published var isEditing: Bool = false
    
    static let shared = DockEditorSettings()
    
    private init() {
        UserDefaults.standard.register(defaults: [
            "cursorClose": false,
            "dockZoom": 1.0,
            "dockPadding": 36.0,
            "iconWidth": 64.0,
            "dockStyle": "native",
            "keepClosedRecents": 5
        ])
        
        self.cursorClose = UserDefaults.standard.bool(forKey: "cursorClose")
        self.dockZoom = UserDefaults.standard.double(forKey: "dockZoom")
        self.dockPadding = UserDefaults.standard.double(forKey: "dockPadding")
        self.iconWidth = UserDefaults.standard.double(forKey: "iconWidth")
        self.dockStyle = UserDefaults.standard.string(forKey: "dockStyle") ?? "native"
        self.keepClosedRecents = UserDefaults.standard.integer(forKey: "keepClosedRecents")
        
    }
}
