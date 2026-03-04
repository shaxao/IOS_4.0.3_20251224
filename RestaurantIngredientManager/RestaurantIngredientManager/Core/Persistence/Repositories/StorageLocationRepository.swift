//
//  StorageLocationRepository.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  Repository for managing StorageLocation data persistence
//

import CoreData
import Foundation
import os.log

/// 存储位置仓储协议
protocol StorageLocationRepositoryProtocol {
    func fetchAll() async throws -> [StorageLocation]
    func fetch(by id: UUID) async throws -> StorageLocation?
    func create(_ location: StorageLocation) async throws
    func update(_ location: StorageLocation) async throws
    func delete(_ location: StorageLocation) async throws
    func fetchIngredients(for location: StorageLocation) async throws -> [Ingredient]
    func canDelete(_ location: StorageLocation) async throws -> Bool
}

/// 存储位置仓储实现
/// 满足需求：11.2, 11.3, 11.4, 11.5
class StorageLocationRepository: StorageLocationRepositoryProtocol {
    private let persistenceController: PersistenceController
    private let logger = Logger(subsystem: "com.restaurant.ingredientmanager", category: "StorageLocationRepository")
    
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }
    
    // MARK: - Fetch Operations
    
    /// 获取所有存储位置
    /// 满足需求：11.1
    func fetchAll() async throws -> [StorageLocation] {
        logger.info("开始获取所有存储位置")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<StorageLocationEntity> = StorageLocationEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \StorageLocationEntity.name, ascending: true)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                let locations = entities.compactMap { StorageLocation(from: $0) }
                self.logger.info("成功获取 \(locations.count) 个存储位置")
                return locations
            } catch {
                self.logger.error("获取所有存储位置失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 根据ID获取存储位置
    /// 满足需求：11.3
    func fetch(by id: UUID) async throws -> StorageLocation? {
        logger.info("开始获取存储位置，ID: \(id.uuidString)")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<StorageLocationEntity> = StorageLocationEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let entities = try context.fetch(fetchRequest)
                if let entity = entities.first {
                    let location = StorageLocation(from: entity)
                    self.logger.info("成功获取存储位置: \(entity.name ?? "unknown")")
                    return location
                } else {
                    self.logger.info("未找到ID为 \(id.uuidString) 的存储位置")
                    return nil
                }
            } catch {
                self.logger.error("获取存储位置失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 获取存储位置关联的所有食材
    /// 满足需求：11.4
    func fetchIngredients(for location: StorageLocation) async throws -> [Ingredient] {
        logger.info("开始获取存储位置关联的食材，位置: \(location.name)")
        
        return try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<IngredientEntity> = IngredientEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "storageLocation.id == %@", location.id as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \IngredientEntity.name, ascending: true)]
            
            do {
                let entities = try context.fetch(fetchRequest)
                let ingredients = entities.compactMap { Ingredient(from: $0) }
                self.logger.info("找到 \(ingredients.count) 个关联食材")
                return ingredients
            } catch {
                self.logger.error("获取存储位置关联食材失败: \(error.localizedDescription)")
                throw RepositoryError.fetchFailed(error)
            }
        }
    }
    
    /// 检查存储位置是否可以删除（没有关联食材）
    /// 满足需求：11.5
    func canDelete(_ location: StorageLocation) async throws -> Bool {
        logger.info("检查存储位置是否可以删除: \(location.name)")
        
        let ingredients = try await fetchIngredients(for: location)
        let canDelete = ingredients.isEmpty
        
        logger.info("存储位置 \(location.name) \(canDelete ? "可以" : "不能")删除")
        return canDelete
    }
    
    // MARK: - Create, Update, Delete Operations
    
    /// 创建新存储位置
    /// 满足需求：11.2
    func create(_ location: StorageLocation) async throws {
        logger.info("开始创建存储位置: \(location.name)")
        
        // 验证数据
        do {
            try location.validate()
        } catch {
            logger.error("存储位置数据验证失败: \(error.localizedDescription)")
            throw RepositoryError.createFailed(error)
        }
        
        try await persistenceController.performBackgroundTaskAsync { context in
            do {
                // 创建实体
                _ = location.toEntity(context: context)
                
                // 保存上下文
                if context.hasChanges {
                    try context.save()
                    self.logger.info("成功创建存储位置: \(location.name)")
                }
            } catch {
                self.logger.error("创建存储位置失败: \(error.localizedDescription)")
                throw RepositoryError.createFailed(error)
            }
        }
    }
    
    /// 更新存储位置
    /// 满足需求：11.5
    func update(_ location: StorageLocation) async throws {
        logger.info("开始更新存储位置: \(location.name)")
        
        // 验证数据
        do {
            try location.validate()
        } catch {
            logger.error("存储位置数据验证失败: \(error.localizedDescription)")
            throw RepositoryError.updateFailed(error)
        }
        
        try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<StorageLocationEntity> = StorageLocationEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", location.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let entities = try context.fetch(fetchRequest)
                guard let entity = entities.first else {
                    self.logger.error("未找到要更新的存储位置: \(location.id.uuidString)")
                    throw RepositoryError.notFound
                }
                
                // 更新实体属性
                entity.name = location.name
                entity.type = location.type.rawValue
                entity.temperature = location.temperature ?? 0
                entity.isCustom = location.isCustom
                
                // 保存上下文
                if context.hasChanges {
                    try context.save()
                    self.logger.info("成功更新存储位置: \(location.name)")
                }
            } catch {
                self.logger.error("更新存储位置失败: \(error.localizedDescription)")
                throw RepositoryError.updateFailed(error)
            }
        }
    }
    
    /// 删除存储位置（仅当没有关联食材时）
    /// 满足需求：11.5, 11.6
    func delete(_ location: StorageLocation) async throws {
        logger.info("开始删除存储位置: \(location.name)")
        
        // 检查是否可以删除
        let canDelete = try await canDelete(location)
        guard canDelete else {
            logger.error("存储位置 \(location.name) 有关联食材，无法删除")
            throw RepositoryError.deleteFailed(StorageLocationDeletionError.hasAssociatedIngredients)
        }
        
        try await persistenceController.performBackgroundTaskAsync { context in
            let fetchRequest: NSFetchRequest<StorageLocationEntity> = StorageLocationEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", location.id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            do {
                let entities = try context.fetch(fetchRequest)
                guard let entity = entities.first else {
                    self.logger.error("未找到要删除的存储位置: \(location.id.uuidString)")
                    throw RepositoryError.notFound
                }
                
                context.delete(entity)
                
                // 保存上下文
                if context.hasChanges {
                    try context.save()
                    self.logger.info("成功删除存储位置: \(location.name)")
                }
            } catch {
                self.logger.error("删除存储位置失败: \(error.localizedDescription)")
                throw RepositoryError.deleteFailed(error)
            }
        }
    }
}

/// 存储位置删除错误
enum StorageLocationDeletionError: LocalizedError {
    case hasAssociatedIngredients
    
    var errorDescription: String? {
        switch self {
        case .hasAssociatedIngredients:
            return "无法删除存储位置：该位置有关联的食材"
        }
    }
}
