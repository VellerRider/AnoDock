//
//  CustomDockOverlayView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 12/28/24.
//

/*
 Overlay for custom dock UI.
 */
import Foundation
import SwiftUI

struct CustomDockOverlayView: View {
    let items: [DockItem]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            ForEach(items) { item in
                DockItemView(item: item, interactive: true)
            }
        }
        .padding()
        .background(
            VisualEffectView(material: .sidebar, blendingMode: .withinWindow)
                .cornerRadius(12)
        )
    }
}
