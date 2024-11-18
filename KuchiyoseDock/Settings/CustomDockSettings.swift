//
//  CustomDockSettings.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import Foundation

class CustomDockSettings: ObservableObject {
    @Published var mirrorSystem: Bool// dock content mirror system or not
    @Published var animationSpeed: Double
//    @Published var dockStyle: DockStyle
    // todo: implement multiple dock style like clusters, ring, etc.
    // if not custom, then use system style.
    
    init() {
        self.animationSpeed = 0.1
        self.mirrorSystem = true
    }
}
