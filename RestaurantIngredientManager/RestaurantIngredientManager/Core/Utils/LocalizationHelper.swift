//
//  LocalizationHelper.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  本地化辅助工具
//

import Foundation

/// 本地化辅助类
/// 提供便捷的本地化字符串访问方法
struct LocalizationHelper {
    /// 获取本地化字符串
    /// - Parameters:
    ///   - key: 本地化键
    ///   - comment: 注释（可选）
    /// - Returns: 本地化后的字符串
    static func localized(_ key: String, comment: String = "") -> String {
        return NSLocalizedString(key, comment: comment)
    }
    
    /// 当前语言代码
    static var currentLanguageCode: String {
        return Locale.current.languageCode ?? "zh-Hans"
    }
    
    /// 是否为中文环境
    static var isChinese: Bool {
        return currentLanguageCode.hasPrefix("zh")
    }
}

// MARK: - String Extension

extension String {
    /// 本地化字符串
    var localized: String {
        return LocalizationHelper.localized(self)
    }
    
    /// 带参数的本地化字符串
    /// - Parameter arguments: 参数列表
    /// - Returns: 格式化后的本地化字符串
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}
