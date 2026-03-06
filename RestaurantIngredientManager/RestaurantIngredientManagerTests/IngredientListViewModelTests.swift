//
//  IngredientListViewModelTests.swift
//  RestaurantIngredientManagerTests
//
//  Unit tests for IngredientListViewModel
//

import XCTest
import Combine
@testable import RestaurantIngredientManager

class IngredientListViewModelTests: XCTestCase {
    
    var sut: IngredientListViewModel!
    var mockRepository: MockIngredientRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockIngredientRepository()
        sut = IngredientListViewModel(repository: mockRepository)
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
        XCTAssertTrue(sut.ingredients.isEmpty, "Should start with empty ingredients")
        XCTAssertEqual(sut.searchText, "", "Search text should be empty")
        XCTAssertNil(sut.selectedCategory, "No category should be selected")
    }
    
    // MARK: - Load Ingredients Tests
    
    func testLoadIngredients() {
        let expectation = XCTestExpectation(description: "Load ingredients")
        
        let testIngredients = createTestIngredients(count: 5)
        mockRepository.ingredientsToReturn = testIngredients
        
        sut.$ingredients
            .dropFirst()
            .sink { ingredients in
                XCTAssertEqual(ingredients.count, 5, "Should load 5 ingredients")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.loadIngredients()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadIngredientsError() {
        let expectation = XCTestExpectation(description: "Handle load error")
        
        mockRepository.shouldThrowError = true
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage, "Should set error message")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.loadIngredients()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Search Tests
    
    func testSearchIngredients() {
        let expectation = XCTestExpectation(description: "Search ingredients")
        
        let testIngredients = createTestIngredients(count: 10)
        mockRepository.ingredientsToReturn = testIngredients
        sut.loadIngredients()
        
        sut.searchText = "Ingredient 5"
        
        // Wait for debounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let filtered = self.sut.filteredIngredients
            XCTAssertEqual(filtered.count, 1, "Should find 1 matching ingredient")
            XCTAssertEqual(filtered.first?.name, "Ingredient 5")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSearchDebounce() {
        let expectation = XCTestExpectation(description: "Debounce search")
        
        sut.searchText = "A"
        sut.searchText = "AB"
        sut.searchText = "ABC"
        
        // Should only trigger once after debounce period
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            XCTAssertEqual(self.mockRepository.searchCallCount, 1, "Should debounce search calls")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Filter Tests
    
    func testFilterByCategory() {
        let testIngredients = [
            createIngredient(name: "Apple", category: .fruit),
            createIngredient(name: "Carrot", category: .vegetable),
            createIngredient(name: "Banana", category: .fruit)
        ]
        mockRepository.ingredientsToReturn = testIngredients
        sut.loadIngredients()
        
        sut.selectedCategory = .fruit
        
        let filtered = sut.filteredIngredients
        XCTAssertEqual(filtered.count, 2, "Should filter to 2 fruits")
        XCTAssertTrue(filtered.allSatisfy { $0.category == .fruit })
    }
    
    func testFilterBySupplier() {
        let supplier1 = createSupplier(name: "Supplier A")
        let supplier2 = createSupplier(name: "Supplier B")
        
        let testIngredients = [
            createIngredient(name: "Item 1", supplier: supplier1),
            createIngredient(name: "Item 2", supplier: supplier2),
            createIngredient(name: "Item 3", supplier: supplier1)
        ]
        mockRepository.ingredientsToReturn = testIngredients
        sut.loadIngredients()
        
        sut.selectedSupplier = supplier1
        
        let filtered = sut.filteredIngredients
        XCTAssertEqual(filtered.count, 2, "Should filter to 2 items from Supplier A")
    }
    
    func testFilterByStorageLocation() {
        let location1 = createStorageLocation(name: "Fridge")
        let location2 = createStorageLocation(name: "Freezer")
        
        let testIngredients = [
            createIngredient(name: "Item 1", location: location1),
            createIngredient(name: "Item 2", location: location2),
            createIngredient(name: "Item 3", location: location1)
        ]
        mockRepository.ingredientsToReturn = testIngredients
        sut.loadIngredients()
        
        sut.selectedLocation = location1
        
        let filtered = sut.filteredIngredients
        XCTAssertEqual(filtered.count, 2, "Should filter to 2 items in Fridge")
    }
    
    // MARK: - Expiration Tests
    
    func testExpiredIngredients() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let testIngredients = [
            createIngredient(name: "Expired", expirationDate: yesterday),
            createIngredient(name: "Fresh", expirationDate: tomorrow)
        ]
        mockRepository.ingredientsToReturn = testIngredients
        sut.loadIngredients()
        
        let expired = sut.expiredIngredients
        XCTAssertEqual(expired.count, 1, "Should have 1 expired ingredient")
        XCTAssertEqual(expired.first?.name, "Expired")
    }
    
    func testExpiringSoonIngredients() {
        let inTwoDays = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let inTenDays = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
        
        let testIngredients = [
            createIngredient(name: "Expiring Soon", expirationDate: inTwoDays),
            createIngredient(name: "Still Fresh", expirationDate: inTenDays)
        ]
        mockRepository.ingredientsToReturn = testIngredients
        sut.loadIngredients()
        
        let expiringSoon = sut.expiringSoonIngredients(days: 3)
        XCTAssertEqual(expiringSoon.count, 1, "Should have 1 ingredient expiring soon")
        XCTAssertEqual(expiringSoon.first?.name, "Expiring Soon")
    }
    
    // MARK: - Low Stock Tests
    
    func testLowStockIngredients() {
        let testIngredients = [
            createIngredient(name: "Low Stock", quantity: 5, minimumThreshold: 10),
            createIngredient(name: "Good Stock", quantity: 20, minimumThreshold: 10)
        ]
        mockRepository.ingredientsToReturn = testIngredients
        sut.loadIngredients()
        
        let lowStock = sut.lowStockIngredients
        XCTAssertEqual(lowStock.count, 1, "Should have 1 low stock ingredient")
        XCTAssertEqual(lowStock.first?.name, "Low Stock")
    }
    
    // MARK: - Delete Tests
    
    func testDeleteIngredient() {
        let expectation = XCTestExpectation(description: "Delete ingredient")
        
        let ingredient = createIngredient(name: "To Delete")
        mockRepository.ingredientsToReturn = [ingredient]
        sut.loadIngredients()
        
        sut.deleteIngredient(ingredient)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockRepository.deleteWasCalled, "Should call delete on repository")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testLoadLargeDatasetPerformance() {
        let testIngredients = createTestIngredients(count: 1000)
        mockRepository.ingredientsToReturn = testIngredients
        
        measure {
            sut.loadIngredients()
        }
    }
    
    func testFilterPerformance() {
        let testIngredients = createTestIngredients(count: 1000)
        mockRepository.ingredientsToReturn = testIngredients
        sut.loadIngredients()
        
        measure {
            sut.searchText = "Ingredient 500"
            _ = sut.filteredIngredients
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestIngredients(count: Int) -> [Ingredient] {
        return (0..<count).map { index in
            createIngredient(name: "Ingredient \(index)")
        }
    }
    
    private func createIngredient(
        name: String,
        category: Category = .other,
        quantity: Double = 10,
        minimumThreshold: Double = 5,
        expirationDate: Date? = nil,
        supplier: Supplier? = nil,
        location: StorageLocation? = nil
    ) -> Ingredient {
        return Ingredient(
            id: UUID(),
            name: name,
            category: category,
            quantity: quantity,
            unit: "kg",
            expirationDate: expirationDate ?? Date().addingTimeInterval(86400 * 7),
            storageLocation: location ?? createStorageLocation(),
            supplier: supplier,
            barcode: nil,
            qrCode: nil,
            minimumStockThreshold: minimumThreshold,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createSupplier(name: String) -> Supplier {
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
    
    private func createStorageLocation(name: String = "Default Location") -> StorageLocation {
        return StorageLocation(
            id: UUID(),
            name: name,
            type: .refrigerator,
            temperature: nil,
            isCustom: false
        )
    }
}

// MARK: - Mock Repository

class MockIngredientRepository: IngredientRepositoryProtocol {
    var ingredientsToReturn: [Ingredient] = []
    var shouldThrowError = false
    var searchCallCount = 0
    var deleteWasCalled = false
    
    func fetchAll() throws -> [Ingredient] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: -1, userInfo: nil)
        }
        return ingredientsToReturn
    }
    
    func fetch(by id: UUID) throws -> Ingredient? {
        return ingredientsToReturn.first { $0.id == id }
    }
    
    func search(query: String) throws -> [Ingredient] {
        searchCallCount += 1
        return ingredientsToReturn.filter { $0.name.contains(query) }
    }
    
    func create(_ ingredient: Ingredient) throws {
        ingredientsToReturn.append(ingredient)
    }
    
    func update(_ ingredient: Ingredient) throws {
        if let index = ingredientsToReturn.firstIndex(where: { $0.id == ingredient.id }) {
            ingredientsToReturn[index] = ingredient
        }
    }
    
    func delete(_ ingredient: Ingredient) throws {
        deleteWasCalled = true
        ingredientsToReturn.removeAll { $0.id == ingredient.id }
    }
    
    func fetchExpired() throws -> [Ingredient] {
        return ingredientsToReturn.filter { $0.expirationDate < Date() }
    }
    
    func fetchExpiringSoon(days: Int) throws -> [Ingredient] {
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date())!
        return ingredientsToReturn.filter { $0.expirationDate < futureDate && $0.expirationDate >= Date() }
    }
    
    func fetchLowStock() throws -> [Ingredient] {
        return ingredientsToReturn.filter { $0.quantity <= $0.minimumStockThreshold }
    }
}
