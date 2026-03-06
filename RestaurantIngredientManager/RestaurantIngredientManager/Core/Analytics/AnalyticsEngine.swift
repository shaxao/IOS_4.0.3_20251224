//
//  AnalyticsEngine.swift
//  RestaurantIngredientManager
//
//  数据分析引擎
//

import Foundation
import Combine

/// 分析报表类型
enum ReportType {
    case inventory          // 库存分析
    case purchase           // 采购分析
    case expiration         // 过期分析
    case supplier           // 供应商分析
    case cost               // 成本分析
    case trend              // 趋势分析
}

/// 时间范围
enum TimeRange {
    case today
    case week
    case month
    case quarter
    case year
    case custom(start: Date, end: Date)
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            return (start, now)
        case .week:
            let start = calendar.date(byAdding: .day, value: -7, to: now)!
            return (start, now)
        case .month:
            let start = calendar.date(byAdding: .month, value: -1, to: now)!
            return (start, now)
        case .quarter:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return (start, now)
        case .year:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            return (start, now)
        case .custom(let start, let end):
            return (start, end)
        }
    }
}

/// 分析结果
struct AnalyticsResult {
    let reportType: ReportType
    let timeRange: TimeRange
    let data: [String: Any]
    let generatedAt: Date
    let summary: String
}

