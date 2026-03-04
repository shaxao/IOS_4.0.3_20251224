# 项目设置指南 (Project Setup Guide)

本文档提供详细的项目设置步骤，帮助开发者在Xcode中完成项目配置。

## 前提条件

- macOS 12.0 或更高版本
- Xcode 13.0 或更高版本
- iOS 13.0+ 设备或模拟器

## 步骤1：在Xcode中打开项目

由于项目结构已经创建，但Xcode项目文件需要手动生成，请按照以下步骤操作：

### 选项A：使用现有结构创建新项目

1. 打开Xcode
2. 选择 "Create a new Xcode project"
3. 选择 "iOS" > "App"
4. 配置项目：
   - Product Name: `RestaurantIngredientManager`
   - Team: 选择你的开发团队
   - Organization Identifier: `com.yourcompany`
   - Interface: `SwiftUI`
   - Language: `Swift`
   - 取消勾选 "Use Core Data"（我们已经手动配置）
   - 取消勾选 "Include Tests"（我们将手动添加）
5. 保存到项目根目录，替换现有的 `.xcodeproj` 文件
6. 将已创建的源文件添加到项目中

### 选项B：手动配置项目文件

如果你熟悉Xcode项目文件格式，可以手动编辑 `project.pbxproj` 文件。

## 步骤2：配置项目设置

### 2.1 基本设置

1. 在Xcode中选择项目文件
2. 选择 "RestaurantIngredientManager" target
3. 在 "General" 标签页中：
   - Deployment Target: 设置为 `iOS 13.0`
   - Device Orientation: 勾选 Portrait, Landscape Left, Landscape Right

### 2.2 配置Info.plist

Info.plist 文件已经创建并包含必要的权限配置。确保以下权限已正确设置：

- `NSCameraUsageDescription`: 需要访问相机以扫描食材条形码和二维码
- `NSBluetoothAlwaysUsageDescription`: 需要访问蓝牙以连接标签打印机
- `NSBluetoothPeripheralUsageDescription`: 需要访问蓝牙以连接标签打印机

### 2.3 配置本地化

1. 在项目设置中，找到 "Localizations" 部分
2. 点击 "+" 添加以下语言：
   - Chinese (Simplified) - zh-Hans
   - English - en
3. 确保 `Localizable.strings` 文件已添加到两个语言目录

## 步骤3：集成精臣JCAPI框架

### 3.1 添加SDK库文件

1. 在Xcode项目导航器中，右键点击项目根目录
2. 选择 "Add Files to RestaurantIngredientManager..."
3. 导航到 `../IOS_4.0.3_20251224/SDK接入包/Libs/`
4. 选择以下文件：
   - `JCAPI.a`
   - `JCLPAPI.a`
   - `libSkiaRenderLibrary.a`
5. 确保勾选 "Copy items if needed"
6. 点击 "Add"

### 3.2 配置头文件搜索路径

1. 选择项目 target
2. 进入 "Build Settings" 标签页
3. 搜索 "Header Search Paths"
4. 添加以下路径（相对于项目根目录）：
   ```
   $(PROJECT_DIR)/../IOS_4.0.3_20251224/SDK接入包/Headers
   ```
5. 设置为 "recursive"

### 3.3 配置Bridging Header

1. 选择项目 target
2. 进入 "Build Settings" 标签页
3. 搜索 "Objective-C Bridging Header"
4. 设置值为：
   ```
   RestaurantIngredientManager/RestaurantIngredientManager-Bridging-Header.h
   ```
5. 打开 `RestaurantIngredientManager-Bridging-Header.h` 文件
6. 取消注释 `#import "JCAPI.h"` 行

### 3.4 链接库文件

1. 选择项目 target
2. 进入 "Build Phases" 标签页
3. 展开 "Link Binary With Libraries"
4. 确认以下库已添加：
   - `JCAPI.a`
   - `JCLPAPI.a`
   - `libSkiaRenderLibrary.a`
