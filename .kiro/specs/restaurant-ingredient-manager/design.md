# 设计文档：餐厅食材管理系统

## 概述

餐厅食材管理系统是一款原生iOS应用程序，采用MVVM架构模式，使用Swift和SwiftUI构建。该应用程序提供离线优先的食材库存管理功能，集成精臣标签打印机SDK，并提供现代化的深色主题界面。

### 核心功能
- 食材CRUD操作（创建、读取、更新、删除）
- 高级搜索和多条件筛选
- 保质期跟踪和自动提醒
- 库存水平监控和低库存警告
- 条形码/二维码扫描
- 标签打印（单个和批量）
- 供应商和采购历史管理
- 多语言支持（中文/英文）
- 可选云同步功能

### 技术栈
- **语言**: Swift 5.5+
- **UI框架**: SwiftUI
- **最低iOS版本**: iOS 13.0
- **架构**: MVVM (Model-View-ViewModel)
- **数据持久化**: Core Data
- **打印机集成**: 精臣JCAPI框架 v4.0.3
- **扫描**: AVFoundation
- **云同步**: CloudKit (可选)

## 架构

### MVVM架构模式

```
┌─────────────────────────────────────────────────────────┐
│                         Views                            │
│  (SwiftUI Views - 用户界面层)                            │
│  - IngredientListView                                    │
│  - IngredientDetailView                                  │
│  - ScannerView                                           │
│  - PrinterConnectionView                                 │
│  - LabelPrintView                                        │
└────────────────┬────────────────────────────────────────┘
                 │ 绑定 (@ObservedObject, @StateObject)
┌────────────────▼────────────────────────────────────────┐
│                      ViewModels                          │
│  (业务逻辑和状态管理)                                     │
│  - IngredientListViewModel                               │
│  - IngredientDetailViewModel                             │
│  - ScannerViewModel                                      │
│  - PrinterViewModel                                      │
│  - LabelPrintViewModel                                   │
└────────────────┬────────────────────────────────────────┘
                 │ 调用服务和仓储
┌────────────────▼────────────────────────────────────────┐
│                   Services & Repositories                │
│  - IngredientRepository (Core Data)                      │
│  - PrinterService (JCAPI SDK)                            │
│  - ScannerService (AVFoundation)                         │
│  - CloudSyncService (CloudKit)                           │
│  - LocalizationService                                   │
└────────────────┬────────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────────┐
│                        Models                            │
│  (数据模型)                                               │
│  - Ingredient                                            │
│  - Category                                              │
│  - StorageLocation                                       │
│  - Supplier                                              │
│  - PurchaseRecord                                        │
│  - LabelTemplate                                         │
└─────────────────────────────────────────────────────────┘
```

### 模块划分

1. **核心模块 (Core)**
   - 数据模型定义
   - Core Data栈配置
   - 通用工具和扩展

2. **食材管理模块 (Ingredient Management)**
   - 食材列表和详情视图
   - 搜索和筛选功能
   - CRUD操作

3. **扫描模块 (Scanner)**
   - 相机集成
   - 条形码/二维码识别
   - 扫描结果处理

4. **打印模块 (Printer)**
   - 打印机连接管理
   - 标签模板设计
   - 打印作业处理

5. **供应商和采购模块 (Supplier & Purchase)**
   - 供应商管理
   - 采购记录跟踪
   - 成本分析

6. **设置模块 (Settings)**
   - 语言切换
   - 云同步配置
   - 应用偏好设置

## 组件和接口

### 1. 数据模型

#### Ingredient (食材)
```swift
struct Ingredient: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: Category
    var quantity: Double
    var unit: String
    var expirationDate: Date
    var storageLocation: StorageLocation
    var supplier: Supplier?
    var barcode: String?
    var qrCode: String?
    var minimumStockThreshold: Double
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
}
```

#### Category (类别)
```swift
enum Category: String, Codable, CaseIterable {
    case vegetables = "蔬菜"
    case meat = "肉类"
    case seafood = "海鲜"
    case dairy = "乳制品"
    case dryGoods = "干货"
    case frozen = "冷冻食品"
    case beverages = "饮料"
    case condiments = "调味品"
    case other = "其他"
}
```

