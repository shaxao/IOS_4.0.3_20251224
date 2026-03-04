//
//  IngredientRepository.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  Repository for managing Ingredient data persistence
//

import CoreData
import Foundation
import os.log

/// 筛选条件
struct FilterCriteria {
    var categories: [Category]?
    var storageLocations: [UUID]?
    var expirationDateRange: ClosedRange<Date>?
    var suppliers: [UUID]?
}

/// 仓储错误类型
enum RepositoryError: LocalizedError {
    case fetchFailed(Error)
    case createFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case notFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let error):
            return "获取数据失败: \(error.localizedDescription)"
        case .createFailed(let error):
            return "创建数据失败: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "更新数据失败: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "删除数据失败: \(error.localizedDescription)"
        case .notFound:
            return "未找到数据"
        case .invalidData:
            return "数据无效"
        }
    }
}

/// 食材仓储协议
protocol IngredientRepositoryProtocol {
    func fetchAll() async throws -> [Ingredient]
    func fetch(by id: UUID) async throws -> Ingredient?
    func search(query: String) async throws -> [Ingredient]
    func filter(by criteria: FilterCriteria) async throws -> [Ingredient]
    func create(_ ingredient: Ingredient) async throws
    func update(_ ingredient: Ingredient) async throws
    func delete(_ ingredient: Ingredient) async throws
    func fetchExpiring(within days: Int) async throws -> [Ingredient]
    func fetchLowStock() async throws -> [Ingredient]
}

/// 食材仓储实现
/// 满足需求：1.1, 1.2, 1.3, 1.4, 2.2, 2.3, 2.4, 2.5, 2.6, 3.4, 4.3
class IngredientRepository: IngredientRepositoryProtocol {
    static let shared = IngredientRepository()
    private let persistenceController: PersistenceController
    private let logger = Logger(subsystem: "com.restaurant.ingredientmanager", category: "IngredientRepository")
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Fetch Operations
    
