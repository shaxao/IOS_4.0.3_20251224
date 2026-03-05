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

        let fm = FileManager.default
        let documents = fm.urls(for: .documentDirectory, in: .userDomainMask).first
        let fontDirectory = documents?.appendingPathComponent("font", isDirectory: true)
        if let fontDirectory {
            try? fm.createDirectory(at: fontDirectory, withIntermediateDirectories: true)
            if let bundleFont1 = Bundle.main.url(forResource: "ZT001", withExtension: "ttf") {
                let target = fontDirectory.appendingPathComponent("ZT001.ttf")
                if !fm.fileExists(atPath: target.path) {
                    try? fm.copyItem(at: bundleFont1, to: target)
                }
            }
            if let bundleFont2 = Bundle.main.url(forResource: "ZT002", withExtension: "otf") {
                let target = fontDirectory.appendingPathComponent("ZT002.otf")
                if !fm.fileExists(atPath: target.path) {
                    try? fm.copyItem(at: bundleFont2, to: target)
                }
            }
            var error: NSError?
            JCAPI.initImageProcessing(fontDirectory.path, error: &error)
            if let error {
                print("精臣打印字体初始化失败: \(error.localizedDescription)")
            }
        }
        
        isInitialized = true
        print("精臣打印机SDK初始化成功")
    }
}
