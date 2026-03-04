//
//  StorageLocationRepositoryTests.swift
//  RestaurantIngredientManagerTests
//
//  Created on 2024
//  Unit tests for StorageLocationRepository
//

import XCTest
import CoreData
@testable import RestaurantIngredientManager

class StorageLocationRepositoryTests: XCTestCase {
    var repository: StorageLocationRepository!
    var ingredientRepository: IngredientRepository!
    var persistenceController: PersistenceController!
    
    override func setUp() {
        super.setUp()
        // 使用内存存储进行测试
        persistenceController = PersistenceController(inMemory: true)
        repository = StorageLocationRepository(persistenceController: persistenceController)
        ingredientRepository = IngredientRepository(persistenceController: persistenceController)
    }
    
    override func tearDown() {
        repository = nil
        ingredientRepository = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    func createTestStorageLocation(name: String = "测试位置", type: StorageLocation.LocationType = .refrigerator) -> StorageLocation {
        return StorageLocation(
            id: UUID(),
            name: name,
            type: type,
            temperature: type == .refrigerator ? 4.0 : (type == .freezer ? -18.0 : nil),
            isCustom: type == .custom
        )
    }
    
    func createTestIngredient(name: String = "测试食材", storageLocation: StorageLocation) -> Ingredient {
        return Ingredient(
            id: UUID(),
            name: name,
            category: .vegetables,
            quantity: 10.0,
            unit: "kg",
            expirationDate: Date().addingTimeInterval(86400 * 7),
            storageLocation: storageLocation,
            supplier: nil,
            barcode: nil,
            qrCode: nil,
            minimumStockThreshold: 5.0,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    // MARK: - Create Tests
    
    func testCreateStorageLocation() async throws {
        // Given
        let location = createTestStorageLocation(name: "主冰箱", type: .refrigerator)
        
        // When
        try await repository.create(location)
        
        // Then
        let fetched = try await repository.fetch(by: location.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "主冰箱")
        XCTAssertEqual(fetched?.type, .refrigerator)
        XCTAssertEqual(fetched?.temperature, 4.0)
        XCTAssertFalse(fetched?.isCustom ?? true)
    }
    
    func testCreateCustomStorageLocation() async throws {
        // Given
        let location = StorageLocation(
            id: UUID(),
            name: "特殊储藏室",
            type: .custom,
            temperature: 15.0,
            isCustom: true
        )
        
        // When
        try await repository.create(location)
        
        // Then
        let fetched = try await repository.fetch(by: location.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "特殊储藏室")
        XCTAssertEqual(fetched?.type, .custom)
        XCTAssertTrue(fetched?.isCustom ?? false)
    }
    
    func testCreateStorageLocationWithInvalidData() async throws {
        // Given - 创建一个名称为空的无效存储位置
        let location = StorageLocation(
            id: UUID(),
            name: "", // 空名称
            type: .refrigerator,
            temperature: nil,
            isCustom: false
        )
        
        // When & Then
        do {
            try await repository.create(location)
            XCTFail("应该抛出验证错误")
        } catch {
            // 预期会抛出错误
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    // MARK: - Fetch Tests
    
    func testFetchAllStorageLocations() async throws {
        // Given
        let location1 = createTestStorageLocation(name: "冰箱A", type: .refrigerator)
        let location2 = createTestStorageLocation(name: "冷冻柜B", type: .freezer)
        let location3 = createTestStorageLocation(name: "干货仓库C", type: .dryStorage)
        try await repository.create(location1)
        try await repository.create(location2)
        try await repository.create(location3)
        
        // When
        let locations = try await repository.fetchAll()
        
        // Then
        XCTAssertEqual(locations.count, 3)
        XCTAssertTrue(locations.contains { $0.name == "冰箱A" })
        XCTAssertTrue(locations.contains { $0.name == "冷冻柜B" })
        XCTAssertTrue(locations.contains { $0.name == "干货仓库C" })
    }
    
    func testFetchStorageLocationById() async throws {
        // Given
        let location = createTestStorageLocation(name: "特定位置", type: .refrigerator)
        try await repository.create(location)
        
        // When
        let fetched = try await repository.fetch(by: location.id)
        
        // Then
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, location.id)
        XCTAssertEqual(fetched?.name, "特定位置")
    }
    
    func testFetchStorageLocationByIdNotFound() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When
        let fetched = try await repository.fetch(by: nonExistentId)
        
        // Then
        XCTAssertNil(fetched)
    }
    
    // MARK: - Update Tests
    
    func testUpdateStorageLocation() async throws {
        // Given
        let location = createTestStorageLocation(name: "原始位置", type: .refrigerator)
        try await repository.create(location)
        
        // When
        var updatedLocation = location
        updatedLocation = StorageLocation(
            id: location.id,
            name: "更新后的位置",
            type: .freezer,
            temperature: -18.0,
            isCustom: false
        )
        try await repository.update(updatedLocation)
        
        // Then
        let fetched = try await repository.fetch(by: location.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "更新后的位置")
        XCTAssertEqual(fetched?.type, .freezer)
        XCTAssertEqual(fetched?.temperature, -18.0)
    }
    
    func testUpdateNonExistentStorageLocation() async throws {
        // Given
        let location = createTestStorageLocation(name: "不存在的位置")
        
        // When & Then
        do {
            try await repository.update(location)
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
    
    func testDeleteStorageLocationWithoutIngredients() async throws {
        // Given
        let location = createTestStorageLocation(name: "可删除位置")
        try await repository.create(location)
        
        // When
        try await repository.delete(location)
        
        // Then
        let fetched = try await repository.fetch(by: location.id)
        XCTAssertNil(fetched)
    }
    
    func testDeleteStorageLocationWithIngredients() async throws {
        // Given
        let location = createTestStorageLocation(name: "有食材的位置")
        try await repository.create(location)
        
        let ingredient = createTestIngredient(name: "关联食材", storageLocation: location)
        try await ingredientRepository.create(ingredient)
        
        // When & Then
        do {
            try await repository.delete(location)
            XCTFail("应该抛出删除约束错误")
        } catch {
            // 预期会抛出错误
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    func testCanDeleteStorageLocationWithoutIngredients() async throws {
        // Given
        let location = createTestStorageLocation(name: "无食材位置")
        try await repository.create(location)
        
        // When
        let canDelete = try await repository.canDelete(location)
        
        // Then
        XCTAssertTrue(canDelete)
    }
    
    func testCanDeleteStorageLocationWithIngredients() async throws {
        // Given
        let location = createTestStorageLocation(name: "有食材位置")
        try await repository.create(location)
        
        let ingredient = createTestIngredient(name: "关联食材", storageLocation: location)
        try await ingredientRepository.create(ingredient)
        
        // When
        let canDelete = try await repository.canDelete(location)
        
        // Then
        XCTAssertFalse(canDelete)
    }
    
    // MARK: - Association Tests
    
    func testFetchIngredientsForStorageLocation() async throws {
        // Given
        let location = createTestStorageLocation(name: "主冰箱", type: .refrigerator)
        try await repository.create(location)
        
        let ingredient1 = createTestIngredient(name: "胡萝卜", storageLocation: location)
        let ingredient2 = createTestIngredient(name: "白菜", storageLocation: location)
        let ingredient3 = createTestIngredient(name: "西红柿", storageLocation: location)
        try await ingredientRepository.create(ingredient1)
        try await ingredientRepository.create(ingredient2)
        try await ingredientRepository.create(ingredient3)
        
        // When
        let ingredients = try await repository.fetchIngredients(for: location)
        
        // Then
        XCTAssertEqual(ingredients.count, 3)
        XCTAssertTrue(ingredients.contains { $0.name == "胡萝卜" })
        XCTAssertTrue(ingredients.contains { $0.name == "白菜" })
        XCTAssertTrue(ingredients.contains { $0.name == "西红柿" })
    }
    
    func testFetchIngredientsForStorageLocationWithNoIngredients() async throws {
        // Given
        let location = createTestStorageLocation(name: "空位置")
        try await repository.create(location)
        
        // When
        let ingredients = try await repository.fetchIngredients(for: location)
        
        // Then
        XCTAssertEqual(ingredients.count, 0)
    }
    
    func testFetchIngredientsGroupedByStorageLocation() async throws {
        // Given
        let refrigerator = createTestStorageLocation(name: "冰箱", type: .refrigerator)
        let freezer = createTestStorageLocation(name: "冷冻柜", type: .freezer)
        try await repository.create(refrigerator)
        try await repository.create(freezer)
        
        let ingredient1 = createTestIngredient(name: "蔬菜", storageLocation: refrigerator)
        let ingredient2 = createTestIngredient(name: "水果", storageLocation: refrigerator)
        let ingredient3 = createTestIngredient(name: "冷冻肉", storageLocation: freezer)
        try await ingredientRepository.create(ingredient1)
        try await ingredientRepository.create(ingredient2)
        try await ingredientRepository.create(ingredient3)
        
        // When
        let refrigeratorIngredients = try await repository.fetchIngredients(for: refrigerator)
        let freezerIngredients = try await repository.fetchIngredients(for: freezer)
        
        // Then
        XCTAssertEqual(refrigeratorIngredients.count, 2)
        XCTAssertEqual(freezerIngredients.count, 1)
        XCTAssertTrue(refrigeratorIngredients.contains { $0.name == "蔬菜" })
        XCTAssertTrue(refrigeratorIngredients.contains { $0.name == "水果" })
        XCTAssertTrue(freezerIngredients.contains { $0.name == "冷冻肉" })
    }
}
