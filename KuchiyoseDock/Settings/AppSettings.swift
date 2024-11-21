//
//  AppSettings.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

// app setting includes:
// app appearance
// start at login
// ...and more
import Foundation

class AppSettings: ObservableObject {
    @Published var darkMode: Bool
    @Published var permissionGranted: Bool
    
    init() {
        self.darkMode = UserDefaults.standard.bool(forKey: "darkMode")
        self.permissionGranted = UserDefaults.standard.bool(forKey: "permissionGranted")
    }
}
