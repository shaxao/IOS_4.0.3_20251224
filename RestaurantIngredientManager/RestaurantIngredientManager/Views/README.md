# Views 模块

此目录包含应用程序的SwiftUI视图实现。

## 已实现的视图

### 主导航

#### MainTabView
主标签导航视图，包含5个标签页：
- 食材管理
- 扫描
- 打印
- 采购
- 设置

### 食材视图 (Ingredients/)

#### IngredientListView
食材列表视图，主要功能：
- 显示所有食材
- 搜索功能
- 多条件筛选
- 过期和低库存统计
- 下拉刷新
- 滑动删除

#### IngredientDetailView
食材详情视图，显示：
- 基本信息
- 保质期状态
- 条形码
- 备注
- 打印和编辑操作

#### IngredientFormView
食材表单视图，支持：
- 创建新食材
- 编辑现有食材
- 实时表单验证
- 扫描条形码
- 保质期设置

### 扫描视图 (Scanner/)

#### ScannerView
相机扫描视图，功能：
- 实时相机预览
- 扫描框和动画
- 条形码/二维码识别
- 自动查找匹配食材
- 权限请求处理

### 打印机视图 (Printer/)

#### PrinterConnectionView
打印机连接视图，功能：
- 蓝牙/WiFi打印机扫描
- 打印机列表显示
- 连接管理
- 状态查看

#### PrinterStatusView
打印机状态视图，显示：
- 连接状态
- 盖子状态
- 纸张状态
- 电池电量
- 警告信息

#### LabelPrintView
标签打印视图，功能：
- 食材信息预览
- 模板选择
- 打印份数设置
- 打印操作

### 采购视图 (Purchase/)

#### PurchaseRecordView
采购记录视图，功能：
- 采购记录列表
- 总成本统计
- 日期筛选
- 添加/删除记录
- 成本分析入口

#### CostAnalysisView
成本分析视图，显示：
- 总成本
- 按类别统计
- 按供应商统计
- CSV导出

### 设置视图 (Settings/)

#### SettingsView
设置主视图，包含：
- 语言切换
- 保质期警告设置
- 数据管理入口
- 关于信息

#### SupplierListView
供应商列表视图，功能：
- 供应商列表
- 添加/编辑/删除
- 关联食材统计
- 删除约束检查

#### StorageLocationListView
存储位置列表视图，功能：
- 按区域分组显示
- 添加/编辑/删除
- 环境参数设置
- 关联食材统计

## 视图组件

### 可复用组件

- **IngredientRow**: 食材列表行
- **DetailRow**: 详情信息行
- **StatusRow**: 状态信息行
- **PrinterRow**: 打印机列表行
- **PurchaseRecordRow**: 采购记录行
- **FeatureRow**: 功能特性行

### 辅助视图

- **FilterSheet**: 筛选表单
- **PermissionRequestView**: 权限请求视图
- **CameraPreviewView**: 相机预览视图
- **ScanLineView**: 扫描线动画
- **AboutView**: 关于页面

## 设计原则

### MVVM架构
- 视图只负责UI展示
- 业务逻辑在ViewModel中
- 使用@StateObject/@ObservedObject绑定ViewModel

### SwiftUI最佳实践
- 使用List和Form构建界面
- 利用NavigationView/NavigationLink导航
- Sheet/Alert展示模态内容
- Task处理异步操作
- @AppStorage持久化设置

### 用户体验
- 下拉刷新
- 滑动操作
- 加载状态指示
- 错误提示
- 成功反馈
- 空状态处理

## 样式和主题

### 颜色
- 主色调：蓝色
- 类别颜色：根据食材类别动态显示
- 状态颜色：绿色（正常）、橙色（警告）、红色（错误）

### 图标
- 使用SF Symbols系统图标
- 每个类别有专属图标
- 状态用圆点或图标表示

### 布局
- 使用系统标准间距
- List使用.insetGrouped样式
- Form用于表单输入
- 适配不同屏幕尺寸

## 本地化

所有用户可见文本都应支持本地化：
- 使用LocalizedStringKey
- 在Localizable.strings中定义
- 支持中文和英文

## 可访问性

- 使用Label提供语义化标签
- 支持VoiceOver
- 支持动态字体
- 适当的颜色对比度

## 性能优化

- 使用LazyVStack/LazyHStack延迟加载
- 避免在视图中执行耗时操作
- 使用Task处理异步任务
- 合理使用@State和@Binding

## 测试建议

### UI测试
- 测试导航流程
- 测试表单验证
- 测试搜索和筛选
- 测试错误处理

### 快照测试
- 测试不同状态的视图
- 测试不同语言
- 测试不同屏幕尺寸

## 相关需求

- 需求1.1-1.4: 食材管理视图
- 需求2.1-2.6: 搜索和筛选
- 需求5.1-5.6: 扫描视图
- 需求6.1-7.6: 打印机视图
- 需求11.1-11.6: 供应商视图
- 需求12.1-12.6: 存储位置视图
- 需求13.1-13.6: 采购视图
- 需求15.1-15.6: UI主题

## 后续任务

- 实现标签模板编辑器
- 添加图表可视化
- 实现批量操作
- 添加更多动画效果
- 优化iPad布局
