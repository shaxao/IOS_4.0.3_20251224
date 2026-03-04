//
//  PrinterStatus.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  打印机状态模型
//

import Foundation

/// 打印机状态模型
struct PrinterStatus: Equatable {
    /// 是否已连接
    var isConnected: Bool
    
    /// 纸张状态
    var paperStatus: PaperStatus
    
    /// 电池电量（0-100，可选）
    var batteryLevel: Int?
    
    /// 盖子状态
    var coverStatus: CoverStatus

    var lastErrorMessage: String?

    enum SyncState: String, Codable {
        case connected = "已连接"
        case disconnected = "未连接"
        case outOfPaper = "缺纸"
        case error = "报错"
    }
    
    /// 纸张状态枚举
    enum PaperStatus: String, Codable {
        case normal = "正常"
        case low = "纸张不足"
        case out = "缺纸"
    }
    
    /// 盖子状态枚举
    enum CoverStatus: String, Codable {
        case closed = "已关闭"
        case open = "打开"
    }
    
    /// 初始化默认状态（未连接）
    init() {
        self.isConnected = false
        self.paperStatus = .normal
        self.batteryLevel = nil
        self.coverStatus = .closed
        self.lastErrorMessage = nil
    }
    
    /// 初始化完整状态
    /// - Parameters:
    ///   - isConnected: 是否已连接
    ///   - paperStatus: 纸张状态
    ///   - batteryLevel: 电池电量
    ///   - coverStatus: 盖子状态
    init(isConnected: Bool, paperStatus: PaperStatus, batteryLevel: Int?, coverStatus: CoverStatus, lastErrorMessage: String? = nil) {
        self.isConnected = isConnected
        self.paperStatus = paperStatus
        self.batteryLevel = batteryLevel
        self.coverStatus = coverStatus
        self.lastErrorMessage = lastErrorMessage
    }

    var syncState: SyncState {
        if !isConnected {
            return .disconnected
        }
        if paperStatus == .out {
            return .outOfPaper
        }
        if coverStatus == .open || (lastErrorMessage?.isEmpty == false) {
            return .error
        }
        return .connected
    }
    
    /// 是否可以打印
    /// - Returns: 如果打印机状态允许打印则返回true
    func canPrint() -> Bool {
        return isConnected && coverStatus == .closed && paperStatus != .out
    }
    
    /// 获取警告信息
    /// - Returns: 警告信息数组
    func getWarnings() -> [String] {
        var warnings: [String] = []
        
        if !isConnected {
            warnings.append("打印机未连接")
        }
        
        if coverStatus == .open {
            warnings.append("打印机盖子打开")
        }
        
        if paperStatus == .out {
            warnings.append("打印机缺纸")
        } else if paperStatus == .low {
            warnings.append("打印机纸张不足")
        }
        
        if let battery = batteryLevel, battery < 20 {
            warnings.append("打印机电量低（\(battery)%）")
        }
        if let lastErrorMessage, !lastErrorMessage.isEmpty {
            warnings.append(lastErrorMessage)
        }
        
        return warnings
    }
}

// MARK: - Codable
extension PrinterStatus: Codable {
    enum CodingKeys: String, CodingKey {
        case isConnected, paperStatus, batteryLevel, coverStatus, lastErrorMessage
    }
}
