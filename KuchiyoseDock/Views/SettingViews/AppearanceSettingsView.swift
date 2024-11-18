//
//  AppearanceSettings.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import Foundation
import SwiftUI

struct AppearanceSettingsView : View {
    @EnvironmentObject var appsetting: AppSettings
    @EnvironmentObject var customdocksetting: CustomDockSettings
    // todo: some extra aesthetic stuff
    var body: some View {
        
        HStack {
            
            Form {
                Text("Appearance Setting")
            }
            
        }
    }
}
