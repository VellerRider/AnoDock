//
//  ItemPopoverManager.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/12/25.
//

import Foundation
import SwiftUI

class ItemPopoverManager: ObservableObject {
    @Published var name: String = ""
    @Published var position: CGPoint = .zero
    @Published var isHovered: Bool = false
    static let shared = ItemPopoverManager()
    
    
    
    private var window: NSWindow?
    func showPopover(name: String, Position: CGPoint) {
        
    }
    
    func hidePopover() {
        
    }
        
    
}
