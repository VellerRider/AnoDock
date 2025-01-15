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
    
    @State var zoomChanging: Bool = false
    @State var tempDockZoom: Double = 0
    
    var body : some View {
        VStack {
            CustomDockView()
                .padding(.bottom, 40)
            
            VStack(spacing: 20) {
                VStack {
                    Text("Zoom Dock")
                    Slider(
                        value: $tempDockZoom,
                        in: 0.2...2.5,
                        onEditingChanged: { editing in
                            zoomChanging = editing
                            if !editing {
                                snapToClosestValue()
                                updateSettingZoom()
                            }
                        }
                    )
                    
                    .overlay(
                        GeometryReader { geometry in
                            if zoomChanging {
                                let sliderWidth = geometry.size.width
                                let position = calculatePosition(for: tempDockZoom, in: sliderWidth)
                                Text(String(format: "%.2f", tempDockZoom))
                                    .font(.caption)
                                    .padding(5)
                                    .background(Color.white)
                                    .cornerRadius(5)
                                    .offset(x: position-9*(tempDockZoom-0.2/2.3)-4, y: -30)
                            }
                        }
                    )
                    
                    HStack {
                        Text("0.2x")
                        Spacer()
                        Text("1x")
                            .offset(x: calcZoomScale(for: 1.0, in: 200))
                            .padding(.leading, 6.3)
                        Spacer()
                        Text("2.5x")
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
        .onAppear() {
            retrieveSetting()
        }
    }
    
    func snapToClosestValue() {
        let snapValues: [Double] = Array(stride(from: 1.0, through: 2.5, by: 0.1))
        let threshold: Double = 0.05
        if let closestValue = snapValues.min(by: { abs(tempDockZoom - $0) < abs(tempDockZoom - $1) }),
           abs(tempDockZoom - closestValue) <= threshold {
            tempDockZoom = closestValue
        }
    }
    
    func retrieveSetting() {
        tempDockZoom = dockEditorSettings.dockZoom
    }
    
    func updateSettingZoom() {
        dockEditorSettings.dockZoom = tempDockZoom
    }
    
    func calcZoomScale(for value: Double, in width: CGFloat) -> CGFloat {
        let minValue: Double = 0.2
        let maxValue: Double = 2.5
        let position = (value - minValue) / (maxValue - minValue) * width
        return position - width / 2
    }
    
    func calculatePosition(for value: Double, in width: CGFloat) -> CGFloat {
        let minValue: Double = 0.2
        let maxValue: Double = 2.5
        let relativePosition = (value - minValue) / (maxValue - minValue)
        return relativePosition * width
    }
}
