//
//  ScannerViewModel.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  扫描视图模型
//

import Foundation
import AVFoundation
import Combine

/// 扫描视图模型
@MainActor
class ScannerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 是否正在扫描
    @Published private(set) var isScanning: Bool = false
    
    /// 相机权限状态
    @Published private(set) var permissionStatus: AVAuthorizationStatus = .notDetermined
    
    /// 最后扫描的结果
    @Published private(set) var lastScanResult: ScanResult?
    
    /// 找到的食材（如果存在）
    @Published private(set) var foundIngredient: Ingredient?
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 是否显示权限提示
    @Published var showPermissionAlert: Bool = false
    
    /// 扫描提示文本
    @Published var scanPrompt: String = "将条形码或二维码对准扫描框"
    
    // MARK: - Private Properties
    
    private let scannerService: ScannerService
    private let ingredientRepository: IngredientRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// 预览层
    var previewLayer: AVCaptureVideoPreviewLayer? {
        scannerService.previewLayer
    }
    
    // MARK: - Initialization
    
    init(
        scannerService: ScannerService = ScannerService.shared,
        ingredientRepository: IngredientRepository = IngredientRepository.shared
    ) {
        self.scannerService = scannerService
        self.ingredientRepository = ingredientRepository
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// 请求相机权限
    func requestPermission() async {
        let granted = await scannerService.requestCameraPermission()
        permissionStatus = scannerService.permissionStatus
        
        if !granted {
            showPermissionAlert = true
            errorMessage = "需要相机权限才能扫描条形码"
        }
    }
    
    /// 开始扫描
    func startScanning() async {
        errorMessage = nil
        
        do {
            try await scannerService.startScanning()
            isScanning = true
            scanPrompt = "将条形码或二维码对准扫描框"
        } catch ScannerServiceError.permissionDenied {
            showPermissionAlert = true
            errorMessage = "需要相机权限才能扫描"
        } catch {
            errorMessage = "启动扫描失败: \(error.localizedDescription)"
        }
    }
    
    /// 停止扫描
    func stopScanning() {
        scannerService.stopScanning()
        isScanning = false
    }
    
    /// 处理扫描结果
    func handleScanResult(_ result: ScanResult) async {
        lastScanResult = result
        
        // 尝试查找食材
        await findIngredient(by: result.code)
        
        // 暂停扫描以显示结果
        stopScanning()
    }
    
    /// 通过条形码或ID查找食材
    func findIngredient(by code: String) async {
        do {
            // 先尝试通过条形码查找
            let ingredients = try await ingredientRepository.search(query: code)
            
            if let ingredient = ingredients.first(where: { $0.barcode == code }) {
                foundIngredient = ingredient
                scanPrompt = "找到食材: \(ingredient.name)"
                return
            }
            
            // 如果是UUID格式，尝试通过ID查找
            if let uuid = UUID(uuidString: code) {
                if let ingredient = try await ingredientRepository.fetch(by: uuid) {
                    foundIngredient = ingredient
                    scanPrompt = "找到食材: \(ingredient.name)"
                    return
                }
            }
            
            // 未找到
            foundIngredient = nil
            scanPrompt = "未找到匹配的食材"
        } catch {
            errorMessage = "查找食材失败: \(error.localizedDescription)"
            foundIngredient = nil
        }
    }
    
    /// 重置扫描
    func reset() {
        lastScanResult = nil
        foundIngredient = nil
        errorMessage = nil
        scanPrompt = "将条形码或二维码对准扫描框"
    }
    
    /// 清理资源
    func cleanup() {
        stopScanning()
        scannerService.cleanup()
    }
    
    // MARK: - Private Methods
    
    /// 设置绑定
    private func setupBindings() {
        // 订阅扫描结果
        scannerService.scanResultPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                Task { @MainActor in
                    await self?.handleScanResult(result)
                }
            }
            .store(in: &cancellables)
        
        // 订阅扫描状态
        scannerService.$isScanning
            .receive(on: DispatchQueue.main)
            .assign(to: &$isScanning)
        
        // 订阅权限状态
        scannerService.$permissionStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$permissionStatus)
    }
}
