//
//  NewUserGuideView.swift
//  AnoDock
//
//  Created by Qihang Yang on 5/9/25.
//
import SwiftUI


struct NewUserGuideView: View {
    @ObservedObject private var appsettings = AppSettings.shared
    @ObservedObject private var hotKeySettings = HotKeySettings.shared
    @State private var tabFromTrailing: Bool = false
    @State private var currentPage = 0
    @State private var functionPageIndex = 0
    var body: some View {
        VStack(spacing: 0) {
        
            HStack(alignment: .center) {
                Button {
                    if (currentPage == 1 && functionPageIndex > 0) {
                        withAnimation {
                            functionPageIndex -= 1
                        }
                    } else {
                        
                        tabFromTrailing = false
                        withAnimation(.spring) {
                            currentPage -= 1
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.largeTitle)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(currentPage > 0 ? 1 : 0)
                Spacer()
                Text("Welcome to AnoDock")
                    .font(.largeTitle.bold())
                Spacer()
                Button {
                    if (currentPage == 1 && functionPageIndex < 3) {
                        withAnimation {
                            functionPageIndex += 1
                        }
                    } else {
                        tabFromTrailing = true
                        withAnimation(.spring) {
                            currentPage += 1
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.largeTitle)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(currentPage < 2 ? 1 : 0)
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            ZStack {
                switch currentPage {
                case 0:
                    ShortcutIntroPage(hotKeySettings: hotKeySettings)
                        .transition(.push(from: tabFromTrailing ? .trailing : .leading))
                case 1:
                    ShowFunctionPage(innerIndex: $functionPageIndex)
                        .transition(.push(from: tabFromTrailing ? .trailing : .leading))
                case 2:
                    SettingsLocationPage(appsettings: appsettings)
                        .transition(.push(from: tabFromTrailing ? .trailing : .leading))
                default:
                    EmptyView()
                }
            }
            .frame(height: 350)

            Spacer()
        }
        .frame(width: 550, height: 500)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            appsettings.guideShown = true
        }
    }
}


struct ShortcutIntroPage: View {
    let hotKeySettings: HotKeySettings

    var body: some View {
        HStack(alignment: .center) {
            Spacer()

            VStack(spacing: 30) {


                

                Text("Press")
                    .font(.title.bold())
                    .padding(.top, 150)

                HStack(spacing: 8) {
                    ForEach(modifierSymbols(), id: \.self) { symbol in
                        ShortcutKeyView(symbol: symbol)
                    }
                    Text("+")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    ShortcutKeyView(symbol: keySymbol())
                }

                Text("to show or hide the dock.")
                    .font(.title3.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                Text("You can change them in settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }

            Spacer()
        }
    }

    private func modifierSymbols() -> [String] {
        var syms = [String]()
        if let mods = hotKeySettings.keyboardShortcut?.modifiers {
            if mods.contains(.command) { syms.append("⌘") }
            if mods.contains(.shift)   { syms.append("⇧") }
            if mods.contains(.option)  { syms.append("⌥") }
            if mods.contains(.control) { syms.append("⌃") }
        }
        return syms.isEmpty ? ["None"] : syms
    }

    private func keySymbol() -> String {
        guard let key = hotKeySettings.keyboardShortcut?.key else { return "?" }
        switch key {
        case .space:  return "Space"
        case .escape: return "Esc"
        case .delete: return "⌫"
        case .tab:    return "Tab"
        case .return: return "Return"
        default:      return String(key.character).uppercased()
        }
    }
}


struct ShowFunctionPage: View {

    @Binding var innerIndex: Int
    private let messages = [
        "Enter settings page here.",
        "You can add apps to the dock, running apps will be added to the 'recent' area automatically.",
        "If you want, you can hide dock automatically by moving your mouse out.",
        "You can drag the items in the dock to reorder, or remove."
    ]
    var imgname = [
        "where", "addnew", "hideauto"
    ]


    var body: some View {
        VStack {

            Spacer()
            if (innerIndex != 3) {
                Image(imgname[innerIndex])
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(20)
            }
            
            Text(messages[innerIndex])
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()

            HStack(spacing: 12) {
                ForEach(0..<messages.count, id: \.self) { idx in
                    Circle()
                        .frame(width: 8, height: 8)
                        .opacity(innerIndex == idx ? 1 : 0.3)
                        .onTapGesture {
                            withAnimation { innerIndex = idx }
                        }
                }
            }
            
        }
    }
}



struct SettingsLocationPage: View {
    @ObservedObject var appsettings: AppSettings

    var body: some View {
        VStack {

            Spacer()

            // 图标 + 文本 + 确认按钮
            VStack(spacing: 50) {

                Text("Have Fun!")
                    .font(.largeTitle.bold())
                    .padding(.top, 100)

                Button("I understand! Let me go!") {
                    appsettings.guideShown = true
                    DispatchQueue.main.async {
                        NSApplication.shared.keyWindow?.close()
                    }
                }
            }
            .padding(30)

            Spacer()
        }
    }
}


/// 快捷键样式组件
struct ShortcutKeyView: View {
    let symbol: String
    var body: some View {
        Text(symbol)
            .font(.title2.bold())
            .frame(minWidth: 40)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
    }
}

