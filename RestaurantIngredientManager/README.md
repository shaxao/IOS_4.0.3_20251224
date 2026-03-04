# 餐厅食材管理系统 (Restaurant Ingredient Manager)

## 项目概述

餐厅食材管理系统是一款原生iOS应用程序，旨在帮助餐厅员工高效管理食材库存、跟踪保质期、监控库存水平，并使用精臣标签打印机打印标签。

## 技术栈

- **语言**: Swift 5.5+
- **UI框架**: SwiftUI
- **最低iOS版本**: iOS 13.0
- **架构**: MVVM (Model-View-ViewModel)
- **数据持久化**: Core Data
- **打印机集成**: 精臣JCAPI框架 v4.0.3
- **扫描**: AVFoundation
- **云同步**: CloudKit (可选)

## 项目结构

```
RestaurantIngredientManager/
├── RestaurantIngredientManager/
│   ├── RestaurantIngredientManagerApp.swift  # 应用入口
│   ├── ContentView.swift                      # 主视图
│   │
│   ├── Core/                                  # 核心模块
│   │   ├── Persistence/                       # 数据持久化
│   │   │   └── PersistenceController.swift
│   │   ├── Printer/                           # 打印机SDK
│   │   │   └── PrinterSDKManager.swift
│   │   └── Utils/                             # 工具类
│   │
│   ├── Models/                                # 数据模型
│   │   ├── Ingredient.swift
│   │   ├── Category.swift
│   │   ├── StorageLocation.swift
│   │   ├── Supplier.swift
│   │   ├── PurchaseRecord.swift
│   │   └── LabelTemplate.swift
│   │
│   ├── Views/                                 # SwiftUI视图
│   │   ├── Ingredient/                        # 食材管理视图
│   │   ├── Scanner/                           # 扫描视图
│   │   ├── Printer/                           # 打印机视图
│   │   ├── Supplier/                          # 供应商视图
│   │   ├── Purchase/                          # 采购视图
│   │   └── Settings/                          # 设置视图
│   │
│   ├── ViewModels/                            # 视图模型
│   │   ├── IngredientListViewModel.swift
│   │   ├── IngredientDetailViewModel.swift
│   │   ├── PrinterViewModel.swift
│   │   ├── ScannerViewModel.swift
│   │   └── ...
│   │
│   ├── Services/                              # 服务层
│   │   ├── IngredientRepository.swift
│   │   ├── PrinterService.swift
│   │   ├── ScannerService.swift
│   │   └── CloudSyncService.swift
│   │
│   ├── Resources/                             # 资源文件
│   │   ├── Localization/                      # 本地化
│   │   │   ├── zh-Hans.lproj/
│   │   │   │   └── Localizable.strings
│   │   │   └── en.lproj/
│   │   │       └── Localizable.strings
│   │   └── Assets.xcassets/                   # 图片资源
│   │
│   └── Info.plist                             # 应用配置
│
├── RestaurantIngredientManagerTests/          # 单元测试
└── RestaurantIngredientManagerUITests/        # UI测试
```

## 权限配置

应用需要以下权限（已在Info.plist中配置）：

1. **相机权限** (`NSCameraUsageDescription`)
   - 用途：扫描食材条形码和二维码
   - 说明：需要访问相机以扫描食材条形码和二维码

2. **蓝牙权限** (`NSBluetoothAlwaysUsageDescription`, `NSBluetoothPeripheralUsageDescription`)
   - 用途：连接精臣标签打印机
   - 说明：需要访问蓝牙以连接标签打印机

## 本地化支持

应用支持以下语言：
- 中文（简体）- zh-Hans
- 英文 - en

默认语言：中文（简体）

## 精臣JCAPI框架集成

### SDK位置
SDK文件位于项目根目录的 `IOS_4.0.3_20251224/SDK接入包/` 目录：
- Headers: `JCAPI.h`
- Libraries: `JCAPI.a`, `JCLPAPI.a`, `libSkiaRenderLibrary.a`

### 集成步骤（需要在Xcode中完成）

1. 将SDK库文件添加到项目：
   - 将 `JCAPI.a`, `JCLPAPI.a`, `libSkiaRenderLibrary.a` 拖入Xcode项目
   - 在 Build Phases > Link Binary With Libraries 中确认已添加

2. 配置头文件搜索路径：
   - 在 Build Settings > Header Search Paths 中添加SDK头文件路径

3. 配置Bridging Header（如果需要）：
   - 创建 `RestaurantIngredientManager-Bridging-Header.h`
   - 导入 `#import "JCAPI.h"`

4. 在 `PrinterSDKManager.swift` 中初始化SDK：
   ```swift
   JCManager.shared().initSDK()
   ```

## 开发环境要求

- macOS 12.0+
- Xcode 13.0+
- iOS 13.0+ 设备或模拟器
- Swift 5.5+

## 构建和运行

1. 打开 `RestaurantIngredientManager.xcodeproj` 在Xcode中
2. 选择目标设备或模拟器
3. 按 Cmd+R 运行项目

## 下一步

当前任务（任务1：项目初始化和核心架构搭建）已完成以下内容：
- ✅ 创建项目结构（iOS 13.0+，Swift 5.5+）
- ✅ 配置模块化文件夹结构
- ✅ 准备精臣JCAPI框架集成（需要在Xcode中完成最终链接）
- ✅ 配置Info.plist权限（相机、蓝牙）
- ✅ 设置本地化支持（中文、英文）

后续任务将实现：
- 数据模型和Core Data栈
- 仓储层
- 服务层
- ViewModel层
- SwiftUI视图
- 测试

## 参考文档

- 需求文档: `.kiro/specs/restaurant-ingredient-manager/requirements.md`
- 设计文档: `.kiro/specs/restaurant-ingredient-manager/design.md`
- 任务列表: `.kiro/specs/restaurant-ingredient-manager/tasks.md`
- 精臣SDK文档: `IOS_4.0.3_20251224/接口文档/IOS端SDK 接口说明文档 V4.0.3.pdf`

## 许可证

[待定]
