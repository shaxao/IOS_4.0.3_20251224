# ViewModels 模块

此目录包含应用程序的ViewModel层实现，遵循MVVM架构模式。

## 已实现的ViewModels

### IngredientListViewModel

食材列表视图模型，管理食材列表的显示、搜索和筛选。

**功能：**
- 加载和刷新食材列表
- 实时搜索（防抖300ms）
- 多条件筛选（类别、供应商、存储位置）
- 过期食材筛选
- 低库存食材筛选
- 删除食材
- 统计过期和低库存数量

### IngredientDetailViewModel

食材详情视图模型，管理单个食材的查看和编辑。

**功能：**
- 加载食材详情
- 创建新食材
- 更新现有食材
- 实时表单验证
- 数量快速更新
- 错误处理

### PrinterViewModel

打印机视图模型，管理打印机连接和打印操作。

**功能：**
- 扫描蓝牙和WiFi打印机
- 连接和断开打印机
- 实时状态监控
- 单个标签打印
- 批量打印with进度跟踪
- 食材标签快速打印

### ScannerViewModel

扫描视图模型，管理相机扫描功能。

**功能：**
- 相机权限管理
- 启动和停止扫描
- 条形码和二维码识别
- 自动查找匹配的食材
- 扫描结果处理

### SupplierViewModel

供应商视图模型，管理供应商的CRUD操作。

**功能：**
- 加载供应商列表
- 创建、更新、删除供应商
- 删除约束检查
- 关联食材数量统计

### StorageLocationViewModel

存储位置视图模型，管理存储位置的CRUD操作。

**功能：**
- 加载存储位置列表
- 按区域分组显示
- 创建、更新、删除位置
- 删除约束检查
- 关联食材数量统计

### PurchaseViewModel

采购视图模型，管理采购记录和成本分析。

**功能：**
- 加载采购记录
- 创建和删除记录
- 多条件筛选（食材、供应商、日期范围）
- 成本统计（总成本、按类别、按供应商）
- CSV数据导出

## 架构原则

### MVVM模式

- **View**: SwiftUI视图，负责UI展示
- **ViewModel**: 业务逻辑和状态管理
- **Model**: 数据模型（Ingredient、Supplier等）

### 依赖注入

所有ViewModel都支持依赖注入，便于测试：

```swift
// 生产环境
let viewModel = IngredientListViewModel()

// 测试环境
let mockRepository = MockIngredientRepository()
let viewModel = IngredientListViewModel(repository: mockRepository)
```

### 响应式编程

使用Combine框架实现响应式数据流：

- `@Published`: 发布状态变化
- `Publisher`: 订阅数据流
- `sink`: 处理事件
- `debounce`: 防抖处理

### 错误处理

统一的错误处理模式：

```swift
@Published var errorMessage: String?

do {
    // 操作
} catch {
    errorMessage = "操作失败: \(error.localizedDescription)"
}
```

### 加载状态

统一的加载状态管理：

```swift
@Published private(set) var isLoading: Bool = false

func loadData() async {
    isLoading = true
    // 加载数据
    isLoading = false
}
```

## 使用示例

### 在SwiftUI视图中使用

```swift
struct IngredientListView: View {
    @StateObject private var viewModel = IngredientListViewModel()
    
    var body: some View {
        List(viewModel.filteredIngredients) { ingredient in
            IngredientRow(ingredient: ingredient)
        }
        .searchable(text: $viewModel.searchText)
        .task {
            await viewModel.loadIngredients()
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
```

### 测试ViewModel

```swift
@MainActor
class IngredientListViewModelTests: XCTestCase {
    func testLoadIngredients() async {
        let mockRepo = MockIngredientRepository()
        let viewModel = IngredientListViewModel(repository: mockRepo)
        
        await viewModel.loadIngredients()
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.ingredients.count, 3)
    }
}
```

## 最佳实践

1. **使用@MainActor**: 所有ViewModel都标记为@MainActor，确保UI更新在主线程
2. **异步操作**: 使用async/await处理异步操作
3. **防抖处理**: 搜索等高频操作使用debounce
4. **状态管理**: 使用@Published发布状态变化
5. **错误处理**: 统一的错误信息展示
6. **依赖注入**: 支持测试和模块化
7. **资源清理**: 使用cancellables管理订阅

## 相关需求

- 需求1.2-1.4: 食材列表和搜索
- 需求2.2-2.6: 食材筛选
- 需求6.2-6.7: 打印机连接
- 需求5.1-5.6: 扫描功能
- 需求11.2-11.5: 供应商管理
- 需求12.1-12.6: 存储位置管理
- 需求13.1-13.6: 采购记录管理
