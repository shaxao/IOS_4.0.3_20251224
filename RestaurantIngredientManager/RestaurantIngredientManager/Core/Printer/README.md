# 打印机服务模块

本模块封装了精臣JCAPI框架（v4.0.3），提供标签打印机的连接、状态监控和打印功能。

## 文件结构

```
Printer/
├── PrinterSDKManager.swift          # SDK初始化管理器
├── PrinterDevice.swift               # 打印机设备模型
├── PrinterStatus.swift               # 打印机状态模型
├── PrinterServiceProtocol.swift      # 打印机服务协议
├── PrinterService.swift              # 打印机服务实现
└── README.md                         # 本文档
```

## 核心组件

### 1. PrinterSDKManager

负责初始化精臣JCAPI框架。

```swift
// 初始化SDK（应用启动时调用）
PrinterSDKManager.shared.initialize()
```

### 2. PrinterDevice

表示打印机设备的模型，支持蓝牙和WiFi两种连接类型。

```swift
// 创建蓝牙打印机设备
let bluetoothPrinter = PrinterDevice(bluetoothName: "JC-B3S-1234")

// 创建WiFi打印机设备
let wifiPrinter = PrinterDevice(
    wifiName: "JC-Printer", 
    ipAddress: "192.168.1.100", 
    port: 9100
)
```

### 3. PrinterStatus

表示打印机当前状态，包括连接状态、纸张状态、电池电量和盖子状态。

```swift
let status = printerService.currentStatus

// 检查是否可以打印
if status.canPrint() {
    // 执行打印
} else {
    // 显示警告
    let warnings = status.getWarnings()
    print(warnings)
}
```

### 4. PrinterService

主要的打印机服务实现，提供以下功能：

#### 扫描打印机

```swift
// 扫描蓝牙打印机
let bluetoothPrinters = try await printerService.scanForBluetoothPrinters()

// 发现WiFi打印机（5秒超时）
let wifiPrinters = try await printerService.discoverWiFiPrinters(timeout: 5.0)
```

#### 连接打印机

```swift
// 连接到打印机
try await printerService.connect(to: printer)

// 断开连接
try await printerService.disconnect()
```

#### 监控状态

```swift
// 获取当前状态
let status = try await printerService.getPrinterStatus()

// 订阅状态变化
printerService.statusPublisher
    .sink { status in
        print("打印机状态更新: \(status)")
    }
    .store(in: &cancellables)
```

#### 打印标签

```swift
// 单个标签打印
let template = LabelTemplate(
    name: "食材标签",
    width: 50,
    height: 30,
    elements: [
        LabelTemplate.LabelElement(
            type: .text,
            x: 5, y: 5,
            width: 40, height: 10,
            fontSize: 12,
            content: "name"
        ),
        LabelTemplate.LabelElement(
            type: .qrCode,
            x: 5, y: 15,
            width: 15, height: 15,
            content: "qrData"
        )
    ]
)

let data = [
    "name": "鸡胸肉",
    "qrData": "ingredient-12345"
]

try await printerService.printLabel(template: template, data: data)
```

#### 批量打印

```swift
let labels = [
    (template1, data1),
    (template2, data2),
    (template3, data3)
]

let result = try await printerService.printBatch(labels: labels)

print("成功: \(result.successfulJobs)/\(result.totalJobs)")
print("成功率: \(result.successRate * 100)%")

// 处理失败的任务
for (index, error) in result.failedJobs {
    print("标签 \(index) 打印失败: \(error.localizedDescription)")
}
```

## 错误处理

服务定义了详细的错误类型：

```swift
enum PrinterServiceError: LocalizedError {
    case notInitialized        // SDK未初始化
    case notConnected          // 打印机未连接
    case scanFailed(String)    // 扫描失败
    case connectionFailed(String) // 连接失败
    case statusQueryFailed(String) // 状态查询失败
    case printFailed(String)   // 打印失败
    case invalidTemplate       // 无效模板
    case coverOpen            // 盖子打开
    case paperOut             // 缺纸
    case lowBattery           // 电量低
    case printerBusy          // 打印机忙碌
    case unknown(String)      // 未知错误
}
```

