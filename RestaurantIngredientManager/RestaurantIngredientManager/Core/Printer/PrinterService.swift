//
//  PrinterService.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  打印机服务实现
//

import Foundation
import Combine

/// 打印机服务错误
enum PrinterServiceError: LocalizedError {
    case notInitialized
    case notConnected
    case scanFailed(String)
    case connectionFailed(String)
    case statusQueryFailed(String)
    case printFailed(String)
    case invalidTemplate
    case coverOpen
    case paperOut
    case lowBattery
    case printerBusy
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "打印机SDK未初始化"
        case .notConnected:
            return "打印机未连接"
        case .scanFailed(let message):
            return "扫描打印机失败: \(message)"
        case .connectionFailed(let message):
            return "连接打印机失败: \(message)"
        case .statusQueryFailed(let message):
            return "查询打印机状态失败: \(message)"
        case .printFailed(let message):
            return "打印失败: \(message)"
        case .invalidTemplate:
            return "无效的标签模板"
        case .coverOpen:
            return "打印机盖子打开，请关闭后重试"
        case .paperOut:
            return "打印机缺纸，请添加纸张"
        case .lowBattery:
            return "打印机电量不足"
        case .printerBusy:
            return "打印机忙碌中"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
}

/// 打印机服务实现
@MainActor
class PrinterService: PrinterServiceProtocol {
    // MARK: - Properties
    
    /// 共享实例
    static let shared = PrinterService()
    
    /// 当前连接的打印机
    private(set) var connectedPrinter: PrinterDevice?
    
    /// 当前打印机状态
    private(set) var currentStatus: PrinterStatus = PrinterStatus()
    
    /// 状态主题
    private let statusSubject = CurrentValueSubject<PrinterStatus, Never>(PrinterStatus())
    
    /// 打印机状态发布者
    var statusPublisher: AnyPublisher<PrinterStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    /// 是否正在监听状态变化
    private var isMonitoringStatus = false
    
    // MARK: - Initialization
    
    private init() {
        // 确保SDK已初始化
        PrinterSDKManager.shared.initialize()
    }
    
    // MARK: - Public Methods
    
    /// 扫描蓝牙打印机
    func scanForBluetoothPrinters() async throws -> [PrinterDevice] {
        guard PrinterSDKManager.shared.isInitialized else {
            throw PrinterServiceError.notInitialized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            JCAPI.scanBluetoothPrinter { printerNames in
                guard let names = printerNames as? [String] else {
                    continuation.resume(throwing: PrinterServiceError.scanFailed("无效的扫描结果"))
                    return
                }
                
                let devices = names.map { name in
                    PrinterDevice(bluetoothName: name)
                }
                
                continuation.resume(returning: devices)
            }
        }
    }
    
    /// 发现WiFi打印机
    func discoverWiFiPrinters(timeout: Float = 5.0) async throws -> [PrinterDevice] {
        guard PrinterSDKManager.shared.isInitialized else {
            throw PrinterServiceError.notInitialized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            JCAPI.scanWifiPrinter(timeout) { printerInfos in
                guard let infos = printerInfos as? [[String: Any]] else {
                    continuation.resume(throwing: PrinterServiceError.scanFailed("无效的扫描结果"))
                    return
                }
                
                let devices = infos.compactMap { info -> PrinterDevice? in
                    guard let ipAddress = info["ipAdd"] as? String,
                          let name = info["bleName"] as? String else {
                        return nil
                    }
                    
                    let port = info["port"] as? UInt16
                    return PrinterDevice(wifiName: name, ipAddress: ipAddress, port: port)
                }
                
                continuation.resume(returning: devices)
            }
        }
    }
    
    /// 连接到打印机
    func connect(to printer: PrinterDevice) async throws {
        guard PrinterSDKManager.shared.isInitialized else {
            throw PrinterServiceError.notInitialized
        }
        
        let success = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            switch printer.connectionType {
            case .bluetooth:
                JCAPI.openPrinter(printer.name) { isSuccess in
                    continuation.resume(returning: isSuccess)
                }
                
            case .wifi:
                guard let ipAddress = printer.ipAddress else {
                    continuation.resume(throwing: PrinterServiceError.connectionFailed("WiFi打印机缺少IP地址"))
                    return
                }
                
                if let port = printer.port {
                    JCAPI.openPrinterHost(ipAddress, port: port) { isSuccess in
                        continuation.resume(returning: isSuccess)
                    }
                } else {
                    JCAPI.openPrinterHost(ipAddress) { isSuccess in
                        continuation.resume(returning: isSuccess)
                    }
                }
            }
        }
        
