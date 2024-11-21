//
//  GeneralSettingsView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var systemDockSettings: SystemDockSettings

    var body: some View {
        ScrollView {
            VStack {
                Text("System Dock Settings")
                    .font(.title)
                    .padding()
                
                // Size Slider
                HStack {
                    VStack {
                        Text("Size: \(Int(systemDockSettings.size))")
                        Slider(value: $systemDockSettings.size, in: 16...128)
                            .disabled(true)
                        HStack {
                            Text("Small").foregroundColor(.secondary)
                            Spacer()
                            Text("Large").foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 150)
                    .padding()
                    
                    // Magnification Slider
                    VStack {
                        Text("Magnification: \(Int(systemDockSettings.magnification))")
                        Slider(value: $systemDockSettings.magnification, in: 0...256)
                            .disabled(true)
                        HStack {
                            Text("Off").foregroundColor(.secondary)
                            Spacer()
                            Text("Max").foregroundColor(.secondary)
                        }
                    }
                    .frame(width: 150)
                    .padding()
                }
                
                // Position Picker
                HStack {
                    Text("Position on Screen")
                    Spacer()
                    
                    Picker(selection: $systemDockSettings.position, label: Text("")) {
                        ForEach(DockPosition.allCases) { position in
                            Text(position.rawValue.capitalized).tag(position)
                        }
                    }
                    .disabled(true)
                    
                    .frame(width: 90)
                }
                .frame(width: 350)
                .padding()
                
                // Apply Settings Button
                Button(action: {
                    systemDockSettings.openDockSystemSettings()
                }) {
                    Text("Go to Dock Settings")
                        .padding()
                }
                Text("We can't apply changes here because that will require more authorization.")
                    .font(.system(size: 10))
                    .frame(maxWidth: 200)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    GeneralSettingsView()
        .environmentObject(SystemDockSettings())
}
