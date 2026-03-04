//
//  MainTabView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  主导航标签视图
//

import SwiftUI

/// 主导航标签视图
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 食材标签页
            NavigationView {
                IngredientListView()
            }
            .tabItem {
                Label("食材", systemImage: "list.bullet.rectangle")
            }
            .tag(0)
            
            // 扫描标签页
            NavigationView {
                ScannerView()
            }
            .tabItem {
                Label("扫描", systemImage: "qrcode.viewfinder")
            }
            .tag(1)
            
            // 打印标签页
            NavigationView {
                PrinterConnectionView()
            }
            .tabItem {
                Label("打印", systemImage: "printer")
            }
            .tag(2)
            
            // 采购标签页
            NavigationView {
                PurchaseRecordView()
            }
            .tabItem {
                Label("采购", systemImage: "cart")
            }
            .tag(3)
            
            // 设置标签页
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("设置", systemImage: "gear")
            }
            .tag(4)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
}
