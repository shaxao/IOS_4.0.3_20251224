#!/bin/bash
# 强制清理并重新构建脚本
# 用于解决CI/CD缓存问题

set -e

echo "🧹 开始强制清理构建缓存..."

# 进入项目目录
cd RestaurantIngredientManager

# 1. 清理Xcode构建缓存
echo "📦 清理Xcode构建产物..."
xcodebuild clean \
  -project RestaurantIngredientManager.xcodeproj \
  -scheme RestaurantIngredientManager \
  -configuration Release

# 2. 删除DerivedData
echo "🗑️  删除DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/RestaurantIngredientManager-*

# 3. 删除ModuleCache
echo "🗑️  删除ModuleCache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/*

# 4. 删除本地build文件夹
echo "🗑️  删除本地build文件夹..."
rm -rf build/

# 5. 验证关键文件的修改时间
echo "📅 验证文件修改时间..."
ls -la RestaurantIngredientManager/Core/Analytics/AnalyticsEngine.swift
ls -la RestaurantIngredientManager/Core/BatchOperations/BatchOperationManager.swift
ls -la RestaurantIngredientManager/Views/Charts/ChartView.swift

# 6. 显示关键文件的校验和
echo "🔍 文件校验和..."
md5 RestaurantIngredientManager/Core/Analytics/AnalyticsEngine.swift
md5 RestaurantIngredientManager/Core/BatchOperations/BatchOperationManager.swift
md5 RestaurantIngredientManager/Views/Charts/ChartView.swift

# 7. 重新构建
echo "🔨 开始重新构建..."
xcodebuild archive \
  -project RestaurantIngredientManager.xcodeproj \
  -scheme RestaurantIngredientManager \
  -archivePath ./build/RestaurantIngredientManager.xcarchive \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ONLY_ACTIVE_ARCH=NO

echo "✅ 构建完成！"
