//
//  CustomDockView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/17/24.
//
/*
 The interface to edit custom dock.
 */
import SwiftUI
import UniformTypeIdentifiers

struct CustomDockView: View {
    @EnvironmentObject var dockObserver: DockObserver
    @EnvironmentObject var dockWindowManager: DockWindowManager
    @EnvironmentObject var itemPopoverManager: ItemPopoverManager
    @EnvironmentObject var dockEditorSettings: DockEditorSettings
    @EnvironmentObject var dragDropManager: DragDropManager
    
    
    var body: some View {

        ZStack{
            DockOverlayView(inEditorTab: true)
        }
        // drop apps from outside

    }
}
