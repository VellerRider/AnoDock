//
//  GeneralSettingsView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import Foundation
import SwiftUI

enum DockStyle {
    case ring
    case clusters
    case systemdefault
}
struct GeneralSettingsView: View {
    // todo: the main settings are here
    // mirror dock or custom dock
    // and stuffs to do with system dock
    @EnvironmentObject var systemdocksetting: SystemDockSettings
    @EnvironmentObject var appsetting: AppSettings
    @EnvironmentObject var customdocksetting: CustomDockSettings
    @State var dockstyle: DockStyle = DockStyle.systemdefault
    
    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Toggle("Mirror System", isOn: $customdocksetting.mirrorSystem)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Choose Dock Style")
                            .font(.headline)
                        
                        Picker(selection: $dockstyle, label: EmptyView()) {
                            Text("Custom System")
                                .tag(DockStyle.systemdefault)
                            Text("Ring")
                                .tag(DockStyle.ring)
                            Text("Clusters")
                                .tag(DockStyle.clusters)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding()
            }
        }
}

#Preview {
    GeneralSettingsView()
        .environmentObject(SystemDockSettings())
        .environmentObject(AppSettings())
        .environmentObject(CustomDockSettings())
}
