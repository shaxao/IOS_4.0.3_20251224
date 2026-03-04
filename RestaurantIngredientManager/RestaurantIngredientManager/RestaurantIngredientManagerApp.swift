//
//  RestaurantIngredientManagerApp.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  餐厅食材管理系统 - 主应用入口
//

import SwiftUI

@main
struct RestaurantIngredientManagerApp: App {
    // Core Data持久化控制器
    @StateObject private var persistenceController = PersistenceController.shared
    
    // 应用生命周期管理器
    @StateObject private var lifecycleManager = AppLifecycleManager.shared
    
    // 错误处理器
    @StateObject private var errorHandler = ErrorHandler.shared
    
    // 打印机SDK管理器
    private let printerSDKManager = PrinterSDKManager.shared
    
    init() {
        // 初始化精臣打印机SDK
        printerSDKManager.initialize()
        
        // 配置应用外观
        configureAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(lifecycleManager)
                .environmentObject(errorHandler)
                .withErrorHandling()
        }
    }
    
    // MARK: - Private Methods
    
    private func configureAppearance() {
        // 配置导航栏外观
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // 配置TabBar外观
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
