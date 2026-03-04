//
//  PurchaseRecordRepository.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  Repository for managing PurchaseRecord data persistence
//

import CoreData
import Foundation
import os.log

/// 采购记录查询条件
struct PurchaseRecordQueryCriteria {
    var ingredientIds: [UUID]?
    var supplierIds: [UUID]?
    var dateRange: ClosedRange<Date>?
}

/// 成本聚合结果
struct CostAggregation {
    var totalCost: Double
    var recordCount: Int
    var averageCost: Double
    
    init(totalCost: Double, recordCount: Int) {
        self.totalCost = totalCost
        self.recordCount = recordCount
        self.averageCost = recordCount > 0 ? totalCost / Double(recordCount) : 0
    }
}

/// 按类别的成本聚合
struct CategoryCostSummary {
    var category: Category
    var totalCost: Double
    var recordCount: Int
}

/// 按供应商的成本聚合
struct SupplierCostSummary {
    var supplierId: UUID
    var supplierName: String
    var totalCost: Double
    var recordCount: Int
}

/// 采购记录仓储协议
protocol PurchaseRecordRepositoryProtocol {
    func fetchAll() async throws -> [PurchaseRecord]
    func fetch(by id: UUID) async throws -> PurchaseRecord?
    func create(_ record: PurchaseRecord) async throws
    func update(_ record: PurchaseRecord) async throws
    func delete(_ record: PurchaseRecord) async throws
    func query(by criteria: PurchaseRecordQueryCriteria) async throws -> [PurchaseRecord]
    func fetchRecords(for ingredient: Ingredient) async throws -> [PurchaseRecord]
    func fetchRecords(for supplier: Supplier) async throws -> [PurchaseRecord]
    func calculateTotalCost(by criteria: PurchaseRecordQueryCriteria) async throws -> CostAggregation
    func calculateCostByCategory(dateRange: ClosedRange<Date>?) async throws -> [CategoryCostSummary]
    func calculateCostBySupplier(dateRange: ClosedRange<Date>?) async throws -> [SupplierCostSummary]
    func exportData(by criteria: PurchaseRecordQueryCriteria) async throws -> Data
}

/// 采购记录仓储实现
/// 满足需求：13.1, 13.2, 13.3, 13.4, 13.5, 13.6
class PurchaseRecordRepository: PurchaseRecordRepositoryProtocol {
    static let shared = PurchaseRecordRepository()
    private let persistenceController: PersistenceController
    private let logger = Logger(subsystem: "com.restaurant.ingredientmanager", category: "PurchaseRecordRepository")
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Fetch Operations
    
