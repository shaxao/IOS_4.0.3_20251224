# Services 模块

此目录包含应用程序的服务层实现。

## 已实现的服务

### ScannerService

相机集成服务，用于条形码和二维码扫描。

**功能：**
- 相机权限管理
- 基于AVFoundation的捕获会话
- 支持多种条形码格式（EAN8、EAN13、Code128、Code39等）
- 二维码识别
- 通过Combine实时发布扫描结果

**使用示例：**
```swift
let scanner = ScannerService.shared

// 请求权限
let granted = await scanner.requestCameraPermission()

// 开始扫描
try await scanner.startScanning()

// 订阅结果
scanner.scanResultPublisher
    .sink { result in
        print("扫描到: \(result.code) (\(result.type))")
    }
    .store(in: &cancellables)

// 停止扫描
scanner.stopScanning()
```

## 计划中的服务

- **CloudSyncService**: iCloud同步（可选功能）
- **NotificationService**: 食材过期本地通知

## 架构说明

- **Repository**: 负责数据持久化操作（Core Data），位于Core/Persistence/Repositories/
- **Service**: 负责业务逻辑和外部集成
- **Protocol-based**: 所有服务都定义协议接口，便于测试和依赖注入

## 指南

- 服务应尽可能无状态
- 使用async/await处理异步操作
- 实现适当的错误处理
- 服务可以依赖仓储，但不能依赖ViewModel
- 使用Combine发布者处理事件流
