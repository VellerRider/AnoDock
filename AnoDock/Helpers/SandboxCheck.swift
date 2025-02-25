//
//  SandboxCheck.swift
//  AnoDock
//
//  Created by John Yang on 2/24/25.
//

import Foundation
// MARK: check if this is sandboxed
extension ProcessInfo {
    var isSandboxed: Bool {
        environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }
}
