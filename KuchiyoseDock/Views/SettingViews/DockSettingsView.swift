//
//  DockSettingsView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/20/24.
//

import Foundation
import SwiftUI

struct DockSettingsView : View {
    @EnvironmentObject var appsetting: AppSettings
    @EnvironmentObject var customdocksetting: DockSettings

    var body: some View {
        
        HStack {
            
            Form {
                Text("Dock Setting")
            }
            
            // go to system dock setting
            Button(action: {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension")!)
            }) {
                Text("Go to Dock Settings for more editing")
                    .padding()
            }
            Text("We can't apply changes here because that will require more authorization.")
                .font(.system(size: 10))
                .frame(maxWidth: 200)
        }
    }
}
