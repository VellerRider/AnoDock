import SwiftUI

struct CustomPickerStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .labelsHidden()
            .pickerStyle(.menu)
            .overlay(
                HStack {
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .padding(.trailing, 4)
                }
            )
            .buttonStyle(.plain)
    }
}

struct SystemSettingsView: View {
    @State private var size: Double = 0.5
    @State private var magnification: Double = 0.2
    @State private var position: String = "Left"
    @State private var minimizeUsing: String = "Genie Effect"
    @State private var doubleClickAction: String = "Zoom"
    @State private var minimizeIntoIcon: Bool = false
    
    let positions = ["Left", "Right"]
    let minimizeEffects = ["Genie Effect", "Scale Effect"]
    let doubleClickActions = ["Zoom", "Minimize"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Size Slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Size")
                    .font(.system(size: 13))
                HStack {
                    Text("Small")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Slider(value: $size) {
                        EmptyView()
                    } minimumValueLabel: {
                        EmptyView()
                    } maximumValueLabel: {
                        EmptyView()
                    }
                    .tint(.blue)
                    Text("Large")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // Magnification Slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Magnification")
                    .font(.system(size: 13))
                HStack {
                    Text("Off")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Slider(value: $magnification) {
                        EmptyView()
                    } minimumValueLabel: {
                        EmptyView()
                    } maximumValueLabel: {
                        EmptyView()
                    }
                    .tint(.blue)
                    Text("Large")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // Position Picker
            HStack {
                Text("Position on screen")
                    .font(.system(size: 13))
                Spacer()
                Menu {
                    Picker("Position", selection: $position) {
                        ForEach(positions, id: \.self) { position in
                            Text(position).tag(position)
                        }
                    }
                } label: {
                    Text(position)
                        .frame(width: 100, alignment: .leading)
                }
                .modifier(CustomPickerStyle())
            }
            
            // Minimize Effect Picker
            HStack {
                Text("Minimize windows using")
                    .font(.system(size: 13))
                Spacer()
                Menu {
                    Picker("Minimize Effect", selection: $minimizeUsing) {
                        ForEach(minimizeEffects, id: \.self) { effect in
                            Text(effect).tag(effect)
                        }
                    }
                } label: {
                    Text(minimizeUsing)
                        .frame(width: 100, alignment: .leading)
                }
                .modifier(CustomPickerStyle())
            }
            
            // Double Click Action Picker
            HStack {
                Text("Double-click a window's title bar to")
                    .font(.system(size: 13))
                Spacer()
                Menu {
                    Picker("Double Click Action", selection: $doubleClickAction) {
                        ForEach(doubleClickActions, id: \.self) { action in
                            Text(action).tag(action)
                        }
                    }
                } label: {
                    Text(doubleClickAction)
                        .frame(width: 100, alignment: .leading)
                }
                .modifier(CustomPickerStyle())
            }
            
            // Toggle
            HStack {
                Text("Minimize windows into application icon")
                    .font(.system(size: 13))
                Spacer()
                Toggle("", isOn: $minimizeIntoIcon)
            }
        }
        .padding(20)
        .frame(width: 500)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    SystemSettingsView()
}
