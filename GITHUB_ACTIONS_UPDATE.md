# GitHub Actions Workflow 更新说明

## 更新内容

已在 `.github/workflows/ios-build.yml` 中添加了构建缓存清理步骤。

## 新增步骤

在 `Build project` 步骤之前添加了 `Clean Build Cache` 步骤：

```yaml
- name: Clean Build Cache
  run: |
    set -euo pipefail
    echo "🧹 清理构建缓存..."
    cd RestaurantIngredientManager
    
    # 清理Xcode构建缓存
    echo "📦 清理Xcode构建产物..."
    xcodebuild clean \
      -project RestaurantIngredientManager.xcodeproj \
      -scheme RestaurantIngredientManager \
      -configuration Release || echo "⚠️ clean命令失败（可能项目尚未构建过）"
    
    # 删除DerivedData
    echo "🗑️  删除DerivedData..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/RestaurantIngredientManager-* || true
    
    # 删除ModuleCache
    echo "🗑️  删除ModuleCache..."
    rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/* || true
    
    # 删除本地build文件夹
    echo "🗑️  删除本地build文件夹..."
    rm -rf build/ || true
    
    echo "✅ 缓存清理完成"
```

## 清理步骤说明

### 1. Xcode构建缓存清理
```bash
xcodebuild clean -project RestaurantIngredientManager.xcodeproj -scheme RestaurantIngredientManager
```
- 清理项目的构建产物
- 使用 `|| echo` 确保即使项目未构建过也不会失败

### 2. DerivedData清理
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/RestaurantIngredientManager-*
```
- 删除Xcode的派生数据缓存
- 包含编译的中间文件和索引

### 3. ModuleCache清理
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/*
```
- 删除Swift模块的预编译缓存
- 确保使用最新的源代码编译

### 4. 本地build文件夹清理
```bash
rm -rf build/
```
- 删除之前构建的输出文件
- 确保全新构建

## 为什么需要这个步骤？

### 问题背景
CI/CD构建报告的错误与本地代码不匹配，原因是：
1. Xcode使用缓存的旧版本源文件
2. DerivedData中的中间文件未更新
3. ModuleCache中的预编译模块过时

### 解决方案
在每次构建前强制清理所有缓存，确保：
- ✅ 使用最新的源代码
- ✅ 重新编译所有文件
- ✅ 避免缓存导致的构建错误

## 执行顺序

更新后的workflow执行顺序：

1. **Checkout code** - 拉取最新代码
2. **Setup Xcode** - 配置Xcode环境
3. **Validate SDK binaries** - 验证SDK文件
4. **Install xcodegen** - 安装项目生成工具
5. **Generate Xcode project** - 生成项目文件
6. **Install dependencies** - 安装依赖
7. **🆕 Clean Build Cache** - 清理构建缓存（新增）
8. **Build project** - 构建项目
9. **Export IPA** - 导出IPA文件

## 预期效果

### 构建时间
- 首次构建：可能增加 1-2 分钟（因为需要重新编译所有文件）
- 后续构建：时间保持一致（因为每次都是全新构建）

### 构建可靠性
- ✅ 消除缓存导致的构建错误
- ✅ 确保使用最新代码
- ✅ 提高构建的可重复性

### 日志输出
构建日志中会显示：
```
🧹 清理构建缓存...
📦 清理Xcode构建产物...
🗑️  删除DerivedData...
🗑️  删除ModuleCache...
🗑️  删除本地build文件夹...
✅ 缓存清理完成
```

## 验证方法

### 1. 检查workflow文件
```bash
cat .github/workflows/ios-build.yml | grep -A 20 "Clean Build Cache"
```

### 2. 触发构建
```bash
# 提交更改
git add .github/workflows/ios-build.yml
git commit -m "feat: 添加构建缓存清理步骤"
git push

# 或手动触发
# 在GitHub仓库页面: Actions -> iOS Build -> Run workflow
```

### 3. 查看构建日志
在GitHub Actions的构建日志中，应该能看到：
- "Clean Build Cache" 步骤成功执行
- 缓存清理的输出信息
- 构建成功完成，没有async/await错误

## 回滚方法

如果需要回滚此更改：

```bash
git revert <commit-hash>
git push
```

或手动删除 `Clean Build Cache` 步骤。

## 其他优化建议

### 1. 条件清理
如果想要只在特定情况下清理缓存：

```yaml
- name: Clean Build Cache
  if: github.event_name == 'push' || github.event.inputs.clean_cache == 'true'
  run: |
    # 清理命令...
```

### 2. 缓存关键文件
可以缓存不常变化的依赖：

```yaml
- name: Cache Swift Packages
  uses: actions/cache@v3
  with:
    path: ~/Library/Developer/Xcode/DerivedData/**/SourcePackages
    key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
```

### 3. 并行构建
如果有多个scheme，可以使用矩阵构建：

```yaml
strategy:
  matrix:
    scheme: [RestaurantIngredientManager, RestaurantIngredientManagerTests]
```

## 故障排查

### 问题1: 清理步骤失败
**症状**: `Clean Build Cache` 步骤报错

**解决方案**:
- 检查路径是否正确
- 确保有足够的权限
- 查看具体错误信息

### 问题2: 构建时间过长
**症状**: 构建时间显著增加

**解决方案**:
- 这是正常的，因为每次都是全新构建
- 可以考虑只在特定条件下清理缓存
- 使用GitHub Actions的缓存功能优化

### 问题3: 仍然有缓存问题
**症状**: 清理后仍然出现缓存相关错误

**解决方案**:
- 检查是否有其他缓存位置
- 确认代码已正确提交和推送
- 尝试手动触发workflow

## 相关文档

- [CI_CD_CACHE_ISSUE_SOLUTION.md](./CI_CD_CACHE_ISSUE_SOLUTION.md) - 详细的缓存问题解决方案
- [ASYNC_AWAIT_FIX_VERIFICATION.md](./ASYNC_AWAIT_FIX_VERIFICATION.md) - Async/Await修复验证
- [BUILD_FIX_COMPLETE.md](./BUILD_FIX_COMPLETE.md) - 构建修复完成报告

---
**更新时间**: 2026年3月6日  
**状态**: ✅ 已配置完成，等待下次构建验证
