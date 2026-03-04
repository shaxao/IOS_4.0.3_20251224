//
//  SupplierRepository.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  Repository for managing Supplier data persistence
//

import CoreData
import Foundation
import os.log

/// 供应商仓储协议
protocol SupplierRepositoryProtocol {
    func fetchAll() async throws -> [Supplier]
    func fetch(by id: UUID) async throws -> Supplier?
    func create(_ supplier: Supplier) async throws
    func update(_ supplier: Supplier) async throws
    func delete(_ supplier: Supplier) async throws
    func fetchIngredients(for supplier: Supplier) async throws -> [Ingredient]
    func canDelete(_ supplier: Supplier) async throws -> Bool
}

/// 供应商仓储实现
/// 满足需求：12.1, 12.2, 12.4, 12.5, 12.6
class SupplierRepository: SupplierRepositoryProtocol {
    static let shared = SupplierRepository()
    private let persistenceController: PersistenceController
    private let logger = Logger(subsystem: "com.restaurant.ingredientmanager", category: "SupplierRepository")
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Fetch Operations
    
    /// 获取所有供应商
    /// 满足需求：12.3
    func fetchAll() async throws -> [Supplier] {
        logger.info("开始获取所有供应商")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<SupplierEntity> = SupplierEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \SupplierEntity.name, ascending: true)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                let suppliers = entities.compactMap { Supplier(from: $0) }
                self.logger.info("成功获取 \(suppliers.count) 个供应商")
                return suppliers
            } catch {
                self.logger.error("获取所有供应商失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 根据ID获取供应商
    /// 满足需求：12.1
    func fetch(by id: UUID) async throws -> Supplier? {
        logger.info("开始获取供应商，ID: \(id.uuidString)")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<SupplierEntity> = SupplierEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let entities = try context.fetch(fetchRequest)
                if let entity = entities.first {
                    let supplier = Supplier(from: entity)
                    self.logger.info("成功获取供应商: \(entity.name ?? "unknown")")
                    return supplier
                } else {
                    self.logger.info("未找到ID为 \(id.uuidString) 的供应商")
                    return nil
                }
            } catch {
                self.logger.error("获取供应商失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 获取供应商关联的所有食材
    /// 满足需求：12.2, 12.4
    func fetchIngredients(for supplier: Supplier) async throws -> [Ingredient] {
        logger.info("开始获取供应商关联的食材，供应商: \(supplier.name)")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<IngredientEntity> = IngredientEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "supplier.id == %@", supplier.id as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \IngredientEntity.name, ascending: true)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                let ingredients = entities.compactMap { Ingredient(from: $0) }
                self.logger.info("找到 \(ingredients.count) 个关联食材")
                return ingredients
            } catch {
                self.logger.error("获取供应商关联食材失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 检查供应商是否可以删除（没有关联食材）
    /// 满足需求：12.6
    func canDelete(_ supplier: Supplier) async throws -> Bool {
        logger.info("检查供应商是否可以删除: \(supplier.name)")
        
        let ingredients = try await fetchIngredients(for: supplier)
        let canDelete = ingredients.isEmpty
        
        logger.info("供应商 \(supplier.name) \(canDelete ? "可以" : "不能")删除")
        return canDelete
    }
    
    // MARK: - Create, Update, Delete Operations
    
    /// 创建新供应商
    /// 满足需求：12.1
    func create(_ supplier: Supplier) async throws {
        logger.info("开始创建供应商: \(supplier.name)")
        
        // 验证数据
        do {
            try supplier.validate()
        } catch {
            logger.error("供应商数据验证失败: \(error.localizedDescription)")
            throw RepositoryError.createFailed(error)
        }
        
        try await persistenceController.performBackgroundTaskAsync { context in
            do {
                // 创建实体
                _ = supplier.toEntity(context: context)
                
                // 保存上下文
                if context.hasChanges {
                    try context.save()
                    self.logger.info("成功创建供应商: \(supplier.name)")
                }
            } catch {
                self.logger.error("创建供应商失败: \(error.localizedDescription)")
                throw RepositoryError.createFailed(error)
            }
        }
    }
    
    /// 更新供应商
    /// 满足需求：12.5
    func update(_ supplier: Supplier) async throws {
        logger.info("开始更新供应商: \(supplier.name)")
        
        // 验证数据
        do {
            try supplier.validate()
        } catch {
            logger.error("供应商数据验证失败: \(error.localizedDescription)")
            throw RepositoryError.updateFailed(error)
        }
        
        try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<SupplierEntity> = SupplierEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", supplier.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let entities = try context.fetch(fetchRequest)
                guard let entity = entities.first else {
                    self.logger.error("未找到要更新的供应商: \(supplier.id.uuidString)")
                    throw RepositoryError.notFound
                }
                
                // 更新实体属性
                entity.name = supplier.name
                entity.contactPerson = supplier.contactPerson
                entity.phone = supplier.phone
                entity.email = supplier.email
                entity.address = supplier.address
                entity.notes = supplier.notes
                
                // 保存上下文
                if context.hasChanges {
                    try context.save()
                    self.logger.info("成功更新供应商: \(supplier.name)")
                }
            } catch {
                self.logger.error("更新供应商失败: \(error.localizedDescription)")
                throw RepositoryError.updateFailed(error)
            }
        }
    }
    
    /// 删除供应商（仅当没有关联食材时）
    /// 满足需求：12.6
    func delete(_ supplier: Supplier) async throws {
        logger.info("开始删除供应商: \(supplier.name)")
        
        // 检查是否可以删除
        let canDelete = try await canDelete(supplier)
        guard canDelete else {
            logger.error("供应商 \(supplier.name) 有关联食材，无法删除")
            throw RepositoryError.deleteFailed(SupplierDeletionError.hasAssociatedIngredients)
        }
        
        try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<SupplierEntity> = SupplierEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", supplier.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let entities = try context.fetch(fetchRequest)
                guard let entity = entities.first else {
                    self.logger.error("未找到要删除的供应商: \(supplier.id.uuidString)")
                    throw RepositoryError.notFound
                }
                
                context.delete(entity)
                
                // 保存上下文
                if context.hasChanges {
                    try context.save()
                    self.logger.info("成功删除供应商: \(supplier.name)")
                }
            } catch {
                self.logger.error("删除供应商失败: \(error.localizedDescription)")
                throw RepositoryError.deleteFailed(error)
            }
        }
    }
}

/// 供应商删除错误
enum SupplierDeletionError: LocalizedError {
    case hasAssociatedIngredients
    
    var errorDescription: String? {
        switch self {
        case .hasAssociatedIngredients:
            return "无法删除供应商：该供应商有关联的食材"
        }
    }
}
