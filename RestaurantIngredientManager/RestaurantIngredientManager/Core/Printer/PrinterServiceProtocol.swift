//
//  PrinterServiceProtocol.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  打印机服务协议
//

import Foundation
import Combine

/// 打印机服务协议
protocol PrinterServiceProtocol {
    /// 当前连接的打印机
    var connectedPrinter: PrinterDevice? { get }
    
    /// 当前打印机状态
    var currentStatus: PrinterStatus { get }
    
    /// 打印机状态发布者
    var statusPublisher: AnyPublisher<PrinterStatus, Never> { get }
    
    /// 扫描蓝牙打印机
    /// - Returns: 扫描到的打印机设备数组
    func scanForBluetoothPrinters() async throws -> [PrinterDevice]
    
    /// 发现WiFi打印机
    /// - Parameter timeout: 扫描超时时间（秒），默认5秒
    /// - Returns: 发现的打印机设备数组
    func discoverWiFiPrinters(timeout: Float) async throws -> [PrinterDevice]
    
    /// 连接到打印机
    /// - Parameter printer: 要连接的打印机设备
    func connect(to printer: PrinterDevice) async throws
    
    /// 断开当前打印机连接
    func disconnect() async throws
    
    /// 获取打印机状态
    /// - Returns: 当前打印机状态
    func getPrinterStatus() async throws -> PrinterStatus
    
    /// 打印标签
    /// - Parameters:
    ///   - template: 标签模板
    ///   - data: 标签数据字典
    func printLabel(template: LabelTemplate, data: [String: String]) async throws
    
    /// 批量打印标签
    /// - Parameter labels: 标签数组，每个元素包含模板和数据
    /// - Returns: 批量打印结果
    func printBatch(labels: [(LabelTemplate, [String: String])]) async throws -> BatchPrintResult
}

/// 批量打印结果
struct BatchPrintResult {
    /// 总任务数
    let totalJobs: Int
    
    /// 成功任务数
    let successfulJobs: Int
    
    /// 失败任务数组（索引和错误）
    let failedJobs: [(index: Int, error: Error)]
    
    /// 是否全部成功
    var isAllSuccessful: Bool {
        return failedJobs.isEmpty
    }
    
    /// 成功率
    var successRate: Double {
        guard totalJobs > 0 else { return 0 }
        return Double(successfulJobs) / Double(totalJobs)
    }
}