    /// 获取所有采购记录
    /// 满足需求：13.2
    func fetchAll() async throws -> [PurchaseRecord] {
        logger.info("开始获取所有采购记录")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<PurchaseRecordEntity> = PurchaseRecordEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PurchaseRecordEntity.purchaseDate, ascending: false)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                let records = entities.compactMap { PurchaseRecord(from: $0) }
                self.logger.info("成功获取 \(records.count) 条采购记录")
                return records
            } catch {
                self.logger.error("获取所有采购记录失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 根据ID获取采购记录
    /// 满足需求：13.1
    func fetch(by id: UUID) async throws -> PurchaseRecord? {
        logger.info("开始获取采购记录，ID: \(id.uuidString)")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<PurchaseRecordEntity> = PurchaseRecordEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let entities = try context.fetch(fetchRequest)
                if let entity = entities.first {
                    let record = PurchaseRecord(from: entity)
                    self.logger.info("成功获取采购记录")
                    return record
                } else {
                    self.logger.info("未找到ID为 \(id.uuidString) 的采购记录")
                    return nil
                }
            } catch {
                self.logger.error("获取采购记录失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 根据条件查询采购记录
    /// 满足需求：13.2
    func query(by criteria: PurchaseRecordQueryCriteria) async throws -> [PurchaseRecord] {
        logger.info("开始查询采购记录")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<PurchaseRecordEntity> = PurchaseRecordEntity.fetchRequest()
            var predicates: [NSPredicate] = []
            
            // 按食材筛选
            if let ingredientIds = criteria.ingredientIds, !ingredientIds.isEmpty {
                predicates.append(NSPredicate(format: "ingredient.id IN %@", ingredientIds))
            }
            
            // 按供应商筛选
            if let supplierIds = criteria.supplierIds, !supplierIds.isEmpty {
                predicates.append(NSPredicate(format: "supplier.id IN %@", supplierIds))
            }
            
            // 按时间范围筛选
            if let dateRange = criteria.dateRange {
                predicates.append(NSPredicate(
                    format: "purchaseDate >= %@ AND purchaseDate <= %@",
                    dateRange.lowerBound as NSDate,
                    dateRange.upperBound as NSDate
                ))
            }
            
            // 组合所有筛选条件
            if !predicates.isEmpty {
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \PurchaseRecordEntity.purchaseDate, ascending: false)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                let records = entities.compactMap { PurchaseRecord(from: $0) }
                self.logger.info("查询到 \(records.count) 条采购记录")
                return records
            } catch {
                self.logger.error("查询采购记录失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 获取指定食材的采购记录
    /// 满足需求：13.2
    func fetchRecords(for ingredient: Ingredient) async throws -> [PurchaseRecord] {
        logger.info("开始获取食材的采购记录: \(ingredient.name)")
        
        let criteria = PurchaseRecordQueryCriteria(ingredientIds: [ingredient.id])
        return try await query(by: criteria)
    }
    
    /// 获取指定供应商的采购记录
    /// 满足需求：13.2
    func fetchRecords(for supplier: Supplier) async throws -> [PurchaseRecord] {
        logger.info("开始获取供应商的采购记录: \(supplier.name)")
        
        let criteria = PurchaseRecordQueryCriteria(supplierIds: [supplier.id])
        return try await query(by: criteria)
    }
    
    // MARK: - Cost Aggregation
    
    /// 计算总成本
    /// 满足需求：13.3
    func calculateTotalCost(by criteria: PurchaseRecordQueryCriteria) async throws -> CostAggregation {
        logger.info("开始计算总成本")
        
        let records = try await query(by: criteria)
        let totalCost = records.reduce(0.0) { $0 + $1.totalCost }
        let aggregation = CostAggregation(totalCost: totalCost, recordCount: records.count)
        
        logger.info("计算完成：总成本 \(totalCost)，记录数 \(records.count)")
        return aggregation
    }
    
    /// 按类别计算成本
    /// 满足需求：13.4
    func calculateCostByCategory(dateRange: ClosedRange<Date>?) async throws -> [CategoryCostSummary] {
        logger.info("开始按类别计算成本")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<PurchaseRecordEntity> = PurchaseRecordEntity.fetchRequest()
            
            // 按时间范围筛选
            if let dateRange = dateRange {
                fetchRequest.predicate = NSPredicate(
                    format: "purchaseDate >= %@ AND purchaseDate <= %@",
                    dateRange.lowerBound as NSDate,
                    dateRange.upperBound as NSDate
                )
            }
            
            do {
                let entities = try context.fetch(fetchRequest)
                
                // 按类别分组并计算成本
                var categoryMap: [String: (totalCost: Double, count: Int)] = [:]
                
                for entity in entities {
                    guard let categoryString = entity.ingredient?.category else { continue }
                    
                    let current = categoryMap[categoryString] ?? (totalCost: 0.0, count: 0)
                    categoryMap[categoryString] = (
                        totalCost: current.totalCost + entity.totalCost,
                        count: current.count + 1
                    )
                }
                
                // 转换为结果数组
                let summaries = categoryMap.compactMap { (categoryString, data) -> CategoryCostSummary? in
                    guard let category = Category(rawValue: categoryString) else { return nil }
                    return CategoryCostSummary(
                        category: category,
                        totalCost: data.totalCost,
                        recordCount: data.count
                    )
                }.sorted { $0.totalCost > $1.totalCost }
                
                self.logger.info("按类别计算完成，共 \(summaries.count) 个类别")
                return summaries
            } catch {
                self.logger.error("按类别计算成本失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 按供应商计算成本
    /// 满足需求：13.5
    func calculateCostBySupplier(dateRange: ClosedRange<Date>?) async throws -> [SupplierCostSummary] {
        logger.info("开始按供应商计算成本")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<PurchaseRecordEntity> = PurchaseRecordEntity.fetchRequest()
            
            // 按时间范围筛选
            if let dateRange = dateRange {
                fetchRequest.predicate = NSPredicate(
                    format: "purchaseDate >= %@ AND purchaseDate <= %@",
                    dateRange.lowerBound as NSDate,
                    dateRange.upperBound as NSDate
                )
            }
            
            do {
                let entities = try context.fetch(fetchRequest)
                
                // 按供应商分组并计算成本
                var supplierMap: [UUID: (name: String, totalCost: Double, count: Int)] = [:]
                
                for entity in entities {
                    guard let supplier = entity.supplier,
                          let supplierId = supplier.id,
                          let supplierName = supplier.name else { continue }
                    
                    let current = supplierMap[supplierId] ?? (name: supplierName, totalCost: 0.0, count: 0)
                    supplierMap[supplierId] = (
                        name: supplierName,
                        totalCost: current.totalCost + entity.totalCost,
                        count: current.count + 1
                    )
                }
                
                // 转换为结果数组
                let summaries = supplierMap.map { (supplierId, data) in
                    SupplierCostSummary(
                        supplierId: supplierId,
                        supplierName: data.name,
                        totalCost: data.totalCost,
                        recordCount: data.count
                    )
                }.sorted { $0.totalCost > $1.totalCost }
                
                self.logger.info("按供应商计算完成，共 \(summaries.count) 个供应商")
                return summaries
            } catch {
                self.logger.error("按供应商计算成本失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    // MARK: - Data Export
    
    /// 导出采购数据为CSV格式
    /// 满足需求：13.6
    func exportData(by criteria: PurchaseRecordQueryCriteria) async throws -> Data {
        logger.info("开始导出采购数据")
        
        let records = try await query(by: criteria)
        
        // 创建CSV内容
        var csvString = "ID,食材ID,供应商ID,数量,单价,总成本,采购日期,备注\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for record in records {
            let notes = record.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            let line = "\(record.id.uuidString),\(record.ingredientId.uuidString),\(record.supplierId.uuidString),\(record.quantity),\(record.unitCost),\(record.totalCost),\(dateFormatter.string(from: record.purchaseDate)),\(notes)\n"
            csvString.append(line)
        }
        
        guard let data = csvString.data(using: .utf8) else {
            logger.error("导出数据转换失败")
            throw RepositoryError.invalidData
        }
        
        logger.info("成功导出 \(records.count) 条采购记录")
        return data
    }
    
    // MARK: - Create, Update, Delete Operations
    
    /// 创建新采购记录
    /// 满足需求：13.1
    func create(_ record: PurchaseRecord) async throws {
        logger.info("开始创建采购记录")
        
        // 验证数据
        do {
            try record.validate()
        } catch {
            logger.error("采购记录数据验证失败: \(error.localizedDescription)")
            throw RepositoryError.createFailed(error)
        }
        
        try await persistenceController.performBackgroundTaskAsync { context in
            do {
                // 查找关联的食材和供应商
                let ingredientFetch: NSFetchRequest<IngredientEntity> = IngredientEntity.fetchRequest()
                ingredientFetch.predicate = NSPredicate(format: "id == %@", record.ingredientId as CVarArg)
                ingredientFetch.fetchLimit = 1
                
                let supplierFetch: NSFetchRequest<SupplierEntity> = SupplierEntity.fetchRequest()
                supplierFetch.predicate = NSPredicate(format: "id == %@", record.supplierId as CVarArg)
                supplierFetch.fetchLimit = 1
                
                guard let ingredient = try context.fetch(ingredientFetch).first else {
                    self.logger.error("未找到关联的食材: \(record.ingredientId.uuidString)")
                    throw RepositoryError.invalidData
                }
                
                guard let supplier = try context.fetch(supplierFetch).first else {
                    self.logger.error("未找到关联的供应商: \(record.supplierId.uuidString)")
                    throw RepositoryError.invalidData
                }
                
                // 创建实体
                _ = record.toEntity(context: context, ingredient: ingredient, supplier: supplier)
                
                // 保存上下文
                if context.hasChanges {
                    try context.save()
                    self.logger.info("成功创建采购记录")
                }
            } catch {
                self.logger.error("创建采购记录失败: \(error.localizedDescription)")
                throw RepositoryError.createFailed(error)
            }
        }
    }
    
    /// 更新采购记录
    /// 满足需求：13.1
    func update(_ record: PurchaseRecord) async throws {
        logger.info("开始更新采购记录")
        
        // 验证数据
        do {
            try record.validate()
        } catch {
            logger.error("采购记录数据验证失败: \(error.localizedDescription)")
            throw RepositoryError.updateFailed(error)
        }
        
        try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<PurchaseRecordEntity> = PurchaseRecordEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", record.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let entities = try context.fetch(fetchRequest)
                guard let entity = entities.first else {
                    self.logger.error("未找到要更新的采购记录: \(record.id.uuidString)")
                    throw RepositoryError.notFound
                }
                
                // 更新实体属性
                entity.quantity = record.quantity
                entity.unitCost = record.unitCost
                entity.totalCost = record.totalCost
                entity.purchaseDate = record.purchaseDate
                entity.notes = record.notes
                
                // 更新关联（如果需要）
                if entity.ingredient?.id != record.ingredientId {
                    let ingredientFetch: NSFetchRequest<IngredientEntity> = IngredientEntity.fetchRequest()
                    ingredientFetch.predicate = NSPredicate(format: "id == %@", record.ingredientId as CVarArg)
                    ingredientFetch.fetchLimit = 1
                    
                    if let ingredient = try context.fetch(ingredientFetch).first {
                        entity.ingredient = ingredient
                    }
                }
                
                if entity.supplier?.id != record.supplierId {
                    let supplierFetch: NSFetchRequest<SupplierEntity> = SupplierEntity.fetchRequest()
                    supplierFetch.predicate = NSPredicate(format: "id == %@", record.supplierId as CVarArg)
                    supplierFetch.fetchLimit = 1
                    
                    if let supplier = try context.fetch(supplierFetch).first {
                        entity.supplier = supplier
                    }
                }
                
                // 保存上下文
                if context.hasChanges {
                    try context.save()
                    self.logger.info("成功更新采购记录")
                }
            } catch {
                self.logger.error("更新采购记录失败: \(error.localizedDescription)")
                throw RepositoryError.updateFailed(error)
            }
        }
    }
    
    /// 删除采购记录
    /// 满足需求：13.1
    func delete(_ record: PurchaseRecord) async throws {
        logger.info("开始删除采购记录")
        
        try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<PurchaseRecordEntity> = PurchaseRecordEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", record.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let entities = try context.fetch(fetchRequest)
                guard let entity = entities.first else {
                    self.logger.error("未找到要删除的采购记录: \(record.id.uuidString)")
                    throw RepositoryError.notFound
                }
                
                context.delete(entity)
                
                // 保存上下文
                if context.hasChanges {
                    try context.save()
                    self.logger.info("成功删除采购记录")
                }
            } catch {
                self.logger.error("删除采购记录失败: \(error.localizedDescription)")
                throw RepositoryError.deleteFailed(error)
            }
        }
    }
}
