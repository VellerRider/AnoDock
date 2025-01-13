//
//  AppSettings.swift
//  KuchiyoseDock
//
//  Created by John Yang on 12/19/24.
//

//  app setting includes:
//  app appearance
//  start at login
//  check update
//  ...and more

import Foundation

class AppSettings: ObservableObject {
    @Published var darkMode: Bool
    @Published var permissionGranted: Bool
    @Published var autoUpdate: Bool
    static let shared = AppSettings()
    
    init() {
        self.darkMode = UserDefaults.standard.bool(forKey: "darkMode")
        self.permissionGranted = UserDefaults.standard.bool(forKey: "permissionGranted")
        self.autoUpdate = UserDefaults.standard.bool(forKey: "autoUpdate")
        
    }
}
