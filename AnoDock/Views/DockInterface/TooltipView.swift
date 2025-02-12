//
//  TooltipView.swift
//  AnoDock
//
//  Created by John Yang on 2/1/25.
//

import Foundation
import SwiftUI
import AppKit

struct TooltipView: View {
    let text: String
    var body: some View {
        ZStack {
            VisualEffectView(material: .fullScreenUI, blendingMode: .behindWindow)
            Text(text)
                .foregroundStyle(Color.black.opacity(0.65))
                .font(.system(size: 14, design: .rounded))
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.clear)
        }
        .cornerRadius(5)
        .fixedSize()

    }
}
