# 数据模型 (Data Models)

本目录包含餐厅食材管理系统的所有数据模型定义。

## 已实现的模型

### 1. Category.swift
- **描述**: 食材类别枚举
- **协议**: `Codable`, `CaseIterable`, `Identifiable`
- **类别**: 蔬菜、肉类、海鲜、乳制品、干货、冷冻食品、饮料、调味品、其他
- **功能**: 提供中英文名称映射

### 2. StorageLocation.swift
- **描述**: 存储位置模型
- **协议**: `Identifiable`, `Codable`, `Equatable`
- **字段**: id, name, type, temperature, isCustom
- **验证**: 名称非空、长度限制
- **类型**: 冰箱、冷冻柜、干货仓库、自定义

### 3. Supplier.swift
- **描述**: 供应商模型
- **协议**: `Identifiable`, `Codable`, `Equatable`
- **字段**: id, name, contactPerson, phone, email, address, notes
- **验证**: 
  - 名称非空、长度限制
  - 电话号码格式验证
  - 电子邮件格式验证

### 4. Ingredient.swift
- **描述**: 食材模型（核心模型）
- **协议**: `Identifiable`, `Codable`, `Equatable`
- **字段**: id, name, category, quantity, unit, expirationDate, storageLocation, supplier, barcode, qrCode, minimumStockThreshold, notes, createdAt, updatedAt
- **验证**:
  - 名称非空、长度限制
  - 数量非负
  - 单位非空、长度限制
  - 最低库存阈值非负
- **业务逻辑**:
  - `isExpiringSoon(within:)`: 检查是否即将过期
  - `isExpired`: 检查是否已过期
  - `isLowStock`: 检查是否库存不足
  - `isOutOfStock`: 检查是否缺货

### 5. PurchaseRecord.swift
- **描述**: 采购记录模型
- **协议**: `Identifiable`, `Codable`, `Equatable`
- **字段**: id, ingredientId, supplierId, quantity, unitCost, totalCost, purchaseDate, notes
- **验证**:
  - 数量大于0
  - 单价非负
  - 总成本等于数量×单价
  - 采购日期不能晚于当前日期
- **便利初始化器**: 自动计算总成本

### 6. LabelTemplate.swift
- **描述**: 标签模板模型
- **协议**: `Identifiable`, `Codable`, `Equatable`
- **字段**: id, name, width, height, elements, isDefault
- **子模型**: `LabelElement`
  - 类型: text, qrCode, barcode, line, rectangle
  - 字段: id, type, x, y, width, height, fontSize, content
- **验证**:
  - 模板名称非空、长度限制
  - 宽度和高度大于0
  - 元素位置和尺寸在模板范围内
  - 文本元素必须指定字体大小

## 数据验证

所有模型都实现了 `validate()` 方法，用于验证数据的完整性和有效性。验证失败时会抛出 `ValidationError`，包含本地化的错误描述。

## 测试

所有模型都有对应的单元测试，位于 `RestaurantIngredientManagerTests/ModelTests.swift`。

测试覆盖：
- 模型创建
- 数据验证（有效和无效数据）
- 业务逻辑（过期检查、库存状态等）
- Codable 序列化和反序列化

## 使用示例

```swift
// 创建存储位置
let location = StorageLocation(
    name: "冰箱A",
    type: .refrigerator,
    temperature: 4.0
)

// 创建供应商
let supplier = Supplier(
    name: "新鲜食材供应商",
    phone: "13800138000",
    email: "supplier@example.com"
)

// 创建食材
let ingredient = Ingredient(
    name: "西红柿",
    category: .vegetables,
    quantity: 10.0,
    unit: "kg",
    expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
    storageLocation: location,
    supplier: supplier,
    minimumStockThreshold: 2.0
)

// 验证数据
try ingredient.validate()

// 检查状态
if ingredient.isExpiringSoon(within: 3) {
    print("食材即将过期")
}

if ingredient.isLowStock {
    print("库存不足")
}
```

## 需求映射

- **需求 1.1**: Ingredient 模型支持所有必需字段
- **需求 11.1**: StorageLocation 模型
- **需求 12.1**: Supplier 模型
- **需求 13.1**: PurchaseRecord 模型
- **需求 8.1**: LabelTemplate 模型

## 下一步

- 实现 Core Data 实体映射（任务 2.3）
- 实现仓储层（任务 3.1-3.5）
- 编写属性测试（任务 2.2）
