
/*
 Display The container
 */
import SwiftUI

/// The main SwiftUI container for your custom dock overlay.
struct CustomDockOverlayView: View {
    @EnvironmentObject var dockObserver: DockObserver

    
    
    var body: some View {
        ZStack {
            VisualEffectView(material: .menu, blendingMode: .behindWindow)
                .cornerRadius(36)
                .overlay(
                    RoundedRectangle(cornerRadius: 36)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1) // 半透明白色边框
                )
            
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    ForEach(Array(dockObserver.dockAppOrderKeys.enumerated()), id: \.element) { (index, key) in
                        if let app = dockObserver.dockApps[key] {
                            DockItemView(item: app, interactive: true)
                        }
                    }
                }
                
                HStack(spacing: 8) {
                    ForEach(dockObserver.recentApps) { app in
                        DockItemView(item: app, interactive: true)
                    }
                }
                
            }
            .padding(8)
        }

        .fixedSize()

    }
}
