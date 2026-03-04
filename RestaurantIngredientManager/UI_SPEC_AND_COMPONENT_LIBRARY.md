# UI规范与组件库

## 1. 设计令牌
- 主色：`#0A84FF`
- 成功色：`#34C759`
- 警告色：`#FF9F0A`
- 错误色：`#FF3B30`
- 字号：10 / 12 / 14 / 16 / 20
- 圆角：6 / 8 / 12

## 2. 组件清单
| 组件 | 说明 | 配置项 |
|---|---|---|
| CategorySelector | 单一分类入口 | dataSource, selectedID |
| DynamicFieldGroup | 分类驱动字段区域 | fields, values, required |
| DurationInput | 时长输入组件 | amount, unit, customMinutes |
| PrinterStatusBadge | 全局打印状态徽章 | connected, paperStatus, coverStatus |
| TemplateCanvas | 标签画布 | paperSize, items |
| CanvasToolbar | 字体与样式工具栏 | fontSize, color, bold, italic |
| FieldMaterialPanel | 字段素材面板 | enabledFields |
| ImageUploadAction | 上传/拍照入口 | sourceType, thumbnail |

## 3. 交互规范
- 拖拽容差：手指移动超过 4pt 进入拖拽状态。
- 选中态：蓝色 1pt 边框 + 工具栏立即可编辑。
- 图片框：默认 72×54，自动缩略到 300×300。
- 纸张切换：A4 / 58mm / 80mm / 40×30mm，切换后即时重算画布比例。

## 4. 零代码配置约定
- 新字段接入只需在分类配置增加字段定义，不修改视图代码。
- 模板版本以 `CANVAS::JSON` 存储，渲染层自动识别。
- 打印数据映射基于字段 key，新增字段自动注入模板预览数据。
