//
//  PrinterSDKManager.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  精臣打印机SDK管理器
//

import Foundation

/// 精臣打印机SDK管理器
/// 负责初始化和管理精臣JCAPI框架
class PrinterSDKManager {
    /// 共享实例
    static let shared = PrinterSDKManager()
    
    /// 是否已初始化
    private(set) var isInitialized = false
    
    private init() {}
    
    /// 初始化精臣打印机SDK
    func initialize() {
        guard !isInitialized else {
            print("精臣打印机SDK已经初始化")
            return
        }
        
        // TODO: 在后续任务中集成实际的JCAPI框架
        // JCManager.shared().initSDK()
        
        isInitialized = true
        print("精臣打印机SDK初始化成功")
    }
}
