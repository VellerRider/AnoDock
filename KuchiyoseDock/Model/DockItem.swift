//
//  DockItem.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//

import Foundation
import AppKit

enum DockItemType {
    case app
    case folder
    case recent
}
struct DockItem {
    var icon : NSImage
    var name : String
    var active : Bool // tiny dot in macOS dock
    
}
