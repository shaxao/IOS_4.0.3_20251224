# 精臣JCAPI SDK集成指南

本文档说明如何将精臣JCAPI框架（v4.0.3）集成到RestaurantIngredientManager项目中。

## SDK文件位置

SDK文件位于项目根目录的`IOS_4.0.3_20251224/SDK接入包/`文件夹中：

```
IOS_4.0.3_20251224/
└── SDK接入包/
    ├── Headers/
    │   └── JCAPI.h          # SDK头文件
    └── Libs/
        ├── JCAPI.a          # 主SDK静态库
        ├── JCLPAPI.a        # 辅助库
        └── libSkiaRenderLibrary.a  # 图形渲染库
```

## 集成步骤

### 1. 复制SDK文件到项目

将SDK文件复制到项目目录中：

```bash
# 创建SDK目录
mkdir -p RestaurantIngredientManager/RestaurantIngredientManager/SDK

# 复制头文件
cp IOS_4.0.3_20251224/SDK接入包/Headers/JCAPI.h \
   RestaurantIngredientManager/RestaurantIngredientManager/SDK/

# 复制静态库
cp IOS_4.0.3_20251224/SDK接入包/Libs/*.a \
   RestaurantIngredientManager/RestaurantIngredientManager/SDK/
```

### 2. 在Xcode中添加文件

1. 打开`RestaurantIngredientManager.xcodeproj`
2. 右键点击项目导航器中的`RestaurantIngredientManager`文件夹
3. 选择"Add Files to RestaurantIngredientManager..."
4. 选择刚才复制的SDK文件夹
5. 确保勾选"Copy items if needed"和"Create groups"
6. 点击"Add"

### 3. 配置Build Settings

在Xcode中配置以下设置：

#### 3.1 Header Search Paths

1. 选择项目 > Target: RestaurantIngredientManager
2. 选择"Build Settings"标签
3. 搜索"Header Search Paths"
4. 添加：`$(SRCROOT)/RestaurantIngredientManager/SDK`（设置为recursive）

#### 3.2 Library Search Paths

1. 在"Build Settings"中搜索"Library Search Paths"
2. 添加：`$(SRCROOT)/RestaurantIngredientManager/SDK`（设置为recursive）

#### 3.3 Other Linker Flags

1. 在"Build Settings"中搜索"Other Linker Flags"
2. 添加：`-ObjC`

### 4. 链接静态库

1. 选择项目 > Target: RestaurantIngredientManager
2. 选择"Build Phases"标签
3. 展开"Link Binary With Libraries"
4. 点击"+"按钮
5. 点击"Add Other..." > "Add Files..."
6. 选择以下文件：
   - `JCAPI.a`
   - `JCLPAPI.a`
   - `libSkiaRenderLibrary.a`

### 5. 配置桥接头文件

桥接头文件已经配置好（`RestaurantIngredientManager-Bridging-Header.h`），确保在Build Settings中设置正确：

1. 在"Build Settings"中搜索"Objective-C Bridging Header"
2. 设置为：`RestaurantIngredientManager/RestaurantIngredientManager-Bridging-Header.h`

### 6. 配置Info.plist权限

在`Info.plist`中添加以下权限说明（已配置）：

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>需要蓝牙权限以连接标签打印机</string>

<key>NSBluetoothPeripheralUsageDescription</key>
<string>需要蓝牙权限以连接标签打印机</string>

<key>NSLocalNetworkUsageDescription</key>
<string>需要本地网络权限以发现WiFi打印机</string>

<key>NSBonjourServices</key>
<array>
    <string>_printer._tcp</string>
</array>
```

### 7. 添加字体文件（可选）

如果需要使用自定义字体进行文本打印：

1. 从`IOS_4.0.3_20251224/SDKDemoSwift/SDKDemoSwift/font/`复制字体文件
2. 在应用启动时将字体文件复制到Documents目录
3. 调用`JCAPI.initImageProcessing(_:error:)`初始化字体路径

示例代码：

```swift
func setupFonts() {
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    let fontPath = "\(documentsPath)/font"
    
    // 创建字体目录
    try? FileManager.default.createDirectory(atPath: fontPath, withIntermediateDirectories: true)
    
    // 复制字体文件到Documents目录
    // ... 复制逻辑 ...
    
    // 初始化图像处理
    JCAPI.initImageProcessing(fontPath, error: nil)
}
```

## 验证集成

### 编译测试

1. 在Xcode中按`Cmd+B`编译项目
2. 确保没有编译错误
3. 特别检查以下文件：
   - `PrinterService.swift`
   - `PrinterSDKManager.swift`

### 运行时测试

在应用启动时测试SDK初始化：

```swift
@main
struct RestaurantIngredientManagerApp: App {
    init() {
        // 初始化打印机SDK
        PrinterSDKManager.shared.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 功能测试

创建一个简单的测试视图来验证SDK功能：

```swift
struct PrinterTestView: View {
    @State private var printers: [PrinterDevice] = []
    @State private var isScanning = false
    
    var body: some View {
        VStack {
            Button("扫描蓝牙打印机") {
                Task {
                    isScanning = true
                    do {
                        printers = try await PrinterService.shared.scanForBluetoothPrinters()
                        print("找到 \(printers.count) 台打印机")
                    } catch {
                        print("扫描失败: \(error)")
                    }
                    isScanning = false
                }
            }
            .disabled(isScanning)
            
            List(printers) { printer in
                Text(printer.name)
            }
        }
    }
}
```

## 常见问题

### 问题1：找不到JCAPI.h

**解决方案**：
- 检查Header Search Paths是否正确配置
- 确保JCAPI.h文件已添加到项目中
- 清理构建文件夹（Product > Clean Build Folder）

### 问题2：链接错误 - Undefined symbols

**解决方案**：
- 检查Library Search Paths是否正确配置
- 确保所有.a文件都已添加到"Link Binary With Libraries"
- 确保添加了`-ObjC`到Other Linker Flags

### 问题3：运行时崩溃

**解决方案**：
- 检查Info.plist中的权限配置
- 确保在使用SDK前调用了初始化方法
- 检查是否在真机上测试（模拟器可能不支持蓝牙）

### 问题4：蓝牙扫描无结果

**解决方案**：
- 确保设备蓝牙已开启
- 确保打印机已开机且处于可发现状态
- 检查应用是否获得了蓝牙权限
- 必须在真机上测试（模拟器不支持蓝牙）

## 参考文档

- SDK使用说明：`IOS_4.0.3_20251224/IOS端 SDK接入包使用说明.pdf`
- Swift示例代码：`IOS_4.0.3_20251224/SDKDemoSwift/`
- Objective-C示例代码：`IOS_4.0.3_20251224/SDKDemoOC/`
- 接口文档：`IOS_4.0.3_20251224/接口文档/`

## 下一步

集成完成后，可以继续实现以下功能：

1. ✅ 任务5.1：创建PrinterService基础结构（已完成）
2. 任务5.2：实现打印机扫描和连接
3. 任务5.4：实现打印机状态监控
4. 任务5.6：实现标签打印功能
5. 任务5.8：实现批量打印功能

## 支持

如有问题，请参考：
- 项目文档：`RestaurantIngredientManager/RestaurantIngredientManager/Core/Printer/README.md`
- SDK官方文档和示例代码
