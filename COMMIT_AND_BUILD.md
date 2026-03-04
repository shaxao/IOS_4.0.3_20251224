# 🚀 提交并构建 IPA

## ✅ 准备就绪

所有必需的文件都已准备好：

- ✅ `project.yml` - xcodegen 配置
- ✅ `.github/workflows/ios-build.yml` - 已更新，包含自动生成步骤
- ✅ SDK 文件（JCAPI.a, JCLPAPI.a, libSkiaRenderLibrary.a, JCAPI.h）
- ✅ 所有源代码文件（55+ Swift 文件）

## 📝 执行步骤

### 在 Windows 上执行（你当前的环境）

```powershell
# 1. 查看当前状态
git status

# 2. 添加所有更改
git add .

# 3. 提交
git commit -m "修复 Xcode 项目文件问题，添加自动生成功能

- 添加 xcodegen 配置文件 (project.yml)
- 更新 iOS Build workflow，自动生成项目文件
- 复制 SDK 文件到项目目录
- 添加完整的修复文档"

# 4. 推送到 GitHub
git push
```

### 或者使用 Git GUI

如果你使用 Git GUI 工具（如 GitHub Desktop、SourceTree 等）：

1. 打开 Git GUI
2. 查看更改的文件
3. 暂存所有更改
4. 输入提交信息：
   ```
   修复 Xcode 项目文件问题，添加自动生成功能
   ```
5. 提交
6. 推送到远程仓库

---

## 🎯 推送后会发生什么

1. **GitHub Actions 自动触发**
   - 检测到 push 事件
   - 启动 iOS Build workflow

2. **自动生成项目文件**
   ```
   ✅ 安装 xcodegen
   ✅ 生成 project.pbxproj
   ✅ 验证文件大小和完整性
   ```

3. **构建 IPA**
   ```
   ✅ 构建项目
   ✅ 导出 IPA
   ✅ 上传 IPA 为 Artifact
   ```

4. **完成**
   - 大约 5-10 分钟后完成
   - 可以下载 IPA 文件

---

## 📊 监控构建进度

### 方法 1: GitHub 网页

1. 访问你的 GitHub 仓库
2. 点击 "Actions" 标签页
3. 查看最新的 workflow 运行
4. 点击进入查看详细日志

### 方法 2: GitHub CLI（可选）

```bash
# 安装 GitHub CLI
# https://cli.github.com/

# 查看 workflow 运行状态
gh run list

# 查看特定运行的日志
gh run view --log
```

---

## ✅ 成功标志

在 Actions 日志中，你应该看到：

```
✅ Install xcodegen
   📦 安装 xcodegen...
   xcodegen, version X.X.X

✅ Generate Xcode project
   🔨 生成 Xcode 项目文件...
   ✅ 项目文件生成成功 (大小: 50000+ bytes)

✅ Build project
   ** BUILD SUCCEEDED **

✅ Export IPA
   ** EXPORT SUCCEEDED **

✅ Upload IPA
   Artifact uploaded successfully
```

---

## 📥 下载 IPA

构建成功后：

1. 在 Actions 页面，点击成功的 workflow 运行
2. 滚动到页面底部
3. 在 "Artifacts" 部分，点击 "RestaurantIngredientManager-IPA"
4. 下载 ZIP 文件
5. 解压得到 `.ipa` 文件

---

## 📱 安装到设备

### 使用 Sideloadly（推荐）

1. 下载并安装 Sideloadly
   - Windows: https://sideloadly.io/
   - macOS: https://sideloadly.io/

2. 连接 iOS 设备到电脑

3. 打开 Sideloadly
   - 拖入 IPA 文件
   - 输入 Apple ID
   - 点击 "Start"

4. 等待安装完成

5. 在设备上：
   - 设置 → 通用 → VPN与设备管理
   - 信任开发者证书

6. 打开应用！

---

## 🎉 完成检查清单

- [ ] 代码已提交到 Git
- [ ] 代码已推送到 GitHub
- [ ] GitHub Actions 开始运行
- [ ] "Generate Xcode project" 步骤成功
- [ ] "Build project" 步骤成功
- [ ] "Export IPA" 步骤成功
- [ ] IPA 文件已下载
- [ ] 应用已安装到设备
- [ ] 应用可以正常打开

---

## 🆘 如果构建失败

### 常见问题

1. **xcodegen 安装失败**
   - 这不太可能，因为 GitHub Actions 的 macOS 环境有 Homebrew

2. **项目生成失败**
   - 检查 `project.yml` 是否正确提交
   - 查看错误日志

3. **构建失败**
   - 可能是签名问题（这是正常的）
   - 检查是否所有源文件都已提交
   - 检查 SDK 文件是否已提交

4. **导出失败**
   - 通常是签名配置问题
   - 可以忽略，因为 Sideloadly 会重新签名

### 获取帮助

如果遇到问题，请提供：
1. GitHub Actions 的完整日志
2. 失败的具体步骤
3. 错误信息

---

## 📝 提交命令（复制粘贴）

```bash
git add .
git commit -m "修复 Xcode 项目文件问题，添加自动生成功能"
git push
```

**就这么简单！** 🎉

---

**准备好了吗？** 执行上面的命令，然后等待 5-10 分钟，你的 IPA 就准备好了！

---

**创建时间**: 2024  
**状态**: 🟢 准备执行  
**预计时间**: 10-15 分钟（包括构建时间）
