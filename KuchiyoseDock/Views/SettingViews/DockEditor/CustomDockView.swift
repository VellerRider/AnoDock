//
//  CustomDockView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import Foundation
import SwiftUI

import SwiftUI

struct CustomDockView: View {
    @State private var dockItems: [DockItem] = []
    @StateObject private var appStateMonitor = AppStateMonitor()
    
    var body: some View {
        HStack {
            ForEach(dockItems) { item in
                DockItemView(item: item)
                    .environmentObject(appStateMonitor)
                    // 拖放和删除功能
            }
            // 添加项目按钮
            Button(action: {
                // 打开文件选择器
            }) {
                Image(systemName: "plus")
            }
        }
        .onAppear {
//            dockItems = loadCustomDockItems()
        }
    }
}