#### StorageLocation (存储位置)
```swift
struct StorageLocation: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: LocationType
    var temperature: Double?
    var isCustom: Bool
    
    enum LocationType: String, Codable {
        case refrigerator = "冰箱"
        case freezer = "冷冻柜"
        case dryStorage = "干货仓库"
        case custom = "自定义"
    }
}
```

#### Supplier (供应商)
```swift
struct Supplier: Identifiable, Codable {
    let id: UUID
    var name: String
    var contactPerson: String?
    var phone: String?
    var email: String?
    var address: String?
    var notes: String?
}
```

#### PurchaseRecord (采购记录)
```swift
struct PurchaseRecord: Identifiable, Codable {
    let id: UUID
    var ingredientId: UUID
    var supplierId: UUID
    var quantity: Double
    var unitCost: Double
    var totalCost: Double
    var purchaseDate: Date
    var notes: String?
}
```

#### LabelTemplate (标签模板)
```swift
struct LabelTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var width: Double  // 毫米
    var height: Double // 毫米
    var elements: [LabelElement]
    var isDefault: Bool
    
    struct LabelElement: Codable {
        var type: ElementType
        var x: Double
        var y: Double
        var width: Double
        var height: Double
        var fontSize: Double?
        var content: String?
        
        enum ElementType: String, Codable {
            case text
            case qrCode
            case barcode
            case line
            case rectangle
        }
    }
}
```

### 2. 仓储层 (Repository Layer)

#### IngredientRepository
```swift
protocol IngredientRepositoryProtocol {
    func fetchAll() async throws -> [Ingredient]
    func fetch(by id: UUID) async throws -> Ingredient?
    func search(query: String) async throws -> [Ingredient]
    func filter(by criteria: FilterCriteria) async throws -> [Ingredient]
    func create(_ ingredient: Ingredient) async throws
    func update(_ ingredient: Ingredient) async throws
    func delete(_ ingredient: Ingredient) async throws
    func fetchExpiring(within days: Int) async throws -> [Ingredient]
    func fetchLowStock() async throws -> [Ingredient]
}

struct FilterCriteria {
    var categories: [Category]?
    var storageLocations: [UUID]?
    var expirationDateRange: ClosedRange<Date>?
    var suppliers: [UUID]?
}
```

### 3. 服务层 (Service Layer)

#### PrinterService
```swift
protocol PrinterServiceProtocol {
    func scanForBluetoothPrinters() async throws -> [PrinterDevice]
    func discoverWiFiPrinters() async throws -> [PrinterDevice]
    func connect(to printer: PrinterDevice) async throws
    func disconnect() async throws
    func getPrinterStatus() async throws -> PrinterStatus
    func printLabel(template: LabelTemplate, data: [String: String]) async throws
    func printBatch(labels: [(LabelTemplate, [String: String])]) async throws -> BatchPrintResult
}

struct PrinterDevice {
    let id: String
    let name: String
    let connectionType: ConnectionType
    let signalStrength: Int?
    
    enum ConnectionType {
        case bluetooth
        case wifi
    }
}

struct PrinterStatus {
    var isConnected: Bool
    var paperStatus: PaperStatus
    var batteryLevel: Int?
    var coverStatus: CoverStatus
    
    enum PaperStatus {
        case normal
        case low
        case out
    }
    
    enum CoverStatus {
        case closed
        case open
    }
}

struct BatchPrintResult {
    var totalJobs: Int
    var successfulJobs: Int
    var failedJobs: [(index: Int, error: Error)]
}
```

#### ScannerService
```swift
protocol ScannerServiceProtocol {
    func startScanning() async throws
    func stopScanning()
    func requestCameraPermission() async -> Bool
    var scannedCodePublisher: AnyPublisher<ScannedCode, Never> { get }
}

struct ScannedCode {
    var type: CodeType
    var value: String
    var timestamp: Date
    
    enum CodeType {
        case barcode
        case qrCode
    }
}
```