        if success {
            connectedPrinter = printer
            currentStatus.isConnected = true
            statusSubject.send(currentStatus)
            
            // 开始监听状态变化
            startMonitoringStatus()
            
            // 查询初始状态
            try? await getPrinterStatus()
        } else {
            throw PrinterServiceError.connectionFailed("连接失败")
        }
    }
    
    /// 断开当前打印机连接
    func disconnect() async throws {
        JCAPI.closePrinter()
        
        connectedPrinter = nil
        currentStatus = PrinterStatus()
        statusSubject.send(currentStatus)
        isMonitoringStatus = false
    }
    
    /// 获取打印机状态
    func getPrinterStatus() async throws -> PrinterStatus {
        guard connectedPrinter != nil else {
            throw PrinterServiceError.notConnected
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let supported = JCAPI.getPrintStatusChange { statusInfo in
                guard let info = statusInfo as? [String: Any] else {
                    continuation.resume(throwing: PrinterServiceError.statusQueryFailed("无效的状态信息"))
                    return
                }
                
                var status = PrinterStatus()
                status.isConnected = true
                
                // 解析盖子状态 (0=打开, 1=关闭)
                if let coverValue = info["1"] as? String, let coverInt = Int(coverValue) {
                    status.coverStatus = coverInt == 1 ? .closed : .open
                }
                
                // 解析电量等级 (1-4)
                if let batteryValue = info["2"] as? String, let batteryLevel = Int(batteryValue) {
                    // 将1-4转换为百分比
                    status.batteryLevel = batteryLevel * 25
                }
                
                // 解析纸张状态 (0=没有, 1=有)
                if let paperValue = info["3"] as? String, let paperInt = Int(paperValue) {
                    status.paperStatus = paperInt == 1 ? .normal : .out
                }
                
                self.currentStatus = status
                self.statusSubject.send(status)
                
                continuation.resume(returning: status)
            }
            
            if !supported {
                continuation.resume(throwing: PrinterServiceError.statusQueryFailed("打印机不支持状态查询"))
            }
        }
    }
    
    /// 打印标签
    func printLabel(template: LabelTemplate, data: [String: String]) async throws {
        guard connectedPrinter != nil else {
            throw PrinterServiceError.notConnected
        }
        
        // 检查打印机状态
        let status = try await getPrinterStatus()
        if !status.canPrint() {
            if status.coverStatus == .open {
                throw PrinterServiceError.coverOpen
            }
            if status.paperStatus == .out {
                throw PrinterServiceError.paperOut
            }
        }
        
        // 初始化绘制画板
        JCAPI.initDrawingBoard(
            Float(template.width),
            withHeight: Float(template.height),
            withHorizontalShift: 0,
            withVerticalShift: 0,
            rotate: 0,
            fontArray: []
        )
        
        // 绘制模板元素
        for element in template.elements {
            try drawElement(element, data: data)
        }
        
        // 生成打印JSON
        guard let printJson = JCAPI.generateLableJson() else {
            throw PrinterServiceError.printFailed("生成打印数据失败")
        }
        
        // 设置打印份数
        JCAPI.setTotalQuantityOfPrints(1)
        
        // 开始打印任务
        let printSuccess = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            // 设置错误监听
            JCAPI.getPrintingErrorInfo { errorCode in
                if let code = errorCode, !code.isEmpty {
                    let errorMessage = self.parseErrorCode(code)
                    continuation.resume(throwing: PrinterServiceError.printFailed(errorMessage))
                }
            }
            
            // 开始打印作业
            JCAPI.startJob(3, withPaperStyle: 1) { success in
                if success {
                    // 提交打印数据
                    JCAPI.commit(printJson, withOnePageNumbers: 1) { commitSuccess in
                        if commitSuccess {
                            // 结束打印
                            JCAPI.endPrint { endSuccess in
                                continuation.resume(returning: endSuccess)
                            }
                        } else {
                            continuation.resume(returning: false)
                        }
                    }
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
        
        if !printSuccess {
            throw PrinterServiceError.printFailed("打印失败")
        }
    }
    
    /// 批量打印标签
    func printBatch(labels: [(LabelTemplate, [String: String])]) async throws -> BatchPrintResult {
        var successCount = 0
        var failedJobs: [(index: Int, error: Error)] = []
        
        for (index, label) in labels.enumerated() {
            do {
                try await printLabel(template: label.0, data: label.1)
                successCount += 1
            } catch {
                failedJobs.append((index: index, error: error))
            }
        }
        
        return BatchPrintResult(
            totalJobs: labels.count,
            successfulJobs: successCount,
            failedJobs: failedJobs
        )
    }
    
    // MARK: - Private Methods
    
    /// 开始监听打印机状态变化
    private func startMonitoringStatus() {
        guard !isMonitoringStatus else { return }
        isMonitoringStatus = true
        
        // 持续监听状态变化
        Task {
            while isMonitoringStatus && connectedPrinter != nil {
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 每2秒查询一次
                try? await getPrinterStatus()
            }
        }
    }
    
    /// 绘制模板元素
    private func drawElement(_ element: LabelTemplate.LabelElement, data: [String: String]) throws {
        let x = Float(element.x)
        let y = Float(element.y)
        let width = Float(element.width)
        let height = Float(element.height)
        
        switch element.type {
        case .text:
            guard let content = element.content, let dataValue = data[content] else {
                return
            }
            let fontSize = Float(element.fontSize ?? 12)
            JCAPI.drawLableText(
                x, withY: y,
                withWidth: width, withHeight: height,
                with: dataValue,
                withFontFamily: "ZT001",
                withFontSize: fontSize,
                withRotate: 0,
                withTextAlignHorizonral: 0,
                withTextAlignVertical: 0,
                withLineMode: 0,
                withLetterSpacing: 0,
                withLineSpacing: 0,
                withFontStyle: [0, 0, 0, 0]
            )
            
        case .qrCode:
            guard let content = element.content, let dataValue = data[content] else {
                return
            }
            JCAPI.drawLableQrCode(
                x, withY: y,
                withWidth: width, withHeight: height,
                with: dataValue,
                withRotate: 0,
                withCodeType: 31 // QR_CODE
            )
            
        case .barcode:
            guard let content = element.content, let dataValue = data[content] else {
                return
            }
            let fontSize = Float(element.fontSize ?? 3)
            JCAPI.drawLableBarCode(
                x, withY: y,
                withWidth: width, withHeight: height,
                with: dataValue,
                withFontSize: fontSize,
                withRotate: 0,
                withCodeType: 20, // CODE128
                withTextHeight: 5,
                withTextPosition: 0
            )
            
        case .line:
            JCAPI.drawLableLine(
                x, withY: y,
                withWidth: width, withHeight: height,
                withRotate: 0,
                withLineType: 1, // 实线
                withDashWidth: nil
            )
            
        case .rectangle:
            JCAPI.drawLableGraph(
                x, withY: y,
                withWidth: width, withHeight: height,
                withLineWidth: 1,
                withCornerRadius: 0,
                withRotate: 0,
                withGraphType: 3,
                withLineType: 1,
                withDashWidth: nil
            )
        }
    }
    
    /// 解析错误代码
    private func parseErrorCode(_ code: String) -> String {
        switch code {
        case "1": return "盒盖打开"
        case "2": return "缺纸"
        case "3": return "电量不足"
        case "4": return "电池异常"
        case "5": return "手动停止"
        case "6": return "数据错误"
        case "7": return "温度过高"
        case "8": return "出纸异常"
        case "9": return "打印忙碌"
        case "10": return "没有检测到打印头"
        case "11": return "环境温度过低"
        case "12": return "打印头未锁紧"
        case "13": return "未检测到碳带"
        case "14": return "不匹配的碳带"
        case "15": return "用完的碳带"
        case "16": return "不支持的纸张类型"
        case "17": return "设置纸张失败"
        case "18": return "设置打印模式失败"
        case "19": return "设置打印浓度失败"
        case "20": return "写入RFID失败"
        case "21": return "边距设置错误"
        case "22": return "通讯异常"
        case "23": return "打印机断开"
        default: return "未知错误（代码：\(code)）"
        }
    }
}
