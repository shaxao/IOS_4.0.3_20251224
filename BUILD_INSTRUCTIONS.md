# 构建说明 (Build Instructions)

## 使用 GitHub Actions 自动构建

本项目已配置 GitHub Actions 工作流，可以自动构建 IPA 文件。

### 步骤

1. **推送代码到 GitHub**
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/YOUR_USERNAME/RestaurantIngredientManager.git
   git push -u origin main
   ```

2. **配置签名**
   - 在 GitHub 仓库设置中添加以下 Secrets：
     - `CERTIFICATES_P12`: Base64 编码的开发证书
     - `CERTIFICATES_P12_PASSWORD`: 证书密码
     - `PROVISIONING_PROFILE`: Base64 编码的 Provisioning Profile
     - `KEYCHAIN_PASSWORD`: 临时 keychain 密码

3. **触发构建**
   - 推送代码到 `main` 或 `develop` 分支
   - 或在 GitHub Actions 页面手动触发工作流

4. **下载 IPA**
   - 构建完成后，在 Actions 页面的 Artifacts 中下载 IPA 文件

## 使用 Sideloadly 安装

### 前提条件
- 下载并安装 [Sideloadly](https://sideloadly.io/)
- 准备好 Apple ID（免费或付费账号均可）

### 安装步骤

1. **打开 Sideloadly**
   - 连接 iOS 设备到电脑
   - 在 Sideloadly 中选择你的设备

2. **导入 IPA**
   - 将从 GitHub Actions 下载的 IPA 文件拖入 Sideloadly
   - 或点击 "IPA File" 按钮选择文件

3. **登录 Apple ID**
   - 输入你的 Apple ID 和密码
   - 如果启用了双重认证，输入验证码

4. **配置选项**（可选）
   - Bundle ID: 可以修改为自定义的 Bundle ID
   - App Name: 可以修改应用显示名称
   - Version: 可以修改版本号

5. **开始安装**
   - 点击 "Start" 按钮
   - 等待签名和安装完成

6. **信任开发者**
   - 在 iOS 设备上：设置 > 通用 > VPN与设备管理
   - 找到你的 Apple ID
   - 点击"信任"

7. **启动应用**
   - 返回主屏幕
   - 点击应用图标启动

## 本地构建（需要 macOS 和 Xcode）

### 前提条件
- macOS 12.0+
- Xcode 13.0+
- Apple Developer 账号

### 步骤

1. **打开项目**
   ```bash
   cd RestaurantIngredientManager
   open RestaurantIngredientManager.xcodeproj
   ```

2. **配置签名**
   - 在 Xcode 中选择项目
   - 选择 Target > Signing & Capabilities
   - 选择你的 Team
   - 确保 Bundle Identifier 唯一

3. **添加 SDK 文件**
   - 按照 `SETUP.md` 中的说明添加精臣 SDK 文件
   - 配置头文件搜索路径
   - 链接库文件

4. **构建**
   - 选择目标设备或模拟器
   - 按 Cmd+B 构建
   - 或按 Cmd+R 运行

5. **导出 IPA**
   - Product > Archive
   - 在 Organizer 中选择 Archive
   - 点击 "Distribute App"
   - 选择 "Development" 或 "Ad Hoc"
   - 导出 IPA

## 免费 Apple ID 限制

使用免费 Apple ID 时：
- 应用每 7 天需要重新签名
- 最多同时安装 3 个应用
- 无法使用某些功能（如推送通知）

## 故障排除

### 签名失败
- 确保 Bundle ID 唯一
- 检查证书是否过期
- 尝试清理 Xcode 缓存：Cmd+Shift+K

### 安装失败
- 确保设备已信任开发者
- 检查设备存储空间
- 尝试重启设备

### 应用崩溃
- 检查 Xcode 控制台日志
- 确保所有依赖项正确链接
- 验证 SDK 文件路径

## 注意事项

1. **SDK 集成**
   - 精臣 SDK 文件需要手动添加到 Xcode 项目
   - 确保头文件搜索路径正确配置
   - 链接所有必需的系统框架

2. **权限配置**
   - 相机权限：用于扫描条形码
   - 蓝牙权限：用于连接打印机
   - 确保 Info.plist 中的权限说明清晰

3. **测试**
   - 在真实设备上测试所有功能
   - 特别是打印机连接和扫描功能
   - 测试不同 iOS 版本的兼容性

## 参考资源

- [Sideloadly 官方文档](https://sideloadly.io/)
- [Apple Developer 文档](https://developer.apple.com/documentation/)
- [Xcode 用户指南](https://developer.apple.com/documentation/xcode)
- 项目文档：
  - `README.md` - 项目概述
  - `SETUP.md` - 详细设置指南
  - `PROJECT_STATUS.md` - 项目状态

## 支持

如有问题，请参考：
- 项目 README.md
- 设计文档：`.kiro/specs/restaurant-ingredient-manager/design.md`
- 需求文档：`.kiro/specs/restaurant-ingredient-manager/requirements.md`
