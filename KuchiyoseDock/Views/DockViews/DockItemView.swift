//
//  File.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import Foundation
import SwiftUI

struct DockItemView: View {
    let item: DockItem
    
    var body: some View {
        VStack {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
            
            Text(item.name)
                .font(.system(size: 10))
                .lineLimit(1)
        }
        .padding(4)
    }
}
