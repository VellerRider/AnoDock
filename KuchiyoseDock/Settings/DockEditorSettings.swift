//
//  DockEditorSettings.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/13/25.
//

import Foundation
class DockEditorSettings: ObservableObject {
    
    @Published var cursorClose: Bool// when cursor move out of dock, close app
    @Published var dockZoom: Double
    @Published var isEditing: Bool
    
    static let shared = DockEditorSettings()
    
    init() {
        self.cursorClose = UserDefaults.standard.bool(forKey: "cursorClose")
        self.dockZoom = UserDefaults.standard.double(forKey: "dockZoom")
        self.isEditing = false
    }

    

}
