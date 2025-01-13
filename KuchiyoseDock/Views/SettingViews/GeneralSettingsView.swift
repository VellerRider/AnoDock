//
//  GeneralSettingsView.swift
//  KuchiyoseDock
//
//  Show some content of system dock setting.
//  Maybe could allow user to change system dock settings from here.
//  Plus, maybe appearance of custom dock, mirror system dock, etc. go here.
//  Created by John Yang on 11/17/24.
//

import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var generalSettings: GeneralSettings

    var body: some View {
        ScrollView {
            VStack {
                Text("System Dock Settings")
                    .font(.title)
                    .padding()
        
            }
            .padding()
        }
    }
}

//#Preview {
//    GeneralSettingsView()
//        .environmentObject(SystemDockSettings())
//}
