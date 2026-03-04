//
//  DateFormatter+Extensions.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  日期格式化扩展
//

import Foundation

extension DateFormatter {
    /// 标准日期格式化器（yyyy-MM-dd）
    static let standardDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale.current
        return formatter
    }()
    
    /// 完整日期时间格式化器（yyyy-MM-dd HH:mm:ss）
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale.current
        return formatter
    }()
    
    /// 短日期格式化器（根据用户区域设置）
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()
    
    /// 中等日期格式化器（根据用户区域设置）
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()
}

extension Date {
    /// 格式化为标准日期字符串
    var standardDateString: String {
        return DateFormatter.standardDate.string(from: self)
    }
    
    /// 格式化为完整日期时间字符串
    var fullDateTimeString: String {
        return DateFormatter.fullDateTime.string(from: self)
    }
    
    /// 格式化为短日期字符串
    var shortDateString: String {
        return DateFormatter.shortDate.string(from: self)
    }
    
    /// 格式化为中等日期字符串
    var mediumDateString: String {
        return DateFormatter.mediumDate.string(from: self)
    }
    
    /// 计算距离当前日期的天数
    var daysFromNow: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: self)
        return components.day ?? 0
    }
    
    /// 是否已过期
    var isExpired: Bool {
        return self < Date()
    }
    
    /// 是否即将过期（在指定天数内）
    /// - Parameter days: 天数阈值
    /// - Returns: 是否即将过期
    func isExpiringSoon(within days: Int) -> Bool {
        let daysRemaining = self.daysFromNow
        return daysRemaining >= 0 && daysRemaining <= days
    }
}
