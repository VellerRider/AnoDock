//
//  CustomDockSettings.swift
//  AnoDock
//  Sing source of truth for dock general settings
// includes:
// 0. system setting (optional)
// 1. content mirror system or not
// 2. dock style
// 3. animation
// 4. other stuff
// 5. put shortcuts here too
//  Created by John Yang on 11/17/24.
//

import Foundation
class GeneralSettings: ObservableObject {
    @Published var mirrorSystem: Bool// dock content mirror system or not
    @Published var animationSpeed: Double
    static let shared = GeneralSettings()
//     todo: implement multiple dock style like clusters, ring, etc.
//     if not custom, then use system style.
    //    @Published var dockStyle: DockStyle
    
    init() {
        self.mirrorSystem = UserDefaults.standard.bool(forKey: "mirrorSystem")
        self.animationSpeed = UserDefaults.standard.double(forKey: "animationSpeed")
    }
}
