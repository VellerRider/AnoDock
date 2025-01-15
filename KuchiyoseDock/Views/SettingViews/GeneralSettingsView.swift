//
//  GeneralSettingsView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var generalSettings: GeneralSettings

    var body: some View {
        VStack {
            Text("Dock Settings")
                .padding(.top, 10)
            
            Spacer()
            
            
        }
    }
}

//#Preview {
//    GeneralSettingsView()
//        .environmentObject(SystemDockSettings())
//}
