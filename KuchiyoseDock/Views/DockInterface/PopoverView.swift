//
//  PopoverView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/12/25.
//

import Foundation
import SwiftUI


struct PopoverView: View {
    @ObservedObject var item: DockItem
    let position: CGPoint
    var body: some View {
        Text(item.name)
            .font(.system(size: 12)) // 更大的字体
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(red: 80, green: 80, blue: 80, opacity: 0.9))
                    
            )
        
    }
}