    /// 获取所有食材
    /// 满足需求：1.2
    func fetchAll() async throws -> [Ingredient] {
        logger.info("开始获取所有食材")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<IngredientEntity> = IngredientEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \IngredientEntity.name, ascending: true)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                let ingredients = entities.compactMap { Ingredient(from: $0) }
                self.logger.info("成功获取 \(ingredients.count) 个食材")
                return ingredients
            } catch {
                self.logger.error("获取所有食材失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 根据ID获取食材
    /// 满足需求：1.2
    func fetch(by id: UUID) async throws -> Ingredient? {
        logger.info("开始获取食材，ID: \(id.uuidString)")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<IngredientEntity> = IngredientEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let entities = try context.fetch(fetchRequest)
                if let entity = entities.first {
                    let ingredient = Ingredient(from: entity)
                    self.logger.info("成功获取食材: \(entity.name ?? "unknown")")
                    return ingredient
                } else {
                    self.logger.info("未找到ID为 \(id.uuidString) 的食材")
                    return nil
                }
            } catch {
                self.logger.error("获取食材失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 搜索食材（按名称、类别或供应商）
    /// 满足需求：2.2
    func search(query: String) async throws -> [Ingredient] {
        logger.info("开始搜索食材，查询: \(query)")
        
        guard !query.isEmpty else {
            return try await fetchAll()
        }
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<IngredientEntity> = IngredientEntity.fetchRequest()
            
            // 搜索名称、类别或供应商名称
            let namePredicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
            let categoryPredicate = NSPredicate(format: "category CONTAINS[cd] %@", query)
            let supplierPredicate = NSPredicate(format: "supplier.name CONTAINS[cd] %@", query)
            
            fetchRequest.predicate = NSCompoundPredicate(
                orPredicateWithSubpredicates: [namePredicate, categoryPredicate, supplierPredicate]
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \IngredientEntity.name, ascending: true)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                let ingredients = entities.compactMap { Ingredient(from: $0) }
                self.logger.info("搜索到 \(ingredients.count) 个食材")
                return ingredients
            } catch {
                self.logger.error("搜索食材失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 根据条件筛选食材
    /// 满足需求：2.3, 2.4, 2.5, 2.6
    func filter(by criteria: FilterCriteria) async throws -> [Ingredient] {
        logger.info("开始筛选食材")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<IngredientEntity> = IngredientEntity.fetchRequest()
            var predicates: [NSPredicate] = []
            
            // 按类别筛选
            if let categories = criteria.categories, !categories.isEmpty {
                let categoryStrings = categories.map { $0.rawValue }
                predicates.append(NSPredicate(format: "category IN %@", categoryStrings))
            }
            
            // 按存储位置筛选
            if let storageLocations = criteria.storageLocations, !storageLocations.isEmpty {
                predicates.append(NSPredicate(format: "storageLocation.id IN %@", storageLocations))
            }
            
            // 按保质期范围筛选
            if let dateRange = criteria.expirationDateRange {
                predicates.append(NSPredicate(
                    format: "expirationDate >= %@ AND expirationDate <= %@",
                    dateRange.lowerBound as NSDate,
                    dateRange.upperBound as NSDate
                ))
            }
            
            // 按供应商筛选
            if let suppliers = criteria.suppliers, !suppliers.isEmpty {
                predicates.append(NSPredicate(format: "supplier.id IN %@", suppliers))
            }
            
            // 组合所有筛选条件
            if !predicates.isEmpty {
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \IngredientEntity.name, ascending: true)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                let ingredients = entities.compactMap { Ingredient(from: $0) }
                self.logger.info("筛选到 \(ingredients.count) 个食材")
                return ingredients
            } catch {
                self.logger.error("筛选食材失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 获取即将过期的食材
    /// 满足需求：3.4
    func fetchExpiring(within days: Int) async throws -> [Ingredient] {
        logger.info("开始获取即将过期的食材，天数: \(days)")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<IngredientEntity> = IngredientEntity.fetchRequest()
            
            let now = Date()
            let calendar = Calendar.current
            guard let thresholdDate = calendar.date(byAdding: .day, value: days, to: now) else {
                throw RepositoryError.invalidData
            }
            
            // 查找保质期在当前日期和阈值日期之间的食材
            fetchRequest.predicate = NSPredicate(
                format: "expirationDate > %@ AND expirationDate <= %@",
                now as NSDate,
                thresholdDate as NSDate
            )
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \IngredientEntity.expirationDate, ascending: true)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                let ingredients = entities.compactMap { Ingredient(from: $0) }
                self.logger.info("找到 \(ingredients.count) 个即将过期的食材")
                return ingredients
            } catch {
                self.logger.error("获取即将过期食材失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 获取低库存食材
    /// 满足需求：4.3
    func fetchLowStock() async throws -> [Ingredient] {
        logger.info("开始获取低库存食材")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<IngredientEntity> = IngredientEntity.fetchRequest()
            
            // 查找数量低于最低库存阈值的食材
            fetchRequest.predicate = NSPredicate(format: "quantity < minimumStockThreshold AND quantity > 0")
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \IngredientEntity.quantity, ascending: true)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                let ingredients = entities.compactMap { Ingredient(from: $0) }
                self.logger.info("找到 \(ingredients.count) 个低库存食材")
                return ingredients
            } catch {
                self.logger.error("获取低库存食材失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    // MARK: - Create, Update, Delete Operations
    
    /// 创建新食材
    /// 满足需求：1.1, 1.6
    func create(_ ingredient: Ingredient) async throws {
        logger.info("开始创建食材: \(ingredient.name)")
        
        // 验证数据
        do {
            try ingredient.validate()
        } catch {
            logger.error("食材数据验证失败: \(error.localizedDescription)")
            throw RepositoryError.createFailed(error)
        }
        
        try await persistenceController.performBackgroundTaskAsync { context in
            do {
                // 创建实体
                _ = ingredient.toEntity(context: context)
                
                // 保存上下文
                if context.hasChanges {
                    try context.save()
                    self.logger.info("成功创建食材: \(ingredient.name)")
                }
            } catch {
                self.logger.error("创建食材失败: \(error.localizedDescription)")
                throw RepositoryError.createFailed(error)
            }
        }
    }
    
    /// 更新食材
    /// 满足需求：1.3, 1.6
    func update(_ ingredient: Ingredient) async throws {
        logger.info("开始更新食材: \(ingredient.name)")
        
        // 验证数据
        do {
            try ingredient.validate()
        } catch {
            logger.error("食材数据验证失败: \(error.localizedDescription)")
            throw RepositoryError.updateFailed(error)
        }
        
        try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<IngredientEntity> = IngredientEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", ingredient.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let entities = try context.fetch(fetchRequest)
                guard let entity = entities.first else {
                    self.logger.error("未找到要更新的食材: \(ingredient.id.uuidString)")
                    throw RepositoryError.notFound
                }
                
                // 更新实体属性
                entity.name = ingredient.name
                entity.category = ingredient.category.rawValue
                entity.quantity = ingredient.quantity
                entity.unit = ingredient.unit
                entity.expirationDate = ingredient.expirationDate
                entity.barcode = ingredient.barcode
                entity.qrCode = ingredient.qrCode
                entity.minimumStockThreshold = ingredient.minimumStockThreshold
                entity.notes = ingredient.notes
                entity.updatedAt = Date()
                
                // 更新关系
                entity.storageLocation = ingredient.storageLocation.toEntity(context: context)
                if let supplier = ingredient.supplier {
                    entity.supplier = supplier.toEntity(context: context)
                } else {
                    entity.supplier = nil
                }
                
                // 保存上下文
                if context.hasChanges {
                    try context.save()
                    self.logger.info("成功更新食材: \(ingredient.name)")
                }
            } catch {
                self.logger.error("更新食材失败: \(error.localizedDescription)")
                throw RepositoryError.updateFailed(error)
            }
        }
    }
    
    /// 删除食材
    /// 满足需求：1.4
    func delete(_ ingredient: Ingredient) async throws {
        logger.info("开始删除食材: \(ingredient.name)")
        
        try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<IngredientEntity> = IngredientEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", ingredient.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let entities = try context.fetch(fetchRequest)
                guard let entity = entities.first else {
                    self.logger.error("未找到要删除的食材: \(ingredient.id.uuidString)")
                    throw RepositoryError.notFound
                }
                
                context.delete(entity)
                
                // 保存上下文
                if context.hasChanges {
                    try context.save()
                    self.logger.info("成功删除食材: \(ingredient.name)")
                }
            } catch {
                self.logger.error("删除食材失败: \(error.localizedDescription)")
                throw RepositoryError.deleteFailed(error)
            }
        }
    }
}
