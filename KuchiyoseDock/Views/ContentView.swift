//
//  ContentView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/12/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dockObserver: DockPreferencesObserver
    
    var body: some View {
        VStack {
            Text("Here are all items")
            DockItemsView()
        }
        .padding()
        Text("Try dragging and dropping items")
            .frame(width: 800, height: 600)
    }
}

#Preview {
    ContentView()
        .environmentObject(DockPreferencesObserver())
        .environmentObject(AppSettings())
}
