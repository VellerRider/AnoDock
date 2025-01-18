//
//  DockAnimation.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/15/25.
//

import Foundation
import SwiftUI
extension Animation {
    static let dockUpdateAnimation = Animation.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
    static let goneAnimation = Animation.linear(duration: 0.25)
}