#### CloudSyncService
```swift
protocol CloudSyncServiceProtocol {
    func enableSync() async throws
    func disableSync() async throws
    func syncNow() async throws
    func getLastSyncTime() -> Date?
    func getSyncStatus() -> SyncStatus
    var syncStatusPublisher: AnyPublisher<SyncStatus, Never> { get }
}

enum SyncStatus {
    case idle
    case syncing
    case success(Date)
    case error(Error)
}
```

### 4. ViewModel层

#### IngredientListViewModel
```swift
@MainActor
class IngredientListViewModel: ObservableObject {
    @Published var ingredients: [Ingredient] = []
    @Published var filteredIngredients: [Ingredient] = []
    @Published var searchText: String = ""
    @Published var selectedCategories: Set<Category> = []
    @Published var selectedStorageLocations: Set<UUID> = []
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var expiringCount: Int = 0
    @Published var lowStockCount: Int = 0
    
    private let repository: IngredientRepositoryProtocol
    
    func loadIngredients() async
    func searchIngredients() async
    func applyFilters() async
    func deleteIngredient(_ ingredient: Ingredient) async
    func checkExpiringIngredients() async
    func checkLowStockIngredients() async
}
```

#### PrinterViewModel
```swift
@MainActor
class PrinterViewModel: ObservableObject {
    @Published var availablePrinters: [PrinterDevice] = []
    @Published var connectedPrinter: PrinterDevice?
    @Published var printerStatus: PrinterStatus?
    @Published var isScanning: Bool = false
    @Published var isConnecting: Bool = false
    @Published var error: Error?
    
    private let printerService: PrinterServiceProtocol
    
    func scanForPrinters(type: ConnectionType) async
    func connect(to printer: PrinterDevice) async
    func disconnect() async
    func refreshStatus() async
    func printLabel(ingredient: Ingredient, template: LabelTemplate) async
    func printBatch(ingredients: [Ingredient], template: LabelTemplate) async
}
```

## 数据模型

### Core Data实体关系图

```
┌─────────────────────────────────────────────────────────┐
│                    IngredientEntity                      │
├─────────────────────────────────────────────────────────┤
│ id: UUID                                                 │
│ name: String                                             │
│ category: String                                         │
│ quantity: Double                                         │
│ unit: String                                             │
│ expirationDate: Date                                     │
│ barcode: String?                                         │
│ qrCode: String?                                          │
│ minimumStockThreshold: Double                            │
│ notes: String?                                           │
│ createdAt: Date                                          │
│ updatedAt: Date                                          │
├─────────────────────────────────────────────────────────┤
│ storageLocation: StorageLocationEntity (1:1)             │
│ supplier: SupplierEntity (1:1, optional)                 │
│ purchaseRecords: [PurchaseRecordEntity] (1:N)            │
└─────────────────────────────────────────────────────────┘
                         │
                         │
        ┌────────────────┴────────────────┐
        │                                  │
        ▼                                  ▼
┌──────────────────────┐      ┌──────────────────────┐
│StorageLocationEntity │      │   SupplierEntity     │
├──────────────────────┤      ├──────────────────────┤
│ id: UUID             │      │ id: UUID             │
│ name: String         │      │ name: String         │
│ type: String         │      │ contactPerson: String│
│ temperature: Double? │      │ phone: String?       │
│ isCustom: Bool       │      │ email: String?       │
└──────────────────────┘      │ address: String?     │
                              │ notes: String?       │
                              └──────────────────────┘
                                        │
                                        │
                                        ▼
                              ┌──────────────────────┐
                              │PurchaseRecordEntity  │
                              ├──────────────────────┤
                              │ id: UUID             │
                              │ quantity: Double     │
                              │ unitCost: Double     │
                              │ totalCost: Double    │
                              │ purchaseDate: Date   │
                              │ notes: String?       │
                              └──────────────────────┘
```

### 数据验证规则

1. **Ingredient验证**
   - name: 非空，最大长度100字符
   - quantity: 大于等于0
   - unit: 非空，最大长度20字符
   - expirationDate: 不能早于当前日期（创建时）
   - minimumStockThreshold: 大于等于0

2. **Supplier验证**
   - name: 非空，最大长度100字符
   - phone: 可选，符合电话号码格式
   - email: 可选，符合电子邮件格式

