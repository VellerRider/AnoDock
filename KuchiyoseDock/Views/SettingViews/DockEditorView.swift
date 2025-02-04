//
//  EditDockView.swift
//  KuchiyoseDock
//  The view for editing custom dock. DockEditor.
//  See what is in the custom dock.
//  Should support drag in drag out apps or folders.
//  
//  Created by John Yang on 11/20/24.
//

import Foundation
import SwiftUI

struct DockEditorView : View {
    @EnvironmentObject var dockEditorSettings: DockEditorSettings
    @EnvironmentObject var dockObserver: DockObserver
    @EnvironmentObject var dockWindowManager: DockWindowManager
    @EnvironmentObject var dragDropManager: DragDropManager
    @EnvironmentObject var dockWindowState: DockWindowState
    @State var zoomChanging: Bool = false
    
    var body : some View {
        VStack {
            VStack {
                VStack(spacing: 8) {
                    Text("Here are what's in your dock.")
                        .font(.headline)
                    Text("Try drag and drop to reorder.")
                        .font(.subheadline)
                }
                .padding(.bottom, 20)
                HStack {
                    Button(action: dragDropManager.manualAddApp) {
                        Image(systemName: "plus")
                            .font(.title)
                            .frame(width: 35, height: 30)
                    }
                    Button(action: dragDropManager.toggleEditingMode) {
                        Image(systemName: dockEditorSettings.isEditing ? "checkmark.circle" : "pencil")
                            .font(.title)
                            .frame(width: 35, height: 30)
                    }
                }
            }
            .padding(.bottom, 20)

                
            DockOverlayView(inEditorTab: true)
                .padding(.bottom, 40)
            
            
            VStack(spacing: 20) {
                VStack {
                    Text("Zoom Dock")
                    Slider(
                        value: $dockEditorSettings.dockZoom,
                        in: 0.5...1.5,
                        onEditingChanged: { editing in
                            zoomChanging = editing
                            if editing {
                                dockWindowManager.showDock()
                                dockWindowState.mouseIn = true
                            } else {
                                dockWindowManager.hideDock()
                            }
                        }
                    )
                    .onChange(of: dockEditorSettings.dockZoom) {
                        dockEditorSettings.dockPadding = 36 * dockEditorSettings.dockZoom
                        dockEditorSettings.iconWidth = 64 * dockEditorSettings.dockZoom
                    }
                    
                    .overlay(
                        GeometryReader { geometry in
                            if zoomChanging {
                                let sliderWidth = geometry.size.width
                                let position = calculatePosition(for: dockEditorSettings.dockZoom, in: sliderWidth)
                                Text(String(format: "%.2f", dockEditorSettings.dockZoom))
                                    .font(.caption)
                                    .padding(5)
                                    .background(Color.white)
                                    .cornerRadius(5)
                                    .offset(x: position - 12 * dockEditorSettings.dockZoom, y: -30)
                            }
                        }
                    )
                    	
                    HStack {
                        Text("0.5x")
                        Spacer()
                        Text("1x")
                            .offset(x: calcZoomScale(for: 1.0, in: 200))
                            .padding(.leading, 6.3)
                        Spacer()
                        Text("1.5x")
                    }
                    .font(.caption)
                }
                .frame(maxWidth: 200)

                
                Picker("Select an Dock Style", selection: $dockEditorSettings.dockStyle) {
                    Text("Option 1").tag("Option 1")
                    Text("Option 2").tag("Option 2")
                    Text("Option 3").tag("Option 3")
                }
                .pickerStyle(.radioGroup)
                
                Toggle(isOn: $dockEditorSettings.cursorClose) {
                    Text("Close when cursor moves out")
                }
                

            }
        }
        .onTapGesture { // when editing tap empty space to return
            if dockEditorSettings.isEditing {
                dragDropManager.toggleEditingMode()
            }
        }
        
        .frame(minHeight: 600)
        .onAppear() {
            dragDropManager.editorOpen = true
            print("Editor open")
        }
        .onDisappear() {
            dragDropManager.editorOpen = false
            print("Editor close")
        }
    }
    
    
    func calcZoomScale(for value: Double, in width: CGFloat) -> CGFloat {
        let minValue: Double = 0.5
        let maxValue: Double = 1.5
        let position = (value - minValue) / (maxValue - minValue) * width
        return position - width / 2
    }
    
    func calculatePosition(for value: Double, in width: CGFloat) -> CGFloat {
        let minValue: Double = 0.5
        let maxValue: Double = 1.5
        let relativePosition = (value - minValue) / (maxValue - minValue)
        return relativePosition * width
    }
}
