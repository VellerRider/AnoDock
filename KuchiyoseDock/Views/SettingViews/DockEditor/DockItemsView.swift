//
//  AppsView.swift
//  KuchiyoseDock
//
//  Created by John Yang on 11/19/24.
//

import SwiftUI

struct DockItemsView: View {
    @EnvironmentObject var dockObserver: DockObserver

    var body: some View {
        VStack {
            if !applications.isEmpty {
                DockItemSectionView(title: "Applications", items: applications)
            }
            if !recentApplications.isEmpty {
                DockItemSectionView(title: "Recent Applications", items: recentApplications)
            }
            if !folders.isEmpty {
                DockItemSectionView(title: "Folders", items: folders)
            }
        }
    }

    private var applications: [DockItem] {
        dockObserver.dockItems.filter { $0.type == .application }
    }

    private var recentApplications: [DockItem] {
        dockObserver.recentApplications
    }

    private var folders: [DockItem] {
        dockObserver.dockItems.filter { $0.type == .folder }
    }
}