3. **PurchaseRecord验证**
   - quantity: 大于0
   - unitCost: 大于等于0
   - totalCost: 等于 quantity × unitCost
   - purchaseDate: 不能晚于当前日期

## 正确性属性

*属性是一种特征或行为，应该在系统的所有有效执行中保持为真——本质上是关于系统应该做什么的形式化陈述。属性作为人类可读规范和机器可验证正确性保证之间的桥梁。*


### 属性1：食材创建往返一致性
*对于任何*有效的食材数据，创建食材后立即检索应该返回相同的数据（所有字段匹配）
**验证需求：1.1, 1.2**

### 属性2：食材更新持久化
*对于任何*已存在的食材和任何有效的字段更新，更新后立即检索应该返回更新后的值
**验证需求：1.3, 1.6**

### 属性3：食材删除完整性
*对于任何*已存在的食材，删除后尝试检索应该返回不存在的结果
**验证需求：1.4**

### 属性4：搜索结果相关性
*对于任何*搜索查询文本，返回的所有食材的名称、类别或供应商字段应该包含该查询文本（不区分大小写）
**验证需求：2.2**

### 属性5：筛选结果准确性
*对于任何*筛选条件集合（类别、存储位置、保质期范围），返回的所有食材应该满足所有指定的筛选条件
**验证需求：2.3, 2.4, 2.5, 2.6**

### 属性6：保质期排序正确性
*对于任何*食材列表，按保质期排序后，列表中的每个食材的保质期应该早于或等于其后续食材的保质期
**验证需求：3.3**

### 属性7：保质期警告准确性
*对于任何*食材，如果其保质期在配置的阈值天数内，则应该被标记为即将过期；如果已过期，则应该被标记为已过期
**验证需求：3.1, 3.2**

### 属性8：阈值配置往返
*对于任何*有效的保质期警告阈值天数，设置后立即读取应该返回相同的值
**验证需求：3.5, 4.1**

### 属性9：低库存识别准确性
*对于任何*食材，如果其当前数量低于其最低库存阈值，则应该被标记为低库存；如果数量为零，则应该被标记为缺货
**验证需求：4.2, 4.3, 4.5**

### 属性10：库存数量更新正确性
*对于任何*食材和任何数量变化（加法或减法），执行操作后的数量应该等于原数量加上或减去变化量
**验证需求：4.4**

### 属性11：条形码搜索准确性
*对于任何*有效的条形码，如果数据库中存在具有该条形码的食材，则搜索应该返回该食材
**验证需求：5.2**

### 属性12：二维码往返一致性
*对于任何*食材，生成包含其信息的二维码，然后解码该二维码，应该返回原始食材的关键信息（ID、名称、类别、保质期）
**验证需求：5.3, 9.3**

### 属性13：打印机连接状态一致性
*对于任何*打印机设备，连接状态应该准确反映实际的连接情况（已连接、未连接、连接中）
**验证需求：6.5**

### 属性14：打印机记忆持久化
*对于任何*成功连接的打印机，保存其信息后，应用重启后应该能检索到相同的打印机信息
**验证需求：6.6**

### 属性15：打印机状态查询准确性
*对于任何*已连接的打印机，查询其状态（纸张、电池、盖子）应该返回打印机报告的实际状态
**验证需求：7.1, 7.2, 7.3**

### 属性16：标签模板往返一致性
*对于任何*自定义标签模板，保存后通过名称检索应该返回相同的模板配置（尺寸、元素位置、内容）
**验证需求：8.2, 8.5**

### 属性17：标签内容完整性
*对于任何*食材和标签模板，生成的标签应该包含食材的名称、类别、保质期和存储位置
**验证需求：9.1, 9.2**

### 属性18：批量打印数量一致性
*对于任何*选定的食材列表，批量打印生成的标签数量应该等于选定的食材数量
**验证需求：10.2**

### 属性19：批量打印错误隔离
*对于任何*批量打印作业，如果某个标签打印失败，剩余的标签应该继续打印，失败的标签应该被记录
**验证需求：10.6**

### 属性20：存储位置往返一致性
*对于任何*自定义存储位置，创建后立即检索应该返回相同的位置信息（名称、类型、温度）
**验证需求：11.2**

