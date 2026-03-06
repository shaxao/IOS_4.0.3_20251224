#!/bin/bash
# 验证所有async/await修复是否正确应用

set -e

echo "🔍 验证async/await修复..."

cd RestaurantIngredientManager

# 验证AnalyticsEngine.swift
ANALYTICS_COUNT=$(grep -c "await MainActor.run" RestaurantIngredientManager/Core/Analytics/AnalyticsEngine.swift || echo "0")
echo "📊 AnalyticsEngine.swift: $ANALYTICS_COUNT 个 'await MainActor.run'"
if [ "$ANALYTICS_COUNT" -lt "15" ]; then
  echo "❌ 错误: AnalyticsEngine.swift应该有至少15个'await MainActor.run'，实际只有$ANALYTICS_COUNT个"
  exit 1
fi

# 验证BatchOperationManager.swift
BATCH_COUNT=$(grep -c "await MainActor.run" RestaurantIngredientManager/Core/BatchOperations/BatchOperationManager.swift || echo "0")
echo "📊 BatchOperationManager.swift: $BATCH_COUNT 个 'await MainActor.run'"
if [ "$BATCH_COUNT" -lt "10" ]; then
  echo "❌ 错误: BatchOperationManager.swift应该有至少10个'await MainActor.run'，实际只有$BATCH_COUNT个"
  exit 1
fi

# 验证ChartView.swift
IOS17_COUNT=$(grep -c "iOS 17.0" RestaurantIngredientManager/Views/Charts/ChartView.swift || echo "0")
echo "📊 ChartView.swift: $IOS17_COUNT 个 'iOS 17.0' 版本检查"
if [ "$IOS17_COUNT" -lt "2" ]; then
  echo "❌ 错误: ChartView.swift应该有至少2个'iOS 17.0'版本检查，实际只有$IOS17_COUNT个"
  exit 1
fi

echo "✅ 所有修复验证通过！"
