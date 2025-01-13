//
//  GenieTest.swift
//  KuchiyoseDockTests
//
//  Created by John Yang on 1/12/25.
//

import Foundation
import Cocoa
import SpriteKit

// 创建一个测试窗口
func createTestWindow() -> NSWindow {
    let window = NSWindow(
        contentRect: NSRect(x: 200, y: 200, width: 400, height: 300),
        styleMask: [.titled, .closable, .resizable],
        backing: .buffered,
        defer: false
    )
    window.title = "Test Genie Effect"
    window.makeKeyAndOrderFront(nil)
    return window
}

// 测试 GenieEffect
func testGenieEffect() {
    let testWindow = createTestWindow()
    
    // 延迟执行动画，确保窗口完全显示
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        // 获取鼠标位置作为目标点
        let mouseLocation = NSEvent.mouseLocation
        
        // 运行 Genie 动画
        GenieEffect.apply(to: testWindow, endPoint: mouseLocation, duration: 1.0) {
            print("Genie animation completed!")
        }
    }
}