使用示例：

```swift
do {
    try await printerService.printLabel(template: template, data: data)
} catch PrinterServiceError.coverOpen {
    showAlert("请关闭打印机盖子")
} catch PrinterServiceError.paperOut {
    showAlert("请添加打印纸")
} catch {
    showAlert("打印失败: \(error.localizedDescription)")
}
```

## JCAPI SDK集成

### 必需的库文件

需要将以下文件添加到Xcode项目中：

1. **头文件**：
   - `JCAPI.h`

2. **静态库**：
   - `JCAPI.a`
   - `JCLPAPI.a`
   - `libSkiaRenderLibrary.a`

3. **字体文件**（可选，用于文本绘制）：
   - 将字体文件复制到应用的Documents目录

### Xcode配置

1. **添加库文件到项目**：
   - 将`.a`文件拖入项目
   - 确保在Target的"Build Phases" > "Link Binary With Libraries"中包含这些库

2. **配置搜索路径**：
   - Build Settings > Header Search Paths: 添加JCAPI.h所在目录
   - Build Settings > Library Search Paths: 添加.a文件所在目录

3. **配置桥接头文件**：
   - 确保`RestaurantIngredientManager-Bridging-Header.h`中导入了`JCAPI.h`
   - Build Settings > Objective-C Bridging Header: 设置为桥接头文件路径

4. **Info.plist权限**：
   ```xml
   <key>NSBluetoothAlwaysUsageDescription</key>
   <string>需要蓝牙权限以连接标签打印机</string>
   <key>NSBluetoothPeripheralUsageDescription</key>
   <string>需要蓝牙权限以连接标签打印机</string>
   <key>NSLocalNetworkUsageDescription</key>
   <string>需要本地网络权限以发现WiFi打印机</string>
   ```

## 使用流程

### 完整的打印流程

```swift
// 1. 初始化SDK（应用启动时）
PrinterSDKManager.shared.initialize()

// 2. 创建服务实例
let printerService = PrinterService.shared

// 3. 扫描打印机
let printers = try await printerService.scanForBluetoothPrinters()

// 4. 连接打印机
if let printer = printers.first {
    try await printerService.connect(to: printer)
}

// 5. 检查状态
let status = try await printerService.getPrinterStatus()
guard status.canPrint() else {
    print("打印机状态异常: \(status.getWarnings())")
    return
}

// 6. 打印标签
try await printerService.printLabel(template: template, data: data)

// 7. 断开连接（可选）
try await printerService.disconnect()
```

## 注意事项

1. **线程安全**：
   - PrinterService使用`@MainActor`标记，所有方法都在主线程执行
   - JCAPI的回调会在后台线程，服务会自动处理线程切换

2. **状态监控**：
   - 连接成功后会自动开始监控打印机状态
   - 每2秒查询一次状态更新
   - 断开连接后会停止监控

3. **错误处理**：
   - 所有异步方法都可能抛出错误，需要适当处理
   - 打印前应检查打印机状态，避免不必要的错误

4. **资源管理**：
   - 使用完毕后应断开打印机连接
   - 避免同时连接多个打印机

5. **字体支持**：
   - 文本绘制需要字体文件支持
   - 需要调用`JCAPI.initImageProcessing(_:error:)`初始化字体路径

## 测试建议

1. **单元测试**：
   - 使用模拟对象测试服务逻辑
   - 测试错误处理和边界条件

2. **集成测试**：
   - 使用真实打印机测试连接和打印功能
   - 测试不同的打印机型号和连接类型

3. **UI测试**：
   - 测试完整的用户流程
   - 测试错误提示和用户反馈

## 相关需求

- 需求6.1: 集成精臣打印机SDK版本4.0.3
- 需求6.5: 显示当前选定打印机的连接状态
- 需求7.1-7.3: 查询和显示打印机状态（纸张、电池、盖子）

## 后续任务

- 任务5.2: 实现打印机扫描和连接
- 任务5.4: 实现打印机状态监控
- 任务5.6: 实现标签打印功能
- 任务5.8: 实现批量打印功能