5. 如果缺少，点击 "+" 添加它们

### 3.5 添加系统框架

精臣SDK可能需要以下系统框架，请确保已添加：

1. 在 "Link Binary With Libraries" 中点击 "+"
2. 搜索并添加以下框架：
   - `CoreBluetooth.framework`
   - `SystemConfiguration.framework`
   - `CoreGraphics.framework`
   - `UIKit.framework`
   - `Foundation.framework`

## 步骤4：配置Core Data

### 4.1 创建Core Data模型文件

1. 在Xcode中，右键点击项目导航器中的 "Core" 文件夹
2. 选择 "New File..."
3. 选择 "Data Model"
4. 命名为 `RestaurantIngredientManager.xcdatamodeld`
5. 点击 "Create"

### 4.2 定义实体

在后续任务中，我们将在这个模型文件中定义以下实体：
- IngredientEntity
- StorageLocationEntity
- SupplierEntity
- PurchaseRecordEntity

## 步骤5：配置资源文件

### 5.1 添加Assets Catalog

1. 如果项目中没有 `Assets.xcassets`，创建一个
2. 在后续任务中，我们将添加应用图标和其他图片资源

### 5.2 创建LaunchScreen

1. 创建 `LaunchScreen.storyboard` 或使用SwiftUI创建启动屏幕
2. 在后续任务中实现

## 步骤6：验证配置

### 6.1 构建项目

1. 选择一个iOS模拟器或真实设备
2. 按 `Cmd+B` 构建项目
3. 确保没有编译错误

### 6.2 运行项目

1. 按 `Cmd+R` 运行项目
2. 应该看到一个简单的欢迎界面，显示 "餐厅食材管理系统"

## 步骤7：配置测试目标

### 7.1 创建测试目标

1. 在项目设置中，点击 "+" 添加新target
2. 选择 "Unit Testing Bundle"
3. 命名为 `RestaurantIngredientManagerTests`
4. 重复步骤创建 "UI Testing Bundle"，命名为 `RestaurantIngredientManagerUITests`

## 常见问题

### Q: 编译时找不到JCAPI.h

**A:** 检查以下设置：
1. Header Search Paths 是否正确配置
2. Bridging Header 路径是否正确
3. SDK文件是否已正确添加到项目

### Q: 链接错误：找不到符号

**A:** 确保：
1. 所有SDK库文件（.a文件）已添加到 "Link Binary With Libraries"
2. 必要的系统框架已添加
3. 架构设置正确（支持arm64）

### Q: 运行时崩溃：Core Data错误

**A:** 确保：
1. `RestaurantIngredientManager.xcdatamodeld` 文件已添加到项目
2. PersistenceController 中的容器名称与模型文件名称匹配

### Q: 本地化字符串不显示

**A:** 检查：
1. Localizable.strings 文件是否已添加到正确的语言目录
2. 项目设置中是否已添加相应的本地化语言
3. 使用 `NSLocalizedString` 或 `.localized` 扩展方法

## 下一步

完成以上设置后，项目初始化就完成了。接下来可以继续执行任务列表中的后续任务：

- 任务2：数据模型和Core Data栈实现
- 任务3：仓储层实现
- 任务4：打印机服务实现
- ...

## 参考资源

- [精臣SDK文档](../IOS_4.0.3_20251224/接口文档/IOS端SDK 接口说明文档 V4.0.3.pdf)
- [精臣SDK使用说明](../IOS_4.0.3_20251224/IOS端 SDK接入包使用说明.pdf)
- [Apple Core Data文档](https://developer.apple.com/documentation/coredata)
- [Apple SwiftUI文档](https://developer.apple.com/documentation/swiftui)

## 支持

如有问题，请参考：
- 项目README.md
- 设计文档：`.kiro/specs/restaurant-ingredient-manager/design.md`
- 需求文档：`.kiro/specs/restaurant-ingredient-manager/requirements.md`
