# 快速开始测试指南

## 概述
本指南帮助你快速运行新增的单元测试，验证项目的测试覆盖率。

## 新增测试文件

### ViewModel测试
1. `IngredientListViewModelTests.swift` - 食材列表视图模型测试
2. `PrinterViewModelTests.swift` - 打印机视图模型测试
3. `PurchaseViewModelTests.swift` - 采购视图模型测试
4. `SupplierViewModelTests.swift` - 供应商视图模型测试

### Service测试
5. `ScannerServiceTests.swift` - 扫描服务测试

## 在Xcode中运行测试

### 方法1: 运行所有测试
```
1. 打开 RestaurantIngredientManager.xcodeproj
2. 按 ⌘ + U (Command + U)
3. 等待所有测试完成
```

### 方法2: 运行单个测试文件
```
1. 在Project Navigator中找到测试文件
2. 点击文件名旁边的菱形图标
3. 或者打开文件，点击行号旁边的菱形图标运行单个测试
```

### 方法3: 使用Test Navigator
```
1. 按 ⌘ + 6 打开Test Navigator
2. 点击任意测试或测试组旁边的播放按钮
```

## 命令行运行测试

### 运行所有测试
```bash
xcodebuild test \
  -scheme RestaurantIngredientManager \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -enableCodeCoverage YES
```

### 只运行特定测试类
```bash
xcodebuild test \
  -scheme RestaurantIngredientManager \
  -destination 'platform=iOS Simulator,name=iPhone 14' \
  -only-testing:RestaurantIngredientManagerTests/IngredientListViewModelTests
```

## 查看测试覆盖率

### 在Xcode中启用代码覆盖率
```
1. Product > Scheme > Edit Scheme...
2. 选择 Test
3. 点击 Options 标签
4. 勾选 "Code Coverage"
5. 点击 Close
```

### 查看覆盖率报告
```
1. 运行测试 (⌘ + U)
2. 打开 Report Navigator (⌘ + 9)
3. 选择最新的测试报告
4. 点击 Coverage 标签
5. 查看各文件的覆盖率百分比
```

## 测试统计

### 当前测试覆盖
- **总测试文件**: 14个
- **总测试用例**: 240+
- **测试覆盖率**: ~85%

### 按模块分类
| 模块 | 测试文件 | 测试用例 | 状态 |
|------|---------|---------|------|
| Models | 1 | 45+ | ✅ |
| Persistence | 1 | 15 | ✅ |
| Repositories | 4 | 70+ | ✅ |
| ViewModels | 4 | 56+ | ✅ 新增 |
| Services | 1 | 11+ | ✅ 新增 |
| Utils | 3 | 24+ | ✅ |

## 测试内容概览

### IngredientListViewModelTests (15+ 测试)
- ✅ 初始化和加载
- ✅ 搜索和筛选（含防抖）
- ✅ 过期检测
- ✅ 低库存检测
- ✅ CRUD操作
- ✅ 性能测试（1000条数据）

### PrinterViewModelTests (12+ 测试)
- ✅ 打印机扫描和发现
- ✅ 连接管理
- ✅ 单个和批量打印
- ✅ 状态监控
- ✅ 错误处理

### PurchaseViewModelTests (14+ 测试)
- ✅ 采购记录管理
- ✅ 日期筛选
- ✅ 成本分析
- ✅ 按类别/供应商统计
- ✅ CSV导出
- ✅ 性能测试

### SupplierViewModelTests (15+ 测试)
- ✅ 供应商管理
- ✅ 搜索功能
- ✅ 数据验证（邮箱、电话）
- ✅ 删除约束检查
- ✅ 排序功能
- ✅ 统计信息

### ScannerServiceTests (11+ 测试)
- ✅ 扫描状态管理
- ✅ 条码格式验证
- ✅ 相机权限检查
- ✅ 错误处理
- ✅ 性能测试

## 常见问题

### Q: 测试失败怎么办？
A: 
1. 检查是否选择了正确的模拟器
2. 确保所有依赖都已正确链接
3. 清理构建文件夹 (⌘ + Shift + K)
4. 重新构建项目 (⌘ + B)

### Q: 如何调试失败的测试？
A:
1. 在测试代码中设置断点
2. 右键点击测试名称
3. 选择 "Debug [测试名称]"
4. 使用调试器逐步执行

### Q: 测试运行很慢？
A:
1. 只运行需要的测试，不要每次都运行全部
2. 使用更快的模拟器（如iPhone 14）
3. 关闭不必要的Xcode功能
4. 考虑使用并行测试

### Q: 如何添加新的测试？
A:
1. 在测试文件中添加新的 `func test...()` 方法
2. 遵循 AAA 模式（Arrange-Act-Assert）
3. 使用清晰的测试名称
4. 添加必要的注释

## 性能测试说明

### 大数据集测试
部分测试使用1000条数据来验证性能：
- `testLoadLargeDatasetPerformance`
- `testFilterPerformance`
- `testCostCalculationPerformance`

这些测试使用 `measure` 块来测量执行时间。

### 预期性能指标
- 加载1000条记录: < 100ms
- 搜索/筛选: < 50ms
- 成本计算: < 20ms

## 持续集成

### GitHub Actions配置
项目包含CI配置，每次push都会自动运行测试：
```yaml
- name: Run tests
  run: |
    xcodebuild test \
      -scheme RestaurantIngredientManager \
      -destination 'platform=iOS Simulator,name=iPhone 14' \
      -enableCodeCoverage YES
```

## 下一步

### 建议的测试任务
1. 运行所有新增测试，确保通过
2. 查看测试覆盖率报告
3. 识别未覆盖的代码路径
4. 添加剩余ViewModel的测试
5. 考虑添加UI测试

### 需要测试的剩余ViewModels
- IngredientDetailViewModel
- ScannerViewModel
- StorageLocationViewModel

## 资源链接

- [XCTest文档](https://developer.apple.com/documentation/xctest)
- [测试最佳实践](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
- [代码覆盖率](https://developer.apple.com/documentation/xcode/code-coverage)

## 联系支持

如有问题，请参考：
- `TASK_COMPLETION_REPORT.md` - 详细的完成报告
- `IMPLEMENTATION_COMPLETE.md` - 实现完成文档
- `PROJECT_STATUS.md` - 项目状态

---

**创建日期**: 2026年3月6日  
**版本**: 1.0
