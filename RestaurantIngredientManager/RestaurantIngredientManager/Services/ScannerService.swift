//
//  ScannerService.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  扫描服务实现
//

import Foundation
import AVFoundation
import Combine

/// 扫描服务错误
enum ScannerServiceError: LocalizedError {
    case cameraNotAvailable
    case permissionDenied
    case sessionConfigurationFailed
    case invalidCode
    
    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "相机不可用"
        case .permissionDenied:
            return "相机权限被拒绝"
        case .sessionConfigurationFailed:
            return "相机配置失败"
        case .invalidCode:
            return "无效的条形码或二维码"
        }
    }
}

/// 扫描结果
struct ScanResult: Equatable {
    /// 扫描的代码内容
    let code: String
    
    /// 代码类型
    let type: CodeType
    
    /// 扫描时间
    let timestamp: Date
    
    /// 代码类型枚举
    enum CodeType: String {
        case qrCode = "二维码"
        case barcode = "条形码"
        case unknown = "未知"
    }
}

/// 扫描服务实现
@MainActor
class ScannerService: NSObject, ObservableObject {
    // MARK: - Properties
    
    /// 共享实例
    static let shared = ScannerService()
    
    /// 相机捕获会话
    private var captureSession: AVCaptureSession?
    
    /// 视频预览层
    private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    
    /// 扫描结果发布者
    private let scanResultSubject = PassthroughSubject<ScanResult, Never>()
    var scanResultPublisher: AnyPublisher<ScanResult, Never> {
        scanResultSubject.eraseToAnyPublisher()
    }
    
    /// 是否正在扫描
    @Published private(set) var isScanning = false
    
    /// 相机权限状态
    @Published private(set) var permissionStatus: AVAuthorizationStatus = .notDetermined
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        updatePermissionStatus()
    }
    
    // MARK: - Public Methods
    
    /// 请求相机权限
    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            await MainActor.run {
                permissionStatus = .authorized
            }
            return true
            
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                permissionStatus = granted ? .authorized : .denied
            }
            return granted
            
        case .denied, .restricted:
            await MainActor.run {
                permissionStatus = status
            }
            return false
            
        @unknown default:
            return false
        }
    }
    
    /// 配置相机捕获会话
    func setupCaptureSession() throws {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            throw ScannerServiceError.permissionDenied
        }
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            throw ScannerServiceError.cameraNotAvailable
        }
        
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            throw ScannerServiceError.sessionConfigurationFailed
        }
        
        let session = AVCaptureSession()
        
        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        } else {
            throw ScannerServiceError.sessionConfigurationFailed
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
            // 支持的代码类型
            metadataOutput.metadataObjectTypes = [
                .qr,
                .ean8,
                .ean13,
                .code128,
                .code39,
                .code93,
                .upce,
                .pdf417,
                .aztec
            ]
        } else {
            throw ScannerServiceError.sessionConfigurationFailed
        }
        
        // 创建预览层
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        
        captureSession = session
        previewLayer = preview
    }
    
    /// 开始扫描
    func startScanning() async throws {
        guard !isScanning else { return }
        
        // 确保有权限
        let hasPermission = await requestCameraPermission()
        guard hasPermission else {
            throw ScannerServiceError.permissionDenied
        }
        
        // 如果会话未配置，先配置
        if captureSession == nil {
            try setupCaptureSession()
        }
        
        guard let session = captureSession else {
            throw ScannerServiceError.sessionConfigurationFailed
        }
        
        // 在后台线程启动会话
        Task.detached {
            session.startRunning()
        }
        
        isScanning = true
    }
    
    /// 停止扫描
    func stopScanning() {
        guard isScanning else { return }
        
        captureSession?.stopRunning()
        isScanning = false
    }
    
    /// 清理资源
    func cleanup() {
        stopScanning()
        captureSession = nil
        previewLayer = nil
    }
    
    // MARK: - Private Methods
    
    /// 更新权限状态
    private func updatePermissionStatus() {
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }
    
    /// 解析代码类型
    private func parseCodeType(_ metadataType: AVMetadataObject.ObjectType) -> ScanResult.CodeType {
        switch metadataType {
        case .qr:
            return .qrCode
        case .ean8, .ean13, .code128, .code39, .code93, .upce, .pdf417, .aztec:
            return .barcode
        default:
            return .unknown
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension ScannerService: AVCaptureMetadataOutputObjectsDelegate {
    nonisolated func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }
        
        let codeType = parseCodeType(readableObject.type)
        let result = ScanResult(
            code: stringValue,
            type: codeType,
            timestamp: Date()
        )
        
        // 在主线程发布结果
        Task { @MainActor in
            scanResultSubject.send(result)
        }
    }
}
