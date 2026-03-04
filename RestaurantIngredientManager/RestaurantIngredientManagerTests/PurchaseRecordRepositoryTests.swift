//
//  PurchaseRecordRepositoryTests.swift
//  RestaurantIngredientManagerTests
//
//  Created on 2024
//  Unit tests for PurchaseRecordRepository
//

import XCTest
import CoreData
@testable import RestaurantIngredientManager

class PurchaseRecordRepositoryTests: XCTestCase {
    var persistenceController: PersistenceController!
    var repository: PurchaseRecordRepository!
    var ingredientRepository: IngredientRepository!
    var supplierRepository: SupplierRepository!
    var storageLocationRepository: StorageLocationRepository!
    
    // Test data
    var testIngredient: Ingredient!
    var testSupplier: Supplier!
    var testStorageLocation: StorageLocation!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 使用内存存储进行测试
        persistenceController = PersistenceController(inMemory: true)
        repository = PurchaseRecordRepository(persistenceController: persistenceController)
        ingredientRepository = IngredientRepository(persistenceController: persistenceController)
        supplierRepository = SupplierRepository(persistenceController: persistenceController)
        storageLocationRepository = StorageLocationRepository(persistenceController: persistenceController)
        
        // 创建测试数据
        testStorageLocation = StorageLocation(
            id: UUID(),
            name: "测试冰箱",
            type: .refrigerator,
            temperature: 4.0,
            isCustom: false
        )
        try await storageLocationRepository.create(testStorageLocation)
        
        testSupplier = Supplier(
            id: UUID(),
            name: "测试供应商",
            contactPerson: "张三",
            phone: "13800138000",
            email: "test@example.com",
            address: "测试地址",
            notes: "测试备注"
        )
        try await supplierRepository.create(testSupplier)
        
