//
//  ContentView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//

import SwiftUI

struct ContentView: View {
    @AppStorage("ui.debug.topBanner.enabled") private var isTopBannerEnabled = false

    var body: some View {
        MainTabView()
            .overlay(alignment: .top) {
                if isTopBannerEnabled {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 0)
                }
            }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
