//
//  testview.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/10/25.
//

import Foundation
import SwiftUI

struct TestView: View {
    var body: some View {
        VStack {
            Image(systemName: "app.fill")
                .resizable()
                .frame(width: 64, height: 64)
        }
        .help("Test Item") // 简化测试，确保显示提示框
    }
}

#Preview { TestView() }
