//
//  DockItemSection.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/19/24.
//


//  create a container for custom items

import SwiftUI

struct DockItemSectionView: View {
    let title: String
    let items: [DockItem]
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding(.leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(items) { item in
                        DockItemView(item: item)
                    }
                }
            }
            .frame(height: 100)
        }
    }
}
