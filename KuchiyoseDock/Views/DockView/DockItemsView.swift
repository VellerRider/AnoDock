//
//  AppsView.swift
//  KuchiyoseDock
//  Grouping items when summoning dock.
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
        dockObserver.dockItems.filter {
            if case .app = $0.type {
                return true
            }
            return false
        }
    }

    private var recentApplications: [DockItem] {
        // TODO: - implement recent applications using maybe NSWorkspace?
        // 假设 dockObserver 有一个属性 recentApplications: [DockItem]
        // 并且由 dockObserver 根据用户操作和历史记录维护
        return dockObserver.recentApplications
    }

    private var folders: [DockItem] {
        dockObserver.dockItems.filter {
            if case .folder = $0.type {
                return true
            }
            return false
        }
    }
}
