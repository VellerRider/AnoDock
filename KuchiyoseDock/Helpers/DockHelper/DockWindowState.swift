//
//  DockState.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/11/25.
//

import Foundation
class DockWindowState: ObservableObject {
    @Published var showDockWindow: Bool = false
    @Published var mouseIn: Bool = false
    static let shared = DockWindowState()
}