### 属性21：存储位置分组准确性
*对于任何*存储位置，按该位置分组显示的所有食材应该都分配到该存储位置
**验证需求：11.4**

### 属性22：存储位置删除约束
*对于任何*存储位置，只有当没有食材分配到该位置时，才能被删除
**验证需求：11.5**

### 属性23：供应商往返一致性
*对于任何*供应商记录，创建或更新后立即检索应该返回相同的供应商信息
**验证需求：12.1, 12.5**

### 属性24：供应商关联准确性
*对于任何*供应商，查询其关联的食材应该返回所有分配给该供应商的食材
**验证需求：12.2, 12.4**

### 属性25：供应商删除约束
*对于任何*供应商，只有当没有食材关联到该供应商时，才能被删除
**验证需求：12.6**

### 属性26：采购记录往返一致性
*对于任何*采购记录，创建后立即检索应该返回相同的记录信息（食材、数量、成本、日期）
**验证需求：13.1**

### 属性27：采购历史关联准确性
*对于任何*食材，查询其采购历史应该返回所有关联到该食材的采购记录
**验证需求：13.2**

### 属性28：成本计算准确性
*对于任何*时间段和食材/类别/供应商，计算的总成本应该等于该范围内所有相关采购记录的成本之和
**验证需求：13.3, 13.4, 13.5**

### 属性29：采购数据导出完整性
*对于任何*采购历史导出操作，导出的数据应该包含所有采购记录的所有字段
**验证需求：13.6**

### 属性30：语言偏好持久化
*对于任何*支持的语言选择，设置后应用重启应该保持相同的语言设置
**验证需求：14.6**

### 属性31：数据持久化可靠性
*对于任何*保存的数据（食材、供应商、采购记录），应用重启或意外终止后应该能检索到相同的数据
**验证需求：16.3, 16.4**

### 属性32：云同步上传一致性
*对于任何*本地数据更改，在启用云同步且网络可用时，更改应该被上传到云存储
**验证需求：16.5, 17.1**

### 属性33：云同步下载一致性
*对于任何*云端数据更改，在启用云同步且网络可用时，更改应该被下载并合并到本地
**验证需求：17.2**

### 属性34：云同步冲突解决
*对于任何*同步冲突（同一数据在本地和云端都被修改），应该保留时间戳较新的版本
**验证需求：17.3**

### 属性35：云同步错误恢复
*对于任何*同步失败，系统应该记录错误并在下次同步时重试失败的操作
**验证需求：17.6**

## 错误处理

### 错误类型和处理策略

#### 1. 数据验证错误
- **场景**: 用户输入无效数据（空名称、负数量、过去的保质期等）
- **处理**: 
  - 在UI层进行即时验证
  - 显示具体的错误消息指出哪个字段无效
  - 阻止保存操作直到数据有效
  - 保持用户已输入的有效数据

#### 2. 数据库错误
- **场景**: Core Data操作失败（保存、读取、删除）
- **处理**:
  - 捕获并记录详细错误信息
  - 向用户显示友好的错误消息
  - 对于保存失败，保留用户数据并提供重试选项
  - 对于读取失败，显示缓存数据（如果可用）
  - 实现自动重试机制（最多3次）

#### 3. 打印机连接错误
- **场景**: 无法连接到打印机、连接中断、打印机不响应
- **处理**:
  - 显示具体的错误原因（蓝牙关闭、打印机离线、信号弱等）
  - 提供故障排除建议
  - 允许用户重新扫描打印机
  - 保存打印作业以便稍后重试

#### 4. 打印机状态错误
- **场景**: 纸张用完、电池低、盖子打开
- **处理**:
  - 在打印前检查打印机状态
  - 显示警告消息并阻止打印（对于严重问题）
  - 提供解决步骤的指导
  - 允许用户在解决问题后重试

#### 5. 扫描错误
- **场景**: 相机权限被拒绝、无法识别代码、相机硬件故障
- **处理**:
  - 检查相机权限并提供设置链接
  - 对于无法识别的代码，提供手动输入选项
  - 显示扫描提示帮助用户正确对准代码
  - 记录扫描失败以便调试

