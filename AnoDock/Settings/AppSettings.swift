//
//  AppSettings.swift
//  AnoDock
//
//  Created by John Yang on 12/19/24.
//

//  app setting includes:
//  app appearance
//  start at login
//  check update
//  ...and more
//  Some properties are place holders for now, to be implemented

import Foundation

class AppSettings: ObservableObject {
    @Published var darkMode: Bool
    @Published var permissionGranted: Bool
    @Published var guideShown: Bool {
        didSet {
            UserDefaults.standard.set(guideShown, forKey: "guideShown")
        }
    }
    @Published var autoUpdate: Bool
    @Published var openAtLogin: Bool
    static let shared = AppSettings()
    
    private init() {
        
        UserDefaults.standard.register(defaults: [
            "guideShown": false
        ])
        
        self.darkMode = UserDefaults.standard.bool(forKey: "darkMode")
        self.permissionGranted = UserDefaults.standard.bool(forKey: "permissionGranted")
        self.guideShown = UserDefaults.standard.bool(forKey: "guideShown")
        self.autoUpdate = UserDefaults.standard.bool(forKey: "autoUpdate")
        self.openAtLogin = UserDefaults.standard.bool(forKey: "openAtLogin")
    }
}
