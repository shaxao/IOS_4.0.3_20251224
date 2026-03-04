//
//  SupplierRepositoryTests.swift
//  RestaurantIngredientManagerTests
//
//  Created on 2024
//  Unit tests for SupplierRepository
//

import XCTest
import CoreData
@testable import RestaurantIngredientManager

class SupplierRepositoryTests: XCTestCase {
    var repository: SupplierRepository!
    var ingredientRepository: IngredientRepository!
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        // 使用内存存储进行测试
        persistenceController = PersistenceController(inMemory: true)
        repository = SupplierRepository(persistenceController: persistenceController)
        ingredientRepository = IngredientRepository(persistenceController: persistenceController)
    }
    
    override func tearDown() {
        repository = nil
        ingredientRepository = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    func createTestSupplier(name: String = "测试供应商") -> Supplier {
        return Supplier(
            id: UUID(),
            name: name,
            contactPerson: "张三",
            phone: "13800138000",
            email: "test@example.com",
            address: "测试地址",
            notes: "测试备注"
        )
    }
    
    func createTestIngredient(name: String = "测试食材", supplier: Supplier? = nil) -> Ingredient {
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
            expirationDate: Date().addingTimeInterval(86400 * 7),
            storageLocation: storageLocation,
            supplier: supplier,
            barcode: nil,
            qrCode: nil,
            minimumStockThreshold: 5.0,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Create Tests
    
    func testCreateSupplier() async throws {
        // Given
        let supplier = createTestSupplier(name: "新鲜蔬菜供应商")
        
        // When
        try await repository.create(supplier)
        
        // Then
        let fetched = try await repository.fetch(by: supplier.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "新鲜蔬菜供应商")
        XCTAssertEqual(fetched?.contactPerson, "张三")
        XCTAssertEqual(fetched?.phone, "13800138000")
        XCTAssertEqual(fetched?.email, "test@example.com")
    }
    
    func testCreateSupplierWithInvalidData() async throws {
        // Given - 创建一个名称为空的无效供应商
        let supplier = Supplier(
            id: UUID(),
            name: "", // 空名称
            contactPerson: nil,
            phone: nil,
            email: nil,
            address: nil,
            notes: nil
        )
        
        // When & Then
        do {
            try await repository.create(supplier)
            XCTFail("应该抛出验证错误")
        } catch {
            // 预期会抛出错误
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    // MARK: - Fetch Tests
    
    func testFetchAllSuppliers() async throws {
        // Given
        let supplier1 = createTestSupplier(name: "供应商A")
        let supplier2 = createTestSupplier(name: "供应商B")
        try await repository.create(supplier1)
        try await repository.create(supplier2)
        
        // When
        let suppliers = try await repository.fetchAll()
        
        // Then
        XCTAssertEqual(suppliers.count, 2)
        XCTAssertTrue(suppliers.contains { $0.name == "供应商A" })
        XCTAssertTrue(suppliers.contains { $0.name == "供应商B" })
    }
    
    func testFetchSupplierById() async throws {
        // Given
        let supplier = createTestSupplier(name: "特定供应商")
        try await repository.create(supplier)
        
        // When
        let fetched = try await repository.fetch(by: supplier.id)
        
        // Then
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, supplier.id)
        XCTAssertEqual(fetched?.name, "特定供应商")
    }
    
    func testFetchSupplierByIdNotFound() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When
        let fetched = try await repository.fetch(by: nonExistentId)
        
        // Then
        XCTAssertNil(fetched)
    }
    
    // MARK: - Update Tests
    
    func testUpdateSupplier() async throws {
        // Given
        let supplier = createTestSupplier(name: "原始供应商")
        try await repository.create(supplier)
        
        // When
        var updatedSupplier = supplier
        updatedSupplier = Supplier(
            id: supplier.id,
            name: "更新后的供应商",
            contactPerson: "李四",
            phone: "13900139000",
            email: "updated@example.com",
            address: "新地址",
            notes: "更新备注"
        )
        try await repository.update(updatedSupplier)
        
        // Then
        let fetched = try await repository.fetch(by: supplier.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "更新后的供应商")
        XCTAssertEqual(fetched?.contactPerson, "李四")
        XCTAssertEqual(fetched?.phone, "13900139000")
    }
    
    func testUpdateNonExistentSupplier() async throws {
        // Given
        let supplier = createTestSupplier(name: "不存在的供应商")
        
        // When & Then
        do {
            try await repository.update(supplier)
            XCTFail("应该抛出未找到错误")
        } catch let error as RepositoryError {
            if case .notFound = error {
                // 预期的错误
            } else {
                XCTFail("错误类型不正确")
            }
        }
    }
    
    // MARK: - Delete Tests
    
    func testDeleteSupplierWithoutIngredients() async throws {
        // Given
        let supplier = createTestSupplier(name: "可删除供应商")
        try await repository.create(supplier)
        
        // When
        try await repository.delete(supplier)
        
        // Then
        let fetched = try await repository.fetch(by: supplier.id)
        XCTAssertNil(fetched)
    }
    
    func testDeleteSupplierWithIngredients() async throws {
        // Given
        let supplier = createTestSupplier(name: "有食材的供应商")
        try await repository.create(supplier)
        
        let ingredient = createTestIngredient(name: "关联食材", supplier: supplier)
        try await ingredientRepository.create(ingredient)
        
        // When & Then
        do {
            try await repository.delete(supplier)
            XCTFail("应该抛出删除约束错误")
        } catch {
            // 预期会抛出错误
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    func testCanDeleteSupplierWithoutIngredients() async throws {
        // Given
        let supplier = createTestSupplier(name: "无食材供应商")
        try await repository.create(supplier)
        
        // When
        let canDelete = try await repository.canDelete(supplier)
        
        // Then
        XCTAssertTrue(canDelete)
    }
    
    func testCanDeleteSupplierWithIngredients() async throws {
        // Given
        let supplier = createTestSupplier(name: "有食材供应商")
        try await repository.create(supplier)
        
        let ingredient = createTestIngredient(name: "关联食材", supplier: supplier)
        try await ingredientRepository.create(ingredient)
        
        // When
        let canDelete = try await repository.canDelete(supplier)
        
        // Then
        XCTAssertFalse(canDelete)
    }
    
    // MARK: - Association Tests
    
    func testFetchIngredientsForSupplier() async throws {
        // Given
        let supplier = createTestSupplier(name: "蔬菜供应商")
        try await repository.create(supplier)
        
        let ingredient1 = createTestIngredient(name: "胡萝卜", supplier: supplier)
        let ingredient2 = createTestIngredient(name: "白菜", supplier: supplier)
        try await ingredientRepository.create(ingredient1)
        try await ingredientRepository.create(ingredient2)
        
        // When
        let ingredients = try await repository.fetchIngredients(for: supplier)
        
        // Then
        XCTAssertEqual(ingredients.count, 2)
        XCTAssertTrue(ingredients.contains { $0.name == "胡萝卜" })
        XCTAssertTrue(ingredients.contains { $0.name == "白菜" })
    }
    
    func testFetchIngredientsForSupplierWithNoIngredients() async throws {
        // Given
        let supplier = createTestSupplier(name: "无食材供应商")
        try await repository.create(supplier)
        
        // When
        let ingredients = try await repository.fetchIngredients(for: supplier)
        
        // Then
        XCTAssertEqual(ingredients.count, 0)
    }
}