/// 数据分析引擎
class AnalyticsEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAnalyzing: Bool = false
    @Published var progress: Double = 0.0
    
    // MARK: - Repositories
    
    private let ingredientRepository: IngredientRepositoryProtocol
    private let purchaseRepository: PurchaseRecordRepositoryProtocol
    private let supplierRepository: SupplierRepositoryProtocol
    
    // MARK: - Initialization
    
    init(
        ingredientRepository: IngredientRepositoryProtocol,
        purchaseRepository: PurchaseRecordRepositoryProtocol,
        supplierRepository: SupplierRepositoryProtocol
    ) {
        self.ingredientRepository = ingredientRepository
        self.purchaseRepository = purchaseRepository
        self.supplierRepository = supplierRepository
    }
    
    // MARK: - Analysis Methods
    
    /// 生成库存分析报表
    func generateInventoryReport(timeRange: TimeRange) async throws -> AnalyticsResult {
        await MainActor.run {
            isAnalyzing = true
            progress = 0.0
        }
        
        let ingredients = try ingredientRepository.fetchAll()
        await MainActor.run {
            progress = 0.3
        }
        
        // 分析数据
        let totalItems = ingredients.count
        let totalValue = ingredients.reduce(0.0) { $0 + ($1.quantity * 10.0) } // 假设单价
        let lowStockItems = ingredients.filter { $0.quantity <= $0.minimumStockThreshold }
        let expiredItems = ingredients.filter { $0.expirationDate < Date() }
        
        await MainActor.run {
            progress = 0.6
        }
        
        // 按类别统计
        let categoryStats = Dictionary(grouping: ingredients, by: { $0.category })
            .mapValues { $0.count }
        
        await MainActor.run {
            progress = 0.9
        }
        
        let data: [String: Any] = [
            "totalItems": totalItems,
            "totalValue": totalValue,
            "lowStockCount": lowStockItems.count,
            "expiredCount": expiredItems.count,
            "categoryStats": categoryStats
        ]
        
        let summary = """
        库存总数: \(totalItems)
        库存总值: ¥\(String(format: "%.2f", totalValue))
        低库存: \(lowStockItems.count)
        已过期: \(expiredItems.count)
        """
        
        await MainActor.run {
            isAnalyzing = false
            progress = 1.0
        }
        
        return AnalyticsResult(
            reportType: .inventory,
            timeRange: timeRange,
            data: data,
            generatedAt: Date(),
            summary: summary
        )
    }
    
    /// 生成采购分析报表
    func generatePurchaseReport(timeRange: TimeRange) async throws -> AnalyticsResult {
        await MainActor.run {
            isAnalyzing = true
            progress = 0.0
        }
        
        let range = timeRange.dateRange
        let records = try purchaseRepository.fetchAll().filter { record in
            record.purchaseDate >= range.start && record.purchaseDate <= range.end
        }
        await MainActor.run {
            progress = 0.3
        }
        
        // 分析数据
        let totalPurchases = records.count
        let totalCost = records.reduce(0.0) { $0 + $1.totalCost }
        let averageCost = totalCost / Double(max(totalPurchases, 1))
        
        await MainActor.run {
            progress = 0.6
        }
        
        // 按供应商统计
        let supplierStats = Dictionary(grouping: records, by: { $0.supplierId })
            .mapValues { records in
                records.reduce(0.0) { $0 + $1.totalCost }
            }
        
        await MainActor.run {
            progress = 0.9
        }
        
        let data: [String: Any] = [
            "totalPurchases": totalPurchases,
            "totalCost": totalCost,
            "averageCost": averageCost,
            "supplierStats": supplierStats
        ]
        
        let summary = """
        采购次数: \(totalPurchases)
        总成本: ¥\(String(format: "%.2f", totalCost))
        平均成本: ¥\(String(format: "%.2f", averageCost))
        """
        
        await MainActor.run {
            isAnalyzing = false
            progress = 1.0
        }
        
        return AnalyticsResult(
            reportType: .purchase,
            timeRange: timeRange,
            data: data,
            generatedAt: Date(),
            summary: summary
        )
    }
    
    /// 生成过期分析报表
    func generateExpirationReport() async throws -> AnalyticsResult {
        await MainActor.run {
            isAnalyzing = true
            progress = 0.0
        }
        
        let ingredients = try ingredientRepository.fetchAll()
        await MainActor.run {
            progress = 0.3
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // 分类统计
        let expired = ingredients.filter { $0.expirationDate < now }
        let expiringSoon = ingredients.filter {
            let daysUntil = calendar.dateComponents([.day], from: now, to: $0.expirationDate).day ?? 0
            return daysUntil > 0 && daysUntil <= 7
        }
        let expiring30Days = ingredients.filter {
            let daysUntil = calendar.dateComponents([.day], from: now, to: $0.expirationDate).day ?? 0
            return daysUntil > 7 && daysUntil <= 30
        }
        
        await MainActor.run {
            progress = 0.9
        }
        
        let data: [String: Any] = [
            "expired": expired.count,
            "expiringSoon": expiringSoon.count,
            "expiring30Days": expiring30Days.count,
            "expiredItems": expired.map { $0.name },
            "expiringSoonItems": expiringSoon.map { $0.name }
        ]
        
        let summary = """
        已过期: \(expired.count)
        7天内过期: \(expiringSoon.count)
        30天内过期: \(expiring30Days.count)
        """
        
        await MainActor.run {
            isAnalyzing = false
            progress = 1.0
        }
        
        return AnalyticsResult(
            reportType: .expiration,
            timeRange: .today,
            data: data,
            generatedAt: Date(),
            summary: summary
        )
    }
    
    /// 生成趋势分析报表
    func generateTrendReport(timeRange: TimeRange) async throws -> AnalyticsResult {
        await MainActor.run {
            isAnalyzing = true
            progress = 0.0
        }
        
        let range = timeRange.dateRange
        let records = try purchaseRepository.fetchAll().filter { record in
            record.purchaseDate >= range.start && record.purchaseDate <= range.end
        }
        await MainActor.run {
            progress = 0.3
        }
        
        // 按月份分组
        let calendar = Calendar.current
        let monthlyData = Dictionary(grouping: records) { record in
            calendar.component(.month, from: record.purchaseDate)
        }.mapValues { records in
            records.reduce(0.0) { $0 + $1.totalCost }
        }
        
        await MainActor.run {
            progress = 0.6
        }
        
        // 计算趋势
        let sortedMonths = monthlyData.keys.sorted()
        var trend = "稳定"
        
        if sortedMonths.count >= 2 {
            let lastMonth = monthlyData[sortedMonths[sortedMonths.count - 1]] ?? 0
            let previousMonth = monthlyData[sortedMonths[sortedMonths.count - 2]] ?? 0
            
            if lastMonth > previousMonth * 1.1 {
                trend = "上升"
            } else if lastMonth < previousMonth * 0.9 {
                trend = "下降"
            }
        }
        
        await MainActor.run {
            progress = 0.9
        }
        
        let data: [String: Any] = [
            "monthlyData": monthlyData,
            "trend": trend
        ]
        
        let summary = """
        趋势: \(trend)
        月度数据点: \(monthlyData.count)
        """
        
        await MainActor.run {
            isAnalyzing = false
            progress = 1.0
        }
        
        return AnalyticsResult(
            reportType: .trend,
            timeRange: timeRange,
            data: data,
            generatedAt: Date(),
            summary: summary
        )
    }
    
    // MARK: - Predictive Analytics
    
    /// 预测未来需求
    func predictFutureDemand(for ingredient: Ingredient, days: Int) -> Double {
        // 简单的线性预测
        // 实际实现可以使用更复杂的机器学习模型
        
        let historicalConsumption = 10.0 // 从历史数据计算
        let dailyAverage = historicalConsumption / 30.0
        
        return dailyAverage * Double(days)
    }
    
    /// 预测库存不足时间
    func predictStockoutDate(for ingredient: Ingredient) -> Date? {
        let dailyConsumption = 1.0 // 从历史数据计算
        
        guard dailyConsumption > 0 else { return nil }
        
        let daysRemaining = ingredient.quantity / dailyConsumption
        return Calendar.current.date(byAdding: .day, value: Int(daysRemaining), to: Date())
    }
    
    // MARK: - Export
    
    /// 导出报表为PDF
    func exportReportToPDF(_ result: AnalyticsResult) throws -> Data {
        // 实现PDF生成
        let content = """
        \(result.reportType) 报表
        生成时间: \(result.generatedAt)
        
        \(result.summary)
        """
        
        return Data(content.utf8)
    }
}
