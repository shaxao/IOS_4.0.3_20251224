//
//  IngredientRepositoryTests.swift
//  RestaurantIngredientManagerTests
//
//  Created on 2024
//  Unit tests for IngredientRepository
//

import XCTest
import CoreData
@testable import RestaurantIngredientManager

class IngredientRepositoryTests: XCTestCase {
    var repository: IngredientRepository!
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        // 使用内存存储进行测试
        persistenceController = PersistenceController(inMemory: true)
        repository = IngredientRepository(persistenceController: persistenceController)
    }
    
    override func tearDown() {
        repository = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    func createTestIngredient(name: String = "测试食材") -> Ingredient {
        let storageLocation = StorageLocation(
            id: UUID(),
            name: "冰箱",
            type: .refrigerator,
            temperature: 4.0,
            isCustom: false
        )
        
        return Ingredient(
            id: UUID(),
            name: name,
            category: .vegetables,
            quantity: 10.0,
            unit: "kg",
            expirationDate: Date().addingTimeInterval(86400 * 7), // 7天后
            storageLocation: storageLocation,
            supplier: nil,
            barcode: "1234567890",
            qrCode: nil,
            minimumStockThreshold: 5.0,
            notes: "测试备注",
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Create Tests
    
    func testCreateIngredient() async throws {
        // Given
        let ingredient = createTestIngredient(name: "胡萝卜")
        
        // When
        try await repository.create(ingredient)
        
        // Then
        let fetched = try await repository.fetch(by: ingredient.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "胡萝卜")
        XCTAssertEqual(fetched?.category, .vegetables)
        XCTAssertEqual(fetched?.quantity, 10.0)
        XCTAssertEqual(fetched?.unit, "kg")
    }
    
    func testCreateIngredientWithInvalidData() async throws {
        // Given - 创建一个名称为空的无效食材
        var ingredient = createTestIngredient()
        ingredient = Ingredient(
            id: ingredient.id,
            name: "", // 空名称
            category: ingredient.category,
            quantity: ingredient.quantity,
            unit: ingredient.unit,
            expirationDate: ingredient.expirationDate,
            storageLocation: ingredient.storageLocation,
            supplier: ingredient.supplier,
            barcode: ingredient.barcode,
            qrCode: ingredient.qrCode,
            minimumStockThreshold: ingredient.minimumStockThreshold,
            notes: ingredient.notes,
            createdAt: ingredient.createdAt,
            updatedAt: ingredient.updatedAt
        )
        
        // When & Then
        do {
            try await repository.create(ingredient)
            XCTFail("应该抛出验证错误")
        } catch {
            // 预期会抛出错误
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    // MARK: - Fetch Tests
    
    func testFetchAll() async throws {
        // Given
        let ingredient1 = createTestIngredient(name: "胡萝卜")
        let ingredient2 = createTestIngredient(name: "土豆")
        try await repository.create(ingredient1)
        try await repository.create(ingredient2)
        
        // When
        let ingredients = try await repository.fetchAll()
        
        // Then
        XCTAssertEqual(ingredients.count, 2)
        XCTAssertTrue(ingredients.contains { $0.name == "胡萝卜" })
        XCTAssertTrue(ingredients.contains { $0.name == "土豆" })
    }
    
    func testFetchById() async throws {
        // Given
        let ingredient = createTestIngredient(name: "西红柿")
        try await repository.create(ingredient)
        
        // When
        let fetched = try await repository.fetch(by: ingredient.id)
        
        // Then
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, ingredient.id)
        XCTAssertEqual(fetched?.name, "西红柿")
    }
    
    func testFetchByIdNotFound() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When
        let fetched = try await repository.fetch(by: nonExistentId)
        
        // Then
        XCTAssertNil(fetched)
    }
    
    // MARK: - Search Tests
    
    func testSearchByName() async throws {
        // Given
        let ingredient1 = createTestIngredient(name: "胡萝卜")
        let ingredient2 = createTestIngredient(name: "土豆")
        let ingredient3 = createTestIngredient(name: "西红柿")
        try await repository.create(ingredient1)
        try await repository.create(ingredient2)
        try await repository.create(ingredient3)
        
        // When
        let results = try await repository.search(query: "萝卜")
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "胡萝卜")
    }
    
    func testSearchByCategory() async throws {
        // Given
        var ingredient1 = createTestIngredient(name: "牛肉")
        ingredient1 = Ingredient(
            id: ingredient1.id,
            name: ingredient1.name,
            category: .meat, // 肉类
            quantity: ingredient1.quantity,
            unit: ingredient1.unit,
            expirationDate: ingredient1.expirationDate,
            storageLocation: ingredient1.storageLocation,
            supplier: ingredient1.supplier,
            barcode: ingredient1.barcode,
            qrCode: ingredient1.qrCode,
            minimumStockThreshold: ingredient1.minimumStockThreshold,
            notes: ingredient1.notes,
            createdAt: ingredient1.createdAt,
            updatedAt: ingredient1.updatedAt
        )
        try await repository.create(ingredient1)
        
        // When
        let results = try await repository.search(query: "肉类")
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "牛肉")
    }
    
    func testSearchEmptyQuery() async throws {
        // Given
        let ingredient = createTestIngredient(name: "测试")
        try await repository.create(ingredient)
        
        // When
        let results = try await repository.search(query: "")
        
        // Then - 空查询应该返回所有食材
        XCTAssertEqual(results.count, 1)
    }
    
    // MARK: - Filter Tests
    
    func testFilterByCategory() async throws {
        // Given
        var ingredient1 = createTestIngredient(name: "胡萝卜")
        ingredient1 = Ingredient(
            id: ingredient1.id,
            name: ingredient1.name,
            category: .vegetables,
            quantity: ingredient1.quantity,
            unit: ingredient1.unit,
            expirationDate: ingredient1.expirationDate,
            storageLocation: ingredient1.storageLocation,
            supplier: ingredient1.supplier,
            barcode: ingredient1.barcode,
            qrCode: ingredient1.qrCode,
            minimumStockThreshold: ingredient1.minimumStockThreshold,
            notes: ingredient1.notes,
            createdAt: ingredient1.createdAt,
            updatedAt: ingredient1.updatedAt
        )
        
        var ingredient2 = createTestIngredient(name: "牛肉")
        ingredient2 = Ingredient(
            id: ingredient2.id,
            name: ingredient2.name,
            category: .meat,
            quantity: ingredient2.quantity,
            unit: ingredient2.unit,
            expirationDate: ingredient2.expirationDate,
            storageLocation: ingredient2.storageLocation,
            supplier: ingredient2.supplier,
            barcode: ingredient2.barcode,
            qrCode: ingredient2.qrCode,
            minimumStockThreshold: ingredient2.minimumStockThreshold,
            notes: ingredient2.notes,
            createdAt: ingredient2.createdAt,
            updatedAt: ingredient2.updatedAt
        )
        
        try await repository.create(ingredient1)
        try await repository.create(ingredient2)
        
        // When
        let criteria = FilterCriteria(categories: [.vegetables])
        let results = try await repository.filter(by: criteria)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "胡萝卜")
    }
    
    func testFilterByExpirationDateRange() async throws {
        // Given
        let now = Date()
        let tomorrow = now.addingTimeInterval(86400)
        let nextWeek = now.addingTimeInterval(86400 * 7)
        
        var ingredient1 = createTestIngredient(name: "明天过期")
        ingredient1 = Ingredient(
            id: ingredient1.id,
            name: ingredient1.name,
            category: ingredient1.category,
            quantity: ingredient1.quantity,
            unit: ingredient1.unit,
            expirationDate: tomorrow,
            storageLocation: ingredient1.storageLocation,
            supplier: ingredient1.supplier,
            barcode: ingredient1.barcode,
            qrCode: ingredient1.qrCode,
            minimumStockThreshold: ingredient1.minimumStockThreshold,
            notes: ingredient1.notes,
            createdAt: ingredient1.createdAt,
            updatedAt: ingredient1.updatedAt
        )
        
        var ingredient2 = createTestIngredient(name: "下周过期")
        ingredient2 = Ingredient(
            id: ingredient2.id,
            name: ingredient2.name,
            category: ingredient2.category,
            quantity: ingredient2.quantity,
            unit: ingredient2.unit,
            expirationDate: nextWeek,
            storageLocation: ingredient2.storageLocation,
            supplier: ingredient2.supplier,
            barcode: ingredient2.barcode,
            qrCode: ingredient2.qrCode,
            minimumStockThreshold: ingredient2.minimumStockThreshold,
            notes: ingredient2.notes,
            createdAt: ingredient2.createdAt,
            updatedAt: ingredient2.updatedAt
        )
        
        try await repository.create(ingredient1)
        try await repository.create(ingredient2)
        
        // When - 筛选未来3天内过期的
        let threeDaysLater = now.addingTimeInterval(86400 * 3)
        let criteria = FilterCriteria(expirationDateRange: now...threeDaysLater)
        let results = try await repository.filter(by: criteria)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "明天过期")
    }
    
    // MARK: - Update Tests
    
    func testUpdateIngredient() async throws {
        // Given
        let ingredient = createTestIngredient(name: "原始名称")
        try await repository.create(ingredient)
        
        // When - 更新名称和数量
        var updatedIngredient = ingredient
        updatedIngredient = Ingredient(
            id: updatedIngredient.id,
            name: "更新后的名称",
            category: updatedIngredient.category,
            quantity: 20.0, // 更新数量
            unit: updatedIngredient.unit,
            expirationDate: updatedIngredient.expirationDate,
            storageLocation: updatedIngredient.storageLocation,
            supplier: updatedIngredient.supplier,
            barcode: updatedIngredient.barcode,
            qrCode: updatedIngredient.qrCode,
            minimumStockThreshold: updatedIngredient.minimumStockThreshold,
            notes: updatedIngredient.notes,
            createdAt: updatedIngredient.createdAt,
            updatedAt: Date()
        )
        try await repository.update(updatedIngredient)
        
        // Then
        let fetched = try await repository.fetch(by: ingredient.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "更新后的名称")
        XCTAssertEqual(fetched?.quantity, 20.0)
    }
    
    func testUpdateNonExistentIngredient() async throws {
        // Given
        let ingredient = createTestIngredient()
        
        // When & Then
        do {
            try await repository.update(ingredient)
            XCTFail("应该抛出未找到错误")
        } catch {
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    // MARK: - Delete Tests
    
    func testDeleteIngredient() async throws {
        // Given
        let ingredient = createTestIngredient(name: "要删除的食材")
        try await repository.create(ingredient)
        
        // When
        try await repository.delete(ingredient)
        
        // Then
        let fetched = try await repository.fetch(by: ingredient.id)
        XCTAssertNil(fetched)
    }
    
    func testDeleteNonExistentIngredient() async throws {
        // Given
        let ingredient = createTestIngredient()
        
        // When & Then
        do {
            try await repository.delete(ingredient)
            XCTFail("应该抛出未找到错误")
        } catch {
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    // MARK: - Expiring Tests
    
    func testFetchExpiring() async throws {
        // Given
        let now = Date()
        let twoDaysLater = now.addingTimeInterval(86400 * 2)
        let tenDaysLater = now.addingTimeInterval(86400 * 10)
        
        var ingredient1 = createTestIngredient(name: "即将过期")
        ingredient1 = Ingredient(
            id: ingredient1.id,
            name: ingredient1.name,
            category: ingredient1.category,
            quantity: ingredient1.quantity,
            unit: ingredient1.unit,
            expirationDate: twoDaysLater,
            storageLocation: ingredient1.storageLocation,
            supplier: ingredient1.supplier,
            barcode: ingredient1.barcode,
            qrCode: ingredient1.qrCode,
            minimumStockThreshold: ingredient1.minimumStockThreshold,
            notes: ingredient1.notes,
            createdAt: ingredient1.createdAt,
            updatedAt: ingredient1.updatedAt
        )
        
        var ingredient2 = createTestIngredient(name: "还很新鲜")
        ingredient2 = Ingredient(
            id: ingredient2.id,
            name: ingredient2.name,
            category: ingredient2.category,
            quantity: ingredient2.quantity,
            unit: ingredient2.unit,
            expirationDate: tenDaysLater,
            storageLocation: ingredient2.storageLocation,
            supplier: ingredient2.supplier,
            barcode: ingredient2.barcode,
            qrCode: ingredient2.qrCode,
            minimumStockThreshold: ingredient2.minimumStockThreshold,
            notes: ingredient2.notes,
            createdAt: ingredient2.createdAt,
            updatedAt: ingredient2.updatedAt
        )
        
        try await repository.create(ingredient1)
        try await repository.create(ingredient2)
        
        // When - 查找3天内过期的
        let results = try await repository.fetchExpiring(within: 3)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "即将过期")
    }
    
    // MARK: - Low Stock Tests
    
    func testFetchLowStock() async throws {
        // Given
        var ingredient1 = createTestIngredient(name: "库存不足")
        ingredient1 = Ingredient(
            id: ingredient1.id,
            name: ingredient1.name,
            category: ingredient1.category,
            quantity: 3.0, // 低于阈值5.0
            unit: ingredient1.unit,
            expirationDate: ingredient1.expirationDate,
            storageLocation: ingredient1.storageLocation,
            supplier: ingredient1.supplier,
            barcode: ingredient1.barcode,
            qrCode: ingredient1.qrCode,
            minimumStockThreshold: 5.0,
            notes: ingredient1.notes,
            createdAt: ingredient1.createdAt,
            updatedAt: ingredient1.updatedAt
        )
        
        var ingredient2 = createTestIngredient(name: "库存充足")
        ingredient2 = Ingredient(
            id: ingredient2.id,
            name: ingredient2.name,
            category: ingredient2.category,
            quantity: 10.0, // 高于阈值5.0
            unit: ingredient2.unit,
            expirationDate: ingredient2.expirationDate,
            storageLocation: ingredient2.storageLocation,
            supplier: ingredient2.supplier,
            barcode: ingredient2.barcode,
            qrCode: ingredient2.qrCode,
            minimumStockThreshold: 5.0,
            notes: ingredient2.notes,
            createdAt: ingredient2.createdAt,
            updatedAt: ingredient2.updatedAt
        )
        
        try await repository.create(ingredient1)
        try await repository.create(ingredient2)
        
        // When
        let results = try await repository.fetchLowStock()
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "库存不足")
    }
}
