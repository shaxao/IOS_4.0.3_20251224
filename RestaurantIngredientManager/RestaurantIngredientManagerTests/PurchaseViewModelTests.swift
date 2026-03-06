//
//  PurchaseViewModelTests.swift
//  RestaurantIngredientManagerTests
//
//  Unit tests for PurchaseViewModel
//

import XCTest
import Combine
@testable import RestaurantIngredientManager

class PurchaseViewModelTests: XCTestCase {
    
    var sut: PurchaseViewModel!
    var mockRepository: MockPurchaseRecordRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockPurchaseRecordRepository()
        sut = PurchaseViewModel(repository: mockRepository)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(sut, "ViewModel should initialize")
        XCTAssertTrue(sut.purchaseRecords.isEmpty, "Should start with empty records")
        XCTAssertNil(sut.startDate, "Start date should be nil")
        XCTAssertNil(sut.endDate, "End date should be nil")
    }
    
    // MARK: - Load Purchase Records Tests
    
    func testLoadPurchaseRecords() {
        let expectation = XCTestExpectation(description: "Load purchase records")
        
        let testRecords = createTestPurchaseRecords(count: 5)
        mockRepository.recordsToReturn = testRecords
        
        sut.$purchaseRecords
            .dropFirst()
            .sink { records in
                XCTAssertEqual(records.count, 5, "Should load 5 records")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.loadPurchaseRecords()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadPurchaseRecordsError() {
        let expectation = XCTestExpectation(description: "Handle load error")
        
        mockRepository.shouldThrowError = true
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage, "Should set error message")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.loadPurchaseRecords()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Date Filter Tests
    
    func testFilterByDateRange() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        
        let testRecords = [
            createPurchaseRecord(date: now),
            createPurchaseRecord(date: yesterday),
            createPurchaseRecord(date: twoDaysAgo),
            createPurchaseRecord(date: threeDaysAgo)
        ]
        mockRepository.recordsToReturn = testRecords
        sut.loadPurchaseRecords()
        
        sut.startDate = twoDaysAgo
        sut.endDate = now
        
        let filtered = sut.filteredPurchaseRecords
        XCTAssertEqual(filtered.count, 3, "Should filter to 3 records within date range")
    }
    
    func testFilterByStartDateOnly() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        
        let testRecords = [
            createPurchaseRecord(date: now),
            createPurchaseRecord(date: yesterday),
            createPurchaseRecord(date: twoDaysAgo)
        ]
        mockRepository.recordsToReturn = testRecords
        sut.loadPurchaseRecords()
        
        sut.startDate = yesterday
        
        let filtered = sut.filteredPurchaseRecords
        XCTAssertEqual(filtered.count, 2, "Should filter records after start date")
    }
    
    func testFilterByEndDateOnly() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        
        let testRecords = [
            createPurchaseRecord(date: now),
            createPurchaseRecord(date: yesterday),
            createPurchaseRecord(date: twoDaysAgo)
        ]
        mockRepository.recordsToReturn = testRecords
        sut.loadPurchaseRecords()
        
        sut.endDate = yesterday
        
        let filtered = sut.filteredPurchaseRecords
        XCTAssertEqual(filtered.count, 2, "Should filter records before end date")
    }
    
    // MARK: - Cost Analysis Tests
    
    func testTotalCost() {
        let testRecords = [
            createPurchaseRecord(totalCost: 100),
            createPurchaseRecord(totalCost: 200),
            createPurchaseRecord(totalCost: 300)
        ]
        mockRepository.recordsToReturn = testRecords
        sut.loadPurchaseRecords()
        
        let total = sut.totalCost
        XCTAssertEqual(total, 600, "Should calculate total cost correctly")
    }
    
    func testAverageCost() {
        let testRecords = [
            createPurchaseRecord(totalCost: 100),
            createPurchaseRecord(totalCost: 200),
            createPurchaseRecord(totalCost: 300)
        ]
        mockRepository.recordsToReturn = testRecords
        sut.loadPurchaseRecords()
        
        let average = sut.averageCost
        XCTAssertEqual(average, 200, "Should calculate average cost correctly")
    }
    
    func testCostByCategory() {
        let ingredient1 = createIngredient(category: .fruit)
        let ingredient2 = createIngredient(category: .vegetable)
        let ingredient3 = createIngredient(category: .fruit)
        
        let testRecords = [
            createPurchaseRecord(ingredient: ingredient1, totalCost: 100),
            createPurchaseRecord(ingredient: ingredient2, totalCost: 200),
            createPurchaseRecord(ingredient: ingredient3, totalCost: 150)
        ]
        mockRepository.recordsToReturn = testRecords
        sut.loadPurchaseRecords()
        
        let costByCategory = sut.costByCategory
        XCTAssertEqual(costByCategory[.fruit], 250, "Should calculate fruit cost correctly")
        XCTAssertEqual(costByCategory[.vegetable], 200, "Should calculate vegetable cost correctly")
    }
    
    func testCostBySupplier() {
        let supplier1 = createSupplier(name: "Supplier A")
        let supplier2 = createSupplier(name: "Supplier B")
        
        let testRecords = [
            createPurchaseRecord(supplier: supplier1, totalCost: 100),
            createPurchaseRecord(supplier: supplier2, totalCost: 200),
            createPurchaseRecord(supplier: supplier1, totalCost: 150)
        ]
        mockRepository.recordsToReturn = testRecords
        sut.loadPurchaseRecords()
        
        let costBySupplier = sut.costBySupplier
        XCTAssertEqual(costBySupplier[supplier1.id], 250, "Should calculate Supplier A cost correctly")
        XCTAssertEqual(costBySupplier[supplier2.id], 200, "Should calculate Supplier B cost correctly")
    }
    
    // MARK: - Create Purchase Record Tests
    
    func testCreatePurchaseRecord() {
        let expectation = XCTestExpectation(description: "Create purchase record")
        
        let ingredient = createIngredient()
        let supplier = createSupplier()
        
        sut.createPurchaseRecord(
            ingredient: ingredient,
            supplier: supplier,
            quantity: 10,
            unitCost: 5.0
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockRepository.createWasCalled, "Should call create on repository")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Export Tests
    
    func testExportToCSV() {
        let testRecords = createTestPurchaseRecords(count: 3)
        mockRepository.recordsToReturn = testRecords
        sut.loadPurchaseRecords()
        
        let csvData = sut.exportToCSV()
        
        XCTAssertNotNil(csvData, "Should generate CSV data")
        XCTAssertTrue(csvData!.count > 0, "CSV data should not be empty")
        
        let csvString = String(data: csvData!, encoding: .utf8)
        XCTAssertNotNil(csvString, "Should be valid UTF-8 string")
        XCTAssertTrue(csvString!.contains("Date"), "Should contain header")
    }
    
    // MARK: - Performance Tests
    
    func testLoadLargeDatasetPerformance() {
        let testRecords = createTestPurchaseRecords(count: 1000)
        mockRepository.recordsToReturn = testRecords
        
        measure {
            sut.loadPurchaseRecords()
        }
    }
    
    func testCostCalculationPerformance() {
        let testRecords = createTestPurchaseRecords(count: 1000)
        mockRepository.recordsToReturn = testRecords
        sut.loadPurchaseRecords()
        
        measure {
            _ = sut.totalCost
            _ = sut.averageCost
            _ = sut.costByCategory
            _ = sut.costBySupplier
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestPurchaseRecords(count: Int) -> [PurchaseRecord] {
        return (0..<count).map { index in
            createPurchaseRecord(totalCost: Double(index * 10))
        }
    }
    
    private func createPurchaseRecord(
        ingredient: Ingredient? = nil,
        supplier: Supplier? = nil,
        date: Date = Date(),
        totalCost: Double = 100
    ) -> PurchaseRecord {
        return PurchaseRecord(
            id: UUID(),
            ingredientId: ingredient?.id ?? UUID(),
            supplierId: supplier?.id ?? UUID(),
            quantity: 10,
            unitCost: totalCost / 10,
            totalCost: totalCost,
            purchaseDate: date,
            notes: nil
        )
    }
    
    private func createIngredient(category: Category = .other) -> Ingredient {
        return Ingredient(
            id: UUID(),
            name: "Test Ingredient",
            category: category,
            quantity: 10,
            unit: "kg",
            expirationDate: Date().addingTimeInterval(86400 * 7),
            storageLocation: createStorageLocation(),
            supplier: nil,
            barcode: nil,
            qrCode: nil,
            minimumStockThreshold: 5,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createSupplier(name: String = "Test Supplier") -> Supplier {
        return Supplier(
            id: UUID(),
            name: name,
            contactPerson: nil,
            phone: nil,
            email: nil,
            address: nil,
            notes: nil
        )
    }
    
    private func createStorageLocation() -> StorageLocation {
        return StorageLocation(
            id: UUID(),
            name: "Test Location",
            type: .refrigerator,
            temperature: nil,
            isCustom: false
        )
    }
}

// MARK: - Mock Repository

class MockPurchaseRecordRepository: PurchaseRecordRepositoryProtocol {
    var recordsToReturn: [PurchaseRecord] = []
    var shouldThrowError = false
    var createWasCalled = false
    
    func fetchAll() throws -> [PurchaseRecord] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: -1, userInfo: nil)
        }
        return recordsToReturn
    }
    
    func fetch(by id: UUID) throws -> PurchaseRecord? {
        return recordsToReturn.first { $0.id == id }
    }
    
    func fetchByIngredient(_ ingredientId: UUID) throws -> [PurchaseRecord] {
        return recordsToReturn.filter { $0.ingredientId == ingredientId }
    }
    
    func fetchBySupplier(_ supplierId: UUID) throws -> [PurchaseRecord] {
        return recordsToReturn.filter { $0.supplierId == supplierId }
    }
    
    func fetchByDateRange(start: Date, end: Date) throws -> [PurchaseRecord] {
        return recordsToReturn.filter { $0.purchaseDate >= start && $0.purchaseDate <= end }
    }
    
    func create(_ record: PurchaseRecord) throws {
        createWasCalled = true
        recordsToReturn.append(record)
    }
    
    func update(_ record: PurchaseRecord) throws {
        if let index = recordsToReturn.firstIndex(where: { $0.id == record.id }) {
            recordsToReturn[index] = record
        }
    }
    
    func delete(_ record: PurchaseRecord) throws {
        recordsToReturn.removeAll { $0.id == record.id }
    }
}
