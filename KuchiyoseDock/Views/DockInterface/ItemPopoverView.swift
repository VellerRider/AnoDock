//
//  ItemPopoverView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/12/25.
//

import Foundation
import SwiftUI

struct ItemPopoverView: View {
    @EnvironmentObject var itemPopoverManager: ItemPopoverManager
    
    var body: some View {
        ZStack {
            Text(itemPopoverManager.name)
                .font(.system(size: 12))
                .padding(2)
                .background(Color.white)
                .cornerRadius(1)
                .shadow(radius: 2)
                .position(itemPopoverManager.position)
            
        }
    }
}
