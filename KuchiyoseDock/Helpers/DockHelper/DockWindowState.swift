//
//  DockState.swift
//  KuchiyoseDock
//
//  Created by John Yang on 1/11/25.
//

import Foundation
class DockWindowState: ObservableObject {
    static let shared = DockWindowState()
    @Published var showDockWindow: Bool = false
    @Published var mouseIn: Bool = false
}
