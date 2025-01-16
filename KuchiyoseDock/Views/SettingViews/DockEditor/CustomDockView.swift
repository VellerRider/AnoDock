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
    @EnvironmentObject var itemPopoverManager: ItemPopoverManager
    @EnvironmentObject var dockEditorSettings: DockEditorSettings
    @EnvironmentObject var dragDropManager: DragDropManager
    
    
    var body: some View {
        VStack {
            HStack {
                VStack(spacing: 8) { // spacing 控制两行文字的间距
                    Text("Here are what's in your dock.")
                        .font(.headline) // 可选：设置字体样式
                    Text("Try drag and drop to reorder.")
                        .font(.subheadline) // 可选：设置不同样式
                        .foregroundColor(.gray) // 可选：调整颜色
                }
                Button(action: dragDropManager.manualAddApp) {
                    Image(systemName: "plus")
                        .font(.title)
                }
                Button(action: dragDropManager.toggleEditingMode) {
                    Image(systemName: dockEditorSettings.isEditing ? "checkmark.circle" : "pencil")
                        .font(.title)
                }
                
            }
            .frame(maxWidth: dockObserver.dockUIFrame.width, maxHeight: dockObserver.dockUIFrame.height)
            
            ZStack{
                DockOverlayView(inEditorTab: true)
            }
            .onTapGesture {
                if dockEditorSettings.isEditing {
                    dragDropManager.toggleEditingMode()
                }
            }
            
            

        }

        // drop apps from outside
        .onDrop(of: ["public.file-url"], isTargeted: nil) { providers in
            dragDropManager.dropAddApp(providers: providers, targetIndex: nil)// add to last
        }
    }
}