#### 6. 云同步错误
- **场景**: 网络不可用、CloudKit配额超限、认证失败
- **处理**:
  - 检测网络状态并在离线时暂停同步
  - 显示同步状态和最后成功同步时间
  - 实现指数退避重试策略
  - 对于认证失败，提示用户重新登录iCloud
  - 保持本地数据完整性，即使同步失败

#### 7. 内存和性能错误
- **场景**: 内存警告、大量数据加载、批量操作
- **处理**:
  - 实现分页加载大量数据
  - 使用NSFetchedResultsController优化Core Data查询
  - 在后台线程执行耗时操作
  - 响应内存警告并释放缓存
  - 限制批量操作的大小

### 错误恢复机制

1. **自动重试**: 对于临时性错误（网络、打印机连接），实现自动重试
2. **数据备份**: 在执行破坏性操作前创建数据快照
3. **事务回滚**: 使用Core Data事务确保数据一致性
4. **优雅降级**: 在某些功能不可用时，保持核心功能可用
5. **错误日志**: 记录所有错误以便调试和分析

## 测试策略

### 双重测试方法

本应用采用单元测试和基于属性的测试相结合的综合测试策略：

- **单元测试**: 验证特定示例、边缘情况和错误条件
- **基于属性的测试**: 验证所有输入的通用属性
- 两者互补，共同提供全面覆盖

### 单元测试

单元测试专注于：
- 特定示例，演示正确行为
- 组件之间的集成点
- 边缘情况和错误条件
- UI交互和导航流程

**测试框架**: XCTest

**测试覆盖范围**:
1. **数据模型测试**
   - 验证数据验证规则
   - 测试模型初始化和编码/解码
   - 边缘情况：空值、极值、无效数据

2. **仓储层测试**
   - CRUD操作的正确性
   - 搜索和筛选功能
   - Core Data栈配置
   - 错误处理和恢复

3. **服务层测试**
   - 打印机服务的模拟测试
   - 扫描服务的模拟测试
   - 云同步服务的模拟测试
   - 错误场景和边缘情况

4. **ViewModel测试**
   - 状态管理正确性
   - 用户操作响应
   - 错误处理和用户反馈
   - 异步操作完成

5. **UI测试**
   - 关键用户流程（创建食材、打印标签）
   - 导航和屏幕转换
   - 错误消息显示
   - 可访问性

### 基于属性的测试

基于属性的测试通过在许多生成的输入上测试通用属性来验证软件正确性。

**测试框架**: SwiftCheck (Swift的QuickCheck实现)

**配置**:
- 每个属性测试最少100次迭代
- 每个测试必须引用其设计文档属性
- 标签格式: **Feature: restaurant-ingredient-manager, Property {number}: {property_text}**

**属性测试覆盖范围**:

1. **数据持久化属性** (属性1-3, 31)
   - 创建-检索往返
   - 更新持久化
   - 删除完整性
   - 应用重启后的数据保留

2. **搜索和筛选属性** (属性4-5)
   - 搜索结果相关性
   - 多条件筛选准确性
   - 结果集完整性

3. **业务逻辑属性** (属性6-10)
   - 排序正确性
   - 警告和提醒准确性
   - 库存计算正确性
   - 阈值配置往返

4. **打印机集成属性** (属性13-19)
   - 连接状态一致性
   - 状态查询准确性
   - 标签生成完整性
   - 批量打印正确性

5. **关联和聚合属性** (属性20-29)
   - 实体关联准确性
   - 成本计算正确性
   - 删除约束验证
   - 数据导出完整性

6. **云同步属性** (属性32-35)
   - 上传/下载一致性
   - 冲突解决正确性
   - 错误恢复机制

### 测试数据生成

对于基于属性的测试，需要生成随机但有效的测试数据：

