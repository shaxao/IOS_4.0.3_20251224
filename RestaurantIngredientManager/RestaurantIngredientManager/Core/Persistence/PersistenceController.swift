//
//  PersistenceController.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  Core Data持久化控制器
//

import CoreData
import Foundation

/// Core Data持久化错误类型
enum PersistenceError: LocalizedError {
    case loadFailed(Error)
    case saveFailed(Error)
    case contextCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .loadFailed(let error):
            return "数据加载失败: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "数据保存失败: \(error.localizedDescription)"
        case .contextCreationFailed:
            return "上下文创建失败"
        }
    }
}

/// Core Data持久化控制器
/// 管理Core Data栈的配置和生命周期
/// 满足需求 16.1（本地数据存储）和 18.5（错误处理）
class PersistenceController: ObservableObject {
    /// 共享实例
    static let shared = PersistenceController()
    
    /// 预览实例（用于SwiftUI预览）
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // 在这里添加预览数据
        // TODO: 在后续任务中添加示例数据
        
        return controller
    }()
    
    /// 持久化容器
    let container: NSPersistentContainer
    
    /// 后台上下文（用于后台操作）
    private(set) lazy var backgroundContext: NSManagedObjectContext = {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    /// 主上下文（用于UI操作）
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    /// 初始化持久化控制器
    /// - Parameter inMemory: 是否使用内存存储（用于测试和预览）
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "RestaurantIngredientManager")
        
        if inMemory {
            // 使用内存存储用于测试和预览
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // 配置持久化存储描述
        if let description = container.persistentStoreDescriptions.first {
            // 启用持久化历史跟踪（用于云同步）
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        // 加载持久化存储
        container.loadPersistentStores { description, error in
            if let error = error {
                // 记录错误并通知用户
                print("❌ Core Data加载失败: \(error.localizedDescription)")
                // 在生产环境中，应该通过通知中心发送错误通知
                NotificationCenter.default.post(
                    name: NSNotification.Name("PersistenceLoadError"),
                    object: nil,
                    userInfo: ["error": error]
                )
            } else {
                print("✅ Core Data加载成功: \(description.url?.lastPathComponent ?? "unknown")")
            }
        }
        
        // 配置主上下文
        configureViewContext()
    }
    
    /// 配置主上下文
    private func configureViewContext() {
        // 自动合并来自父上下文的更改
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // 设置合并策略：属性级别的合并，外部更改优先
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // 配置撤销管理器（可选）
        container.viewContext.undoManager = nil
        
        // 设置为主队列并发类型
        container.viewContext.name = "ViewContext"
    }
    
    /// 创建新的后台上下文
    /// - Returns: 配置好的后台上下文
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        return context
    }
    
    /// 保存主上下文
    /// - Throws: PersistenceError.saveFailed 如果保存失败
    func save() throws {
        let context = container.viewContext
        
        guard context.hasChanges else {
            return
        }
        
        do {
            try context.save()
            print("✅ 主上下文保存成功")
        } catch {
            print("❌ 主上下文保存失败: \(error.localizedDescription)")
            throw PersistenceError.saveFailed(error)
        }
    }
    
    /// 在后台上下文中执行操作
    /// - Parameter block: 要执行的操作闭包
    /// - Throws: 操作中抛出的错误
    func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) throws -> Void) throws {
        let context = newBackgroundContext()
        
        var thrownError: Error?
        
        context.performAndWait {
            do {
                try block(context)
                
                // 如果上下文有更改，保存它
                if context.hasChanges {
                    try context.save()
                    print("✅ 后台上下文保存成功")
                }
            } catch {
                print("❌ 后台操作失败: \(error.localizedDescription)")
                thrownError = error
            }
        }
        
        if let error = thrownError {
            throw PersistenceError.saveFailed(error)
        }
    }
    
    /// 异步在后台上下文中执行操作
    /// - Parameter block: 要执行的操作闭包
    func performBackgroundTaskAsync(_ block: @escaping (NSManagedObjectContext) async throws -> Void) async throws {
        let context = newBackgroundContext()
        
        try await context.perform {
            do {
                try await block(context)
                
                // 如果上下文有更改，保存它
                if context.hasChanges {
                    try context.save()
                    print("✅ 后台上下文保存成功")
                }
            } catch {
                print("❌ 后台操作失败: \(error.localizedDescription)")
                throw PersistenceError.saveFailed(error)
            }
        }
    }
    
    /// 批量删除操作
    /// - Parameters:
    ///   - fetchRequest: 要删除的对象的fetch request
    /// - Throws: PersistenceError.saveFailed 如果删除失败
    func batchDelete<T: NSManagedObject>(_ fetchRequest: NSFetchRequest<T>) throws {
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        do {
            let result = try container.viewContext.execute(deleteRequest) as? NSBatchDeleteResult
            let objectIDArray = result?.result as? [NSManagedObjectID] ?? []
            let changes = [NSDeletedObjectsKey: objectIDArray]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [container.viewContext])
            print("✅ 批量删除成功: \(objectIDArray.count) 个对象")
        } catch {
            print("❌ 批量删除失败: \(error.localizedDescription)")
            throw PersistenceError.saveFailed(error)
        }
    }
    
    /// 重置所有数据（仅用于测试）
    func resetAllData() throws {
        let entities = container.managedObjectModel.entities
        
        for entity in entities {
            guard let entityName = entity.name else { continue }
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try container.viewContext.execute(deleteRequest)
                print("✅ 已清空实体: \(entityName)")
            } catch {
                print("❌ 清空实体失败 \(entityName): \(error.localizedDescription)")
                throw PersistenceError.saveFailed(error)
            }
        }
        
        try save()
    }
}
