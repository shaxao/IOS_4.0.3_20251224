//
//  AppLifecycleManager.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  应用生命周期管理
//

import Foundation
import SwiftUI
import Combine

/// 应用生命周期管理器
@MainActor
class AppLifecycleManager: ObservableObject {
    /// 共享实例
    static let shared = AppLifecycleManager()
    
    /// 应用状态
    @Published var appState: AppState = .active
    
    /// 是否需要保存数据
    @Published var needsSave = false
    
    private var cancellables = Set<AnyCancellable>()
    private let persistenceController = PersistenceController.shared
    
    /// 应用状态枚举
    enum AppState {
        case active
        case inactive
        case background
    }
    
    private init() {
        setupNotifications()
    }
    
    /// 设置通知监听
    private func setupNotifications() {
        // 应用进入后台
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.appState = .background
                    await self?.handleEnterBackground()
                }
            }
            .store(in: &cancellables)
        
        // 应用将要终止
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleWillTerminate()
                }
            }
            .store(in: &cancellables)
        
        // 应用变为活跃
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.appState = .active
                    await self?.handleBecomeActive()
                }
            }
            .store(in: &cancellables)
        
        // 应用将要失去活跃状态
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.appState = .inactive
                }
            }
            .store(in: &cancellables)
    }
    
    /// 处理进入后台
    private func handleEnterBackground() async {
        print("📱 App entering background")
        
        // 保存Core Data上下文
        await saveContext()
        
        // 清理资源
        cleanupResources()
    }
    
    /// 处理应用终止
    private func handleWillTerminate() async {
        print("📱 App will terminate")
        
        // 最后一次保存
        await saveContext()
    }
    
    /// 处理变为活跃
    private func handleBecomeActive() async {
        print("📱 App became active")
        
        // 可以在这里刷新数据
    }
    
    /// 保存Core Data上下文
    private func saveContext() async {
        do {
            try await persistenceController.save()
            print("✅ Context saved successfully")
        } catch {
            print("❌ Failed to save context: \(error)")
        }
    }
    
    /// 清理资源
    private func cleanupResources() {
        // 清理扫描服务
        ScannerService.shared.cleanup()
        
        // 可以添加其他资源清理
        print("🧹 Resources cleaned up")
    }
    
    /// 标记需要保存
    func markNeedsSave() {
        needsSave = true
    }
}
