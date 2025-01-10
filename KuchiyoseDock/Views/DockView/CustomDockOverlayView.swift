
/*
 Display The container
 */
import SwiftUI

/// The main SwiftUI container for your custom dock overlay.
struct CustomDockOverlayView: View {
    @EnvironmentObject var dockObserver: DockObserver

    
    
    var body: some View {
        ZStack {
            // (FIX) Semi-transparent background
            VisualEffectView(material: .menu, blendingMode: .behindWindow)
                .cornerRadius(36)
                .overlay(
                    RoundedRectangle(cornerRadius: 36)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1) // 半透明白色边框
                )
            
            VStack(spacing: 12) {
                let apps = dockObserver.dockItems.filter { $0.isApp }
                if !apps.isEmpty {
                    HStack(spacing: 16) {
                        ForEach(apps) { item in
                            DockItemView(item: item, interactive: true)
                        }
                    }
                }
                
                let folders = dockObserver.dockItems.filter { $0.isFolder }
                if !folders.isEmpty {
                    HStack(spacing: 16) {
                        ForEach(folders) { item in
                            DockItemView(item: item, interactive: true)
                        }
                    }
                }
            }
            .padding(16)
        }
    }
}

private extension DockItem {
    var isApp: Bool {
        if case .app = self.type { return true }
        return false
    }
    var isFolder: Bool {
        if case .folder = self.type { return true }
        return false
    }
}
