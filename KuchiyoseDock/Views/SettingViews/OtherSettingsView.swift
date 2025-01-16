//
//  DockSettingsView.swift
//  KuchiyoseDock
//  Start at login, auto update, permission check-again etc.
//  Maybe could allow user to change system dock settings from here.
//  Created by John Yang on 11/20/

/*
    Should store some non-essential settings here
    
 */

import Foundation
import SwiftUI

struct OtherSettingsView : View {
    @EnvironmentObject var appsetting: AppSettings

    var body: some View {
        VStack {
            
            HStack {
                
                Form {
                    Text("Other Setting")
                }
                
                Button(action: {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.Desktop-Settings.extension")!)
                }) {
                    Text("Go to Dock Settings for more editing")
                        .padding()
                }
            }
            Text("We can't apply changes here because that will require more authorization.")
                .font(.system(size: 10))
        }
        .frame(width: 500, height: 300)
    }
}
