//
//  PersistenceControllerTests.swift
//  RestaurantIngredientManagerTests
//
//  Created on 2024
//  Tests for Core Data stack configuration
//

import XCTest
import CoreData
@testable import RestaurantIngredientManager

/// 测试 PersistenceController 的 Core Data 栈配置
/// 验证需求 16.1（本地数据存储）和 18.5（错误处理）
class PersistenceControllerTests: XCTestCase {
    
    var sut: PersistenceController!
    
    override func setUp() {
        super.setUp()
        // 使用内存存储进行测试
        sut = PersistenceController(inMemory: true)
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - 上下文创建和配置测试
    
    /// 测试持久化容器创建
    func testPersistentContainerCreation() {
        // Given & When
        let container = sut.container
        
        // Then
        XCTAssertNotNil(container, "持久化容器应该被创建")
        XCTAssertEqual(container.name, "RestaurantIngredientManager", "容器名称应该正确")
    }
    
    /// 测试主上下文配置
    func testViewContextConfiguration() {
        // Given & When
        let viewContext = sut.viewContext
        
        // Then
        XCTAssertNotNil(viewContext, "主上下文应该存在")
        XCTAssertTrue(viewContext.automaticallyMergesChangesFromParent, "应该自动合并父上下文的更改")
        XCTAssertTrue(viewContext.mergePolicy is NSMergeByPropertyObjectTrumpMergePolicy, "应该使用属性级别合并策略")
        XCTAssertEqual(viewContext.name, "ViewContext", "上下文名称应该正确")
    }
    
    /// 测试后台上下文创建
    func testBackgroundContextCreation() {
        // Given & When
        let backgroundContext = sut.backgroundContext
        
        // Then
        XCTAssertNotNil(backgroundContext, "后台上下文应该被创建")
        XCTAssertTrue(backgroundContext.automaticallyMergesChangesFromParent, "应该自动合并父上下文的更改")
        XCTAssertTrue(backgroundContext.mergePolicy is NSMergeByPropertyObjectTrumpMergePolicy, "应该使用属性级别合并策略")
    }
    
    /// 测试创建新的后台上下文
    func testNewBackgroundContextCreation() {
        // Given & When
        let context1 = sut.newBackgroundContext()
        let context2 = sut.newBackgroundContext()
        
        // Then
        XCTAssertNotNil(context1, "应该创建新的后台上下文")
        XCTAssertNotNil(context2, "应该创建另一个新的后台上下文")
        XCTAssertNotEqual(context1, context2, "每次调用应该创建不同的上下文")
    }
    
    // MARK: - 保存操作测试
    
    /// 测试保存空上下文（无更改）
    func testSaveEmptyContext() {
        // Given
        let context = sut.viewContext
        XCTAssertFalse(context.hasChanges, "初始上下文应该没有更改")
        
        // When & Then
        XCTAssertNoThrow(try sut.save(), "保存空上下文不应该抛出错误")
    }
    
    /// 测试保存有更改的上下文
    func testSaveContextWithChanges() {
        // Given
        let context = sut.viewContext
        let location = StorageLocationEntity(context: context)
        location.id = UUID()
        location.name = "测试冰箱"
        location.type = "refrigerator"
        location.isCustom = false
        
        XCTAssertTrue(context.hasChanges, "上下文应该有更改")
        
        // When & Then
        XCTAssertNoThrow(try sut.save(), "保存应该成功")
        XCTAssertFalse(context.hasChanges, "保存后上下文应该没有更改")
    }
    
    /// 测试保存后数据持久化
    func testDataPersistsAfterSave() throws {
        // Given
        let context = sut.viewContext
        let testID = UUID()
        let location = StorageLocationEntity(context: context)
        location.id = testID
        location.name = "测试存储位置"
        location.type = "freezer"
        location.isCustom = true
        
        // When
        try sut.save()
        
        // Then - 从数据库重新获取
        let fetchRequest: NSFetchRequest<StorageLocationEntity> = StorageLocationEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", testID as CVarArg)
        
        let results = try context.fetch(fetchRequest)
        XCTAssertEqual(results.count, 1, "应该找到一个保存的实体")
        
        let savedLocation = results.first!
        XCTAssertEqual(savedLocation.id, testID, "ID应该匹配")
        XCTAssertEqual(savedLocation.name, "测试存储位置", "名称应该匹配")
        XCTAssertEqual(savedLocation.type, "freezer", "类型应该匹配")
        XCTAssertTrue(savedLocation.isCustom, "isCustom应该为true")
    }
    
    // MARK: - 后台操作测试
    
    /// 测试后台任务执行
    func testPerformBackgroundTask() throws {
        // Given
        let testID = UUID()
        let expectation = self.expectation(description: "后台任务完成")
        
        // When
        try sut.performBackgroundTask { context in
            let supplier = SupplierEntity(context: context)
            supplier.id = testID
            supplier.name = "测试供应商"
            supplier.phone = "1234567890"
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        // 验证数据已保存到主上下文
        let fetchRequest: NSFetchRequest<SupplierEntity> = SupplierEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", testID as CVarArg)
        
        let results = try sut.viewContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 1, "应该找到后台保存的实体")
        XCTAssertEqual(results.first?.name, "测试供应商", "名称应该匹配")
    }
    
    /// 测试异步后台任务执行
    func testPerformBackgroundTaskAsync() async throws {
        // Given
        let testID = UUID()
        
        // When
        try await sut.performBackgroundTaskAsync { context in
            let supplier = SupplierEntity(context: context)
            supplier.id = testID
            supplier.name = "异步测试供应商"
            supplier.email = "test@example.com"
        }
        
        // Then
        let fetchRequest: NSFetchRequest<SupplierEntity> = SupplierEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", testID as CVarArg)
        
        let results = try sut.viewContext.fetch(fetchRequest)
        XCTAssertEqual(results.count, 1, "应该找到异步保存的实体")
        XCTAssertEqual(results.first?.name, "异步测试供应商", "名称应该匹配")
    }
    
    // MARK: - 批量删除测试
    
    /// 测试批量删除操作
    func testBatchDelete() throws {
        // Given - 创建多个测试实体
        let context = sut.viewContext
        for i in 1...5 {
            let location = StorageLocationEntity(context: context)
            location.id = UUID()
            location.name = "测试位置 \(i)"
            location.type = "dryStorage"
            location.isCustom = false
        }
        try sut.save()
        
        // 验证创建成功
        let fetchRequest: NSFetchRequest<StorageLocationEntity> = StorageLocationEntity.fetchRequest()
        var count = try context.count(for: fetchRequest)
        XCTAssertEqual(count, 5, "应该有5个实体")
        
        // When - 批量删除
        try sut.batchDelete(fetchRequest)
        
        // Then
        count = try context.count(for: fetchRequest)
        XCTAssertEqual(count, 0, "所有实体应该被删除")
    }
    
    // MARK: - 错误处理测试
    
    /// 测试保存失败时抛出错误
    func testSaveThrowsErrorOnFailure() {
        // Given - 创建一个无效的实体（缺少必需字段）
        let context = sut.viewContext
        let ingredient = IngredientEntity(context: context)
        ingredient.id = UUID()
        // 故意不设置必需字段以触发验证错误
        
        // When & Then
        XCTAssertThrowsError(try sut.save()) { error in
            XCTAssertTrue(error is PersistenceError, "应该抛出 PersistenceError")
        }
    }
    
    // MARK: - 重置数据测试
    
    /// 测试重置所有数据
    func testResetAllData() throws {
        // Given - 创建各种实体
        let context = sut.viewContext
        
        let location = StorageLocationEntity(context: context)
        location.id = UUID()
        location.name = "测试位置"
        location.type = "refrigerator"
        location.isCustom = false
        
        let supplier = SupplierEntity(context: context)
        supplier.id = UUID()
        supplier.name = "测试供应商"
        
        try sut.save()
        
        // 验证数据存在
        let locationFetch: NSFetchRequest<StorageLocationEntity> = StorageLocationEntity.fetchRequest()
        let supplierFetch: NSFetchRequest<SupplierEntity> = SupplierEntity.fetchRequest()
        
        XCTAssertGreaterThan(try context.count(for: locationFetch), 0, "应该有存储位置")
        XCTAssertGreaterThan(try context.count(for: supplierFetch), 0, "应该有供应商")
        
        // When
        try sut.resetAllData()
        
        // Then
        XCTAssertEqual(try context.count(for: locationFetch), 0, "所有存储位置应该被删除")
        XCTAssertEqual(try context.count(for: supplierFetch), 0, "所有供应商应该被删除")
    }
    
    // MARK: - 预览实例测试
    
    /// 测试预览实例创建
    func testPreviewInstanceCreation() {
        // Given & When
        let preview = PersistenceController.preview
        
        // Then
        XCTAssertNotNil(preview, "预览实例应该被创建")
        XCTAssertNotNil(preview.container, "预览实例应该有容器")
        XCTAssertNotNil(preview.viewContext, "预览实例应该有主上下文")
    }
    
    // MARK: - 并发测试
    
    /// 测试多个后台上下文并发操作
    func testConcurrentBackgroundOperations() throws {
        // Given
        let operationCount = 10
        let expectation = self.expectation(description: "所有后台操作完成")
        expectation.expectedFulfillmentCount = operationCount
        
        // When - 并发执行多个后台操作
        for i in 1...operationCount {
            DispatchQueue.global().async {
                do {
                    try self.sut.performBackgroundTask { context in
                        let supplier = SupplierEntity(context: context)
                        supplier.id = UUID()
                        supplier.name = "并发供应商 \(i)"
                        expectation.fulfill()
                    }
                } catch {
                    XCTFail("后台操作失败: \(error)")
                }
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        
        // 验证所有数据都已保存
        let fetchRequest: NSFetchRequest<SupplierEntity> = SupplierEntity.fetchRequest()
        let count = try sut.viewContext.count(for: fetchRequest)
        XCTAssertEqual(count, operationCount, "应该保存所有并发创建的实体")
    }
}