```swift
// 示例：食材生成器
extension Ingredient: Arbitrary {
    public static var arbitrary: Gen<Ingredient> {
        return Gen.compose { c in
            return Ingredient(
                id: UUID(),
                name: c.generate(using: String.arbitrary.suchThat { !$0.isEmpty }),
                category: c.generate(),
                quantity: c.generate(using: Double.arbitrary.suchThat { $0 >= 0 }),
                unit: c.generate(using: ["kg", "g", "L", "mL", "个", "包"].arbitrary),
                expirationDate: c.generate(using: Date.arbitrary.suchThat { $0 > Date() }),
                storageLocation: c.generate(),
                supplier: c.generate(using: Gen.fromElements(of: [nil] + suppliers)),
                barcode: c.generate(using: Gen.fromElements(of: [nil] + barcodes)),
                qrCode: nil,
                minimumStockThreshold: c.generate(using: Double.arbitrary.suchThat { $0 >= 0 }),
                notes: c.generate(),
                createdAt: Date(),
                updatedAt: Date()
            )
        }
    }
}
```

### 集成测试

集成测试验证组件之间的交互：

1. **ViewModel-Repository集成**
   - ViewModel正确调用Repository方法
   - 数据正确流动和转换
   - 错误正确传播

2. **打印机SDK集成**
   - 正确调用JCAPI框架方法
   - 处理SDK回调和委托
   - 错误处理和状态管理

3. **CloudKit集成**
   - 数据正确同步到iCloud
   - 冲突解决机制
   - 网络错误处理

### 性能测试

性能测试确保应用在各种条件下保持响应：

1. **大数据集测试**
   - 1000+食材的列表加载时间 < 1秒
   - 搜索响应时间 < 200ms
   - 批量打印100个标签 < 30秒

2. **内存使用测试**
   - 正常使用下内存占用 < 100MB
   - 无内存泄漏
   - 正确响应内存警告

3. **电池使用测试**
   - 后台同步不应显著影响电池寿命
   - 打印机连接应高效使用蓝牙/WiFi

### 可访问性测试

确保应用对所有用户可访问：

1. **VoiceOver支持**
   - 所有UI元素有适当的可访问性标签
   - 导航流程对屏幕阅读器友好
   - 重要操作有可访问性提示

2. **动态字体支持**
   - 支持iOS动态字体大小
   - 布局适应不同字体大小

3. **对比度和颜色**
   - 满足WCAG AA标准的对比度
   - 不仅依赖颜色传达信息

### 测试自动化

1. **持续集成**
   - 每次提交自动运行单元测试
   - 每日运行完整测试套件（包括属性测试）
   - 代码覆盖率目标：80%+

2. **测试报告**
   - 生成详细的测试报告
   - 跟踪测试覆盖率趋势
   - 识别不稳定的测试

3. **性能基准**
   - 跟踪关键操作的性能指标
   - 在性能退化时发出警报

## 实现注意事项

### 精臣打印机SDK集成

1. **SDK初始化**
   ```swift
   import JCAPI
   
   class PrinterSDKManager {
       static let shared = PrinterSDKManager()
       
       func initialize() {
           // 初始化SDK
           JCManager.shared().initSDK()
       }
   }
   ```

2. **蓝牙打印机扫描**
   ```swift
   func scanForBluetoothPrinters() {
       JCManager.shared().startScan { [weak self] devices in
           self?.availablePrinters = devices.map { device in
               PrinterDevice(
                   id: device.uuid,
                   name: device.name,
                   connectionType: .bluetooth,
                   signalStrength: device.rssi
               )
           }
       }
   }
   ```

3. **WiFi打印机发现**
   ```swift
   func discoverWiFiPrinters() {
       JCManager.shared().searchWiFiPrinter { [weak self] devices in
           self?.availablePrinters = devices.map { device in
               PrinterDevice(
                   id: device.ipAddress,
                   name: device.name,
                   connectionType: .wifi,
                   signalStrength: nil
               )
           }
       }
   }
   ```