        testIngredient = Ingredient(
            id: UUID(),
            name: "测试食材",
            category: .vegetables,
            quantity: 10.0,
            unit: "kg",
            expirationDate: Date().addingTimeInterval(86400 * 7),
            storageLocation: testStorageLocation,
            supplier: testSupplier,
            barcode: "1234567890",
            qrCode: nil,
            minimumStockThreshold: 5.0,
            notes: "测试备注",
            createdAt: Date(),
            updatedAt: Date()
        )
        try await ingredientRepository.create(testIngredient)
    }
    
    override func tearDown() async throws {
        repository = nil
        ingredientRepository = nil
        supplierRepository = nil
        storageLocationRepository = nil
        persistenceController = nil
        testIngredient = nil
        testSupplier = nil
        testStorageLocation = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Create Tests
    
    func testCreatePurchaseRecord() async throws {
        // Given
        let record = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "测试采购"
        )
        
        // When
        try await repository.create(record)
        
        // Then
        let fetched = try await repository.fetch(by: record.id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, record.id)
        XCTAssertEqual(fetched?.ingredientId, testIngredient.id)
        XCTAssertEqual(fetched?.supplierId, testSupplier.id)
        XCTAssertEqual(fetched?.quantity, 5.0)
        XCTAssertEqual(fetched?.unitCost, 10.0)
        XCTAssertEqual(fetched?.totalCost, 50.0)
    }
    
    func testCreatePurchaseRecordWithInvalidQuantity() async throws {
        // Given
        let record = PurchaseRecord(
            id: UUID(),
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: -5.0,
            unitCost: 10.0,
            totalCost: -50.0,
            purchaseDate: Date(),
            notes: nil
        )
        
        // When/Then
        do {
            try await repository.create(record)
            XCTFail("应该抛出验证错误")
        } catch {
            // 预期的错误
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    func testCreatePurchaseRecordWithFutureDate() async throws {
        // Given
        let futureDate = Date().addingTimeInterval(86400) // 明天
        let record = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: futureDate,
            notes: nil
        )
        
        // When/Then
        do {
            try await repository.create(record)
            XCTFail("应该抛出验证错误")
        } catch {
            // 预期的错误
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    // MARK: - Fetch Tests
    
    func testFetchAllPurchaseRecords() async throws {
        // Given
        let record1 = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "采购1"
        )
        let record2 = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 3.0,
            unitCost: 15.0,
            purchaseDate: Date(),
            notes: "采购2"
        )
        
        try await repository.create(record1)
        try await repository.create(record2)
        
        // When
        let records = try await repository.fetchAll()
        
        // Then
        XCTAssertEqual(records.count, 2)
    }
    
    func testFetchPurchaseRecordById() async throws {
        // Given
        let record = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "测试采购"
        )
        try await repository.create(record)
        
        // When
        let fetched = try await repository.fetch(by: record.id)
        
        // Then
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, record.id)
    }
    
    func testFetchNonExistentPurchaseRecord() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When
        let fetched = try await repository.fetch(by: nonExistentId)
        
        // Then
        XCTAssertNil(fetched)
    }
    
    // MARK: - Query Tests
    
    func testQueryByIngredient() async throws {
        // Given
        let record = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "测试采购"
        )
        try await repository.create(record)
        
        // When
        let criteria = PurchaseRecordQueryCriteria(ingredientIds: [testIngredient.id])
        let records = try await repository.query(by: criteria)
        
        // Then
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.ingredientId, testIngredient.id)
    }
    
    func testQueryBySupplier() async throws {
        // Given
        let record = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "测试采购"
        )
        try await repository.create(record)
        
        // When
        let criteria = PurchaseRecordQueryCriteria(supplierIds: [testSupplier.id])
        let records = try await repository.query(by: criteria)
        
        // Then
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.supplierId, testSupplier.id)
    }
    
    func testQueryByDateRange() async throws {
        // Given
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let tomorrow = now.addingTimeInterval(86400)
        
        let record = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: now,
            notes: "测试采购"
        )
        try await repository.create(record)
        
        // When
        let criteria = PurchaseRecordQueryCriteria(dateRange: yesterday...tomorrow)
        let records = try await repository.query(by: criteria)
        
        // Then
        XCTAssertEqual(records.count, 1)
    }
    
    func testQueryWithMultipleCriteria() async throws {
        // Given
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let tomorrow = now.addingTimeInterval(86400)
        
        let record = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: now,
            notes: "测试采购"
        )
        try await repository.create(record)
        
        // When
        let criteria = PurchaseRecordQueryCriteria(
            ingredientIds: [testIngredient.id],
            supplierIds: [testSupplier.id],
            dateRange: yesterday...tomorrow
        )
        let records = try await repository.query(by: criteria)
        
        // Then
        XCTAssertEqual(records.count, 1)
    }
    
    func testFetchRecordsForIngredient() async throws {
        // Given
        let record = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "测试采购"
        )
        try await repository.create(record)
        
        // When
        let records = try await repository.fetchRecords(for: testIngredient)
        
        // Then
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.ingredientId, testIngredient.id)
    }
    
    func testFetchRecordsForSupplier() async throws {
        // Given
        let record = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "测试采购"
        )
        try await repository.create(record)
        
        // When
        let records = try await repository.fetchRecords(for: testSupplier)
        
        // Then
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.supplierId, testSupplier.id)
    }
    
    // MARK: - Update Tests
    
    func testUpdatePurchaseRecord() async throws {
        // Given
        let record = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "原始备注"
        )
        try await repository.create(record)
        
        // When
        var updatedRecord = record
        updatedRecord.quantity = 8.0
        updatedRecord.unitCost = 12.0
        updatedRecord.totalCost = 96.0
        updatedRecord.notes = "更新后的备注"
        
        try await repository.update(updatedRecord)
        
        // Then
        let fetched = try await repository.fetch(by: record.id)
        XCTAssertEqual(fetched?.quantity, 8.0)
        XCTAssertEqual(fetched?.unitCost, 12.0)
        XCTAssertEqual(fetched?.totalCost, 96.0)
        XCTAssertEqual(fetched?.notes, "更新后的备注")
    }
    
    func testUpdateNonExistentPurchaseRecord() async throws {
        // Given
        let record = PurchaseRecord(
            id: UUID(),
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            totalCost: 50.0,
            purchaseDate: Date(),
            notes: nil
        )
        
        // When/Then
        do {
            try await repository.update(record)
            XCTFail("应该抛出未找到错误")
        } catch {
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    // MARK: - Delete Tests
    
    func testDeletePurchaseRecord() async throws {
        // Given
        let record = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "测试采购"
        )
        try await repository.create(record)
        
        // When
        try await repository.delete(record)
        
        // Then
        let fetched = try await repository.fetch(by: record.id)
        XCTAssertNil(fetched)
    }
    
    func testDeleteNonExistentPurchaseRecord() async throws {
        // Given
        let record = PurchaseRecord(
            id: UUID(),
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            totalCost: 50.0,
            purchaseDate: Date(),
            notes: nil
        )
        
        // When/Then
        do {
            try await repository.delete(record)
            XCTFail("应该抛出未找到错误")
        } catch {
            XCTAssertTrue(error is RepositoryError)
        }
    }
    
    // MARK: - Cost Aggregation Tests
    
    func testCalculateTotalCost() async throws {
        // Given
        let record1 = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "采购1"
        )
        let record2 = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 3.0,
            unitCost: 15.0,
            purchaseDate: Date(),
            notes: "采购2"
        )
        
        try await repository.create(record1)
        try await repository.create(record2)
        
        // When
        let criteria = PurchaseRecordQueryCriteria()
        let aggregation = try await repository.calculateTotalCost(by: criteria)
        
        // Then
        XCTAssertEqual(aggregation.totalCost, 95.0) // 50 + 45
        XCTAssertEqual(aggregation.recordCount, 2)
        XCTAssertEqual(aggregation.averageCost, 47.5)
    }
    
    func testCalculateCostByCategory() async throws {
        // Given
        // 创建另一个类别的食材
        let meatIngredient = Ingredient(
            id: UUID(),
            name: "测试肉类",
            category: .meat,
            quantity: 10.0,
            unit: "kg",
            expirationDate: Date().addingTimeInterval(86400 * 7),
            storageLocation: testStorageLocation,
            supplier: testSupplier,
            barcode: nil,
            qrCode: nil,
            minimumStockThreshold: 5.0,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        try await ingredientRepository.create(meatIngredient)
        
        let record1 = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "蔬菜采购"
        )
        let record2 = PurchaseRecord(
            ingredientId: meatIngredient.id,
            supplierId: testSupplier.id,
            quantity: 3.0,
            unitCost: 20.0,
            purchaseDate: Date(),
            notes: "肉类采购"
        )
        
        try await repository.create(record1)
        try await repository.create(record2)
        
        // When
        let summaries = try await repository.calculateCostByCategory(dateRange: nil)
        
        // Then
        XCTAssertEqual(summaries.count, 2)
        
        // 按总成本降序排列，肉类应该在前
        let meatSummary = summaries.first { $0.category == .meat }
        let vegSummary = summaries.first { $0.category == .vegetables }
        
        XCTAssertNotNil(meatSummary)
        XCTAssertNotNil(vegSummary)
        XCTAssertEqual(meatSummary?.totalCost, 60.0)
        XCTAssertEqual(vegSummary?.totalCost, 50.0)
    }
    
    func testCalculateCostBySupplier() async throws {
        // Given
        // 创建另一个供应商
        let supplier2 = Supplier(
            id: UUID(),
            name: "供应商2",
            contactPerson: "李四",
            phone: "13900139000",
            email: "supplier2@example.com",
            address: "地址2",
            notes: nil
        )
        try await supplierRepository.create(supplier2)
        
        let record1 = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "供应商1采购"
        )
        let record2 = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: supplier2.id,
            quantity: 3.0,
            unitCost: 20.0,
            purchaseDate: Date(),
            notes: "供应商2采购"
        )
        
        try await repository.create(record1)
        try await repository.create(record2)
        
        // When
        let summaries = try await repository.calculateCostBySupplier(dateRange: nil)
        
        // Then
        XCTAssertEqual(summaries.count, 2)
        
        // 按总成本降序排列，供应商2应该在前
        let supplier1Summary = summaries.first { $0.supplierId == testSupplier.id }
        let supplier2Summary = summaries.first { $0.supplierId == supplier2.id }
        
        XCTAssertNotNil(supplier1Summary)
        XCTAssertNotNil(supplier2Summary)
        XCTAssertEqual(supplier1Summary?.totalCost, 50.0)
        XCTAssertEqual(supplier2Summary?.totalCost, 60.0)
    }
    
    // MARK: - Export Tests
    
    func testExportData() async throws {
        // Given
        let record = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "测试采购"
        )
        try await repository.create(record)
        
        // When
        let criteria = PurchaseRecordQueryCriteria()
        let data = try await repository.exportData(by: criteria)
        
        // Then
        XCTAssertFalse(data.isEmpty)
        
        let csvString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(csvString)
        XCTAssertTrue(csvString!.contains("ID,食材ID,供应商ID,数量,单价,总成本,采购日期,备注"))
        XCTAssertTrue(csvString!.contains(record.id.uuidString))
    }
    
    func testExportDataWithCriteria() async throws {
        // Given
        let record1 = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 5.0,
            unitCost: 10.0,
            purchaseDate: Date(),
            notes: "采购1"
        )
        let record2 = PurchaseRecord(
            ingredientId: testIngredient.id,
            supplierId: testSupplier.id,
            quantity: 3.0,
            unitCost: 15.0,
            purchaseDate: Date().addingTimeInterval(-86400 * 10), // 10天前
            notes: "采购2"
        )
        
        try await repository.create(record1)
        try await repository.create(record2)
        
        // When - 只导出最近7天的记录
        let sevenDaysAgo = Date().addingTimeInterval(-86400 * 7)
        let criteria = PurchaseRecordQueryCriteria(dateRange: sevenDaysAgo...Date())
        let data = try await repository.exportData(by: criteria)
        
        // Then
        let csvString = String(data: data, encoding: .utf8)
        XCTAssertNotNil(csvString)
        XCTAssertTrue(csvString!.contains(record1.id.uuidString))
        XCTAssertFalse(csvString!.contains(record2.id.uuidString))
    }
}
