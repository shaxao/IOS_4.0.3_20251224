//
//  PrinterViewModel.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  打印机视图模型
//

import Foundation
import Combine

/// 打印机视图模型
@MainActor
class PrinterViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 可用的打印机列表
    @Published private(set) var availablePrinters: [PrinterDevice] = []
    
    /// 当前连接的打印机
    @Published private(set) var connectedPrinter: PrinterDevice?
    
    /// 打印机状态
    @Published private(set) var printerStatus: PrinterStatus = PrinterStatus()
    
    /// 是否正在扫描
    @Published private(set) var isScanning: Bool = false
    
    /// 是否正在连接
    @Published private(set) var isConnecting: Bool = false
    
    /// 是否正在打印
    @Published private(set) var isPrinting: Bool = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 成功信息
    @Published var successMessage: String?
    
    /// 批量打印进度（0-1）
    @Published private(set) var batchPrintProgress: Double = 0
    
    // MARK: - Private Properties
    
    private let printerService: PrinterServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(printerService: PrinterServiceProtocol = PrinterService.shared) {
        self.printerService = printerService
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// 扫描蓝牙打印机
    func scanBluetoothPrinters() async {
        isScanning = true
        errorMessage = nil
        
        do {
            availablePrinters = try await printerService.scanForBluetoothPrinters()
            if availablePrinters.isEmpty {
                errorMessage = "未找到蓝牙打印机"
            }
        } catch {
            errorMessage = "扫描失败: \(error.localizedDescription)"
        }
        
        isScanning = false
    }
    
    /// 发现WiFi打印机
    func discoverWiFiPrinters(timeout: Float = 5.0) async {
        isScanning = true
        errorMessage = nil
        
        do {
            availablePrinters = try await printerService.discoverWiFiPrinters(timeout: timeout)
            if availablePrinters.isEmpty {
                errorMessage = "未找到WiFi打印机"
            }
        } catch {
            errorMessage = "发现失败: \(error.localizedDescription)"
        }
        
        isScanning = false
    }
    
    /// 连接到打印机
    func connect(to printer: PrinterDevice) async {
        isConnecting = true
        errorMessage = nil
        
        do {
            try await printerService.connect(to: printer)
            connectedPrinter = printer
            successMessage = "已连接到 \(printer.name)"
            
            // 连接后立即查询状态
            await refreshStatus()
        } catch {
            errorMessage = "连接失败: \(error.localizedDescription)"
        }
        
        isConnecting = false
    }
    
    /// 断开连接
    func disconnect() async {
        do {
            try await printerService.disconnect()
            connectedPrinter = nil
            printerStatus = PrinterStatus()
            successMessage = "已断开连接"
        } catch {
            errorMessage = "断开连接失败: \(error.localizedDescription)"
        }
    }
    
    /// 刷新打印机状态
    func refreshStatus() async {
        guard connectedPrinter != nil else { return }
        
        do {
            printerStatus = try await printerService.getPrinterStatus()
        } catch {
            errorMessage = "查询状态失败: \(error.localizedDescription)"
        }
    }
    
    /// 打印标签
    func printLabel(template: LabelTemplate, data: [String: String]) async -> Bool {
        guard connectedPrinter != nil else {
            errorMessage = "请先连接打印机"
            return false
        }
        
        isPrinting = true
        errorMessage = nil
        
        do {
            try await printerService.printLabel(template: template, data: data)
            successMessage = "打印成功"
            isPrinting = false
            return true
        } catch {
            errorMessage = "打印失败: \(error.localizedDescription)"
            isPrinting = false
            return false
        }
    }
    
    /// 批量打印标签
    func printBatch(labels: [(LabelTemplate, [String: String])]) async -> BatchPrintResult {
        guard connectedPrinter != nil else {
            errorMessage = "请先连接打印机"
            return BatchPrintResult(totalJobs: labels.count, successfulJobs: 0, failedJobs: [])
        }
        
        isPrinting = true
        errorMessage = nil
        batchPrintProgress = 0
        
        let result = try! await printerService.printBatch(labels: labels)
        
        batchPrintProgress = 1.0
        isPrinting = false
        
        if result.isAllSuccessful {
            successMessage = "批量打印完成：\(result.successfulJobs)/\(result.totalJobs)"
        } else {
            errorMessage = "批量打印完成，但有 \(result.failedJobs.count) 个失败"
        }
        
        return result
    }
    
    /// 打印食材标签
    func printIngredientLabel(_ ingredient: Ingredient, template: LabelTemplate) async -> Bool {
        let data: [String: String] = [
            "name": ingredient.name,
            "category": ingredient.category.rawValue,
            "quantity": "\(ingredient.quantity) \(ingredient.unit)",
            "expiryDate": ingredient.expirationDate.formatted(date: .abbreviated, time: .omitted),
            "barcode": ingredient.barcode ?? ingredient.id.uuidString,
            "qrData": ingredient.id.uuidString
        ]
        
        return await printLabel(template: template, data: data)
    }
    
    /// 批量打印食材标签
    func printIngredientLabels(_ ingredients: [Ingredient], template: LabelTemplate) async -> BatchPrintResult {
        let labels = ingredients.map { ingredient -> (LabelTemplate, [String: String]) in
            let data: [String: String] = [
                "name": ingredient.name,
                "category": ingredient.category.rawValue,
                "quantity": "\(ingredient.quantity) \(ingredient.unit)",
                "expiryDate": ingredient.expirationDate.formatted(date: .abbreviated, time: .omitted),
                "barcode": ingredient.barcode ?? ingredient.id.uuidString,
                "qrData": ingredient.id.uuidString
            ]
            return (template, data)
        }
        
        return await printBatch(labels: labels)
    }
    
    // MARK: - Private Methods
    
    /// 设置绑定
    private func setupBindings() {
        // 订阅打印机状态变化
        printerService.statusPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: &$printerStatus)
    }
}