4. **标签打印**
   ```swift
   func printLabel(template: LabelTemplate, data: [String: String]) async throws {
       // 创建打印任务
       let printTask = JCPrintTask()
       printTask.width = Int(template.width)
       printTask.height = Int(template.height)
       
       // 添加元素
       for element in template.elements {
           switch element.type {
           case .text:
               let text = JCText()
               text.x = Int(element.x)
               text.y = Int(element.y)
               text.content = data[element.content ?? ""] ?? ""
               text.fontSize = Int(element.fontSize ?? 12)
               printTask.add(text)
               
           case .qrCode:
               let qrCode = JCQRCode()
               qrCode.x = Int(element.x)
               qrCode.y = Int(element.y)
               qrCode.width = Int(element.width)
               qrCode.content = data[element.content ?? ""] ?? ""
               printTask.add(qrCode)
               
           case .barcode:
               let barcode = JCBarcode()
               barcode.x = Int(element.x)
               barcode.y = Int(element.y)
               barcode.width = Int(element.width)
               barcode.height = Int(element.height)
               barcode.content = data[element.content ?? ""] ?? ""
               printTask.add(barcode)
               
           default:
               break
           }
       }
       
       // 发送打印任务
       try await withCheckedThrowingContinuation { continuation in
           JCManager.shared().print(printTask) { success, error in
               if success {
                   continuation.resume()
               } else {
                   continuation.resume(throwing: error ?? PrinterError.unknown)
               }
           }
       }
   }
   ```

### SwiftUI和MVVM最佳实践

1. **状态管理**
   - 使用@Published属性发布状态变化
   - 使用@MainActor确保UI更新在主线程
   - 避免在View中直接修改Model

2. **异步操作**
   - 使用async/await处理异步操作
   - 在ViewModel中处理错误
   - 提供加载状态反馈

3. **依赖注入**
   - 通过初始化器注入依赖
   - 使用协议实现可测试性
   - 避免单例（除了真正的全局状态）

### Core Data最佳实践

1. **并发**
   - 使用私有队列上下文进行后台操作
   - 使用performAndWait或perform执行操作
   - 不跨线程传递托管对象

2. **性能优化**
   - 使用NSFetchedResultsController进行列表显示
   - 实现批量操作减少保存次数
   - 使用谓词和排序描述符优化查询

3. **数据迁移**
   - 实现轻量级迁移
   - 为重大更改提供自定义迁移策略
   - 在迁移前备份数据

### 本地化

1. **字符串本地化**
   - 使用NSLocalizedString进行所有用户可见文本
   - 提供上下文注释帮助翻译
   - 支持复数形式和变量

2. **日期和数字格式**
   - 使用DateFormatter和NumberFormatter
   - 尊重用户的区域设置
   - 正确处理不同的日历系统

3. **布局**
   - 支持从右到左的语言
   - 使用自动布局适应不同文本长度
   - 测试所有支持的语言

### 安全性

1. **数据保护**
   - 使用iOS数据保护API
   - 敏感数据加密存储
   - 在应用进入后台时隐藏敏感信息

2. **权限**
   - 只请求必要的权限
   - 提供清晰的权限说明
   - 优雅处理权限被拒绝

3. **输入验证**
   - 验证所有用户输入
   - 防止SQL注入（虽然Core Data已提供保护）
   - 限制输入长度和格式

## 部署和维护

### 版本控制

- 使用语义化版本号（主版本.次版本.修订号）
- 主版本：不兼容的API更改
- 次版本：向后兼容的功能添加
- 修订号：向后兼容的错误修复

### 发布流程

1. **开发阶段**
   - 功能开发和单元测试
   - 代码审查
   - 集成测试

2. **测试阶段**
   - 完整的回归测试
   - 性能测试
   - 可访问性测试
   - Beta测试（TestFlight）

3. **发布阶段**
   - App Store提交
   - 发布说明准备
   - 监控崩溃和错误

### 监控和分析

1. **崩溃报告**
   - 集成崩溃报告工具（如Firebase Crashlytics）
   - 监控崩溃率和趋势
   - 优先修复高频崩溃

2. **性能监控**
   - 跟踪应用启动时间
   - 监控网络请求性能
   - 识别性能瓶颈

3. **用户分析**
   - 跟踪功能使用情况
   - 识别用户流程问题
   - 收集用户反馈

### 维护计划

1. **定期更新**
   - 每月发布错误修复
   - 每季度发布功能更新
   - 及时支持新iOS版本

2. **技术债务管理**
   - 定期重构代码
   - 更新依赖库
   - 改进测试覆盖率

3. **用户支持**
   - 提供应用内帮助文档
   - 响应用户反馈
   - 维护FAQ和故障排除指南
