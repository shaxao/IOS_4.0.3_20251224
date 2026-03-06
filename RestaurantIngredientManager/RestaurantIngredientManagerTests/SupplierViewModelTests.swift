//
//  SupplierViewModelTests.swift
//  RestaurantIngredientManagerTests
//
//  Unit tests for SupplierViewModel
//

import XCTest
import Combine
@testable import RestaurantIngredientManager

class SupplierViewModelTests: XCTestCase {
    
    var sut: SupplierViewModel!
    var mockRepository: MockSupplierRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockSupplierRepository()
        sut = SupplierViewModel(repository: mockRepository)
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
        XCTAssertTrue(sut.suppliers.isEmpty, "Should start with empty suppliers")
        XCTAssertEqual(sut.searchText, "", "Search text should be empty")
    }
    
    // MARK: - Load Suppliers Tests
    
    func testLoadSuppliers() {
        let expectation = XCTestExpectation(description: "Load suppliers")
        
        let testSuppliers = createTestSuppliers(count: 5)
        mockRepository.suppliersToReturn = testSuppliers
        
        sut.$suppliers
            .dropFirst()
            .sink { suppliers in
                XCTAssertEqual(suppliers.count, 5, "Should load 5 suppliers")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.loadSuppliers()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadSuppliersError() {
        let expectation = XCTestExpectation(description: "Handle load error")
        
        mockRepository.shouldThrowError = true
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage, "Should set error message")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.loadSuppliers()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Search Tests
    
    func testSearchSuppliers() {
        let expectation = XCTestExpectation(description: "Search suppliers")
        
        let testSuppliers = [
            createSupplier(name: "ABC Supplier"),
            createSupplier(name: "XYZ Supplier"),
            createSupplier(name: "ABC Foods")
        ]
        mockRepository.suppliersToReturn = testSuppliers
        sut.loadSuppliers()
        
        sut.searchText = "ABC"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let filtered = self.sut.filteredSuppliers
            XCTAssertEqual(filtered.count, 2, "Should find 2 suppliers with ABC")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSearchByContactPerson() {
        let testSuppliers = [
            createSupplier(name: "Supplier A", contactPerson: "John Doe"),
            createSupplier(name: "Supplier B", contactPerson: "Jane Smith"),
            createSupplier(name: "Supplier C", contactPerson: "John Wilson")
        ]
        mockRepository.suppliersToReturn = testSuppliers
        sut.loadSuppliers()
        
        sut.searchText = "John"
        
        let filtered = sut.filteredSuppliers
        XCTAssertEqual(filtered.count, 2, "Should find 2 suppliers with John")
    }
    
    func testSearchByPhone() {
        let testSuppliers = [
            createSupplier(name: "Supplier A", phone: "123-456-7890"),
            createSupplier(name: "Supplier B", phone: "987-654-3210"),
            createSupplier(name: "Supplier C", phone: "123-999-8888")
        ]
        mockRepository.suppliersToReturn = testSuppliers
        sut.loadSuppliers()
        
        sut.searchText = "123"
        
        let filtered = sut.filteredSuppliers
        XCTAssertEqual(filtered.count, 2, "Should find 2 suppliers with 123")
    }
    
    // MARK: - Create Supplier Tests
    
    func testCreateSupplier() {
        let expectation = XCTestExpectation(description: "Create supplier")
        
        sut.createSupplier(
            name: "New Supplier",
            contactPerson: "John Doe",
            phone: "123-456-7890",
            email: "john@example.com",
            address: "123 Main St",
            notes: "Test notes"
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockRepository.createWasCalled, "Should call create on repository")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCreateSupplierValidation() {
        let expectation = XCTestExpectation(description: "Validate supplier creation")
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage, "Should set error for empty name")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.createSupplier(name: "", contactPerson: nil, phone: nil, email: nil, address: nil, notes: nil)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Update Supplier Tests
    
    func testUpdateSupplier() {
        let expectation = XCTestExpectation(description: "Update supplier")
        
        let supplier = createSupplier(name: "Original Name")
        mockRepository.suppliersToReturn = [supplier]
        sut.loadSuppliers()
        
        var updatedSupplier = supplier
        updatedSupplier.name = "Updated Name"
        
        sut.updateSupplier(updatedSupplier)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockRepository.updateWasCalled, "Should call update on repository")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Delete Supplier Tests
    
    func testDeleteSupplier() {
        let expectation = XCTestExpectation(description: "Delete supplier")
        
        let supplier = createSupplier(name: "To Delete")
        mockRepository.suppliersToReturn = [supplier]
        sut.loadSuppliers()
        
        sut.deleteSupplier(supplier)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockRepository.deleteWasCalled, "Should call delete on repository")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteSupplierWithIngredients() {
        let expectation = XCTestExpectation(description: "Handle delete with ingredients")
        
        let supplier = createSupplier(name: "Has Ingredients")
        mockRepository.suppliersToReturn = [supplier]
        mockRepository.hasIngredientsToReturn = true
        sut.loadSuppliers()
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage, "Should show error for supplier with ingredients")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.deleteSupplier(supplier)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Validation Tests
    
    func testValidateEmail() {
        XCTAssertTrue(sut.isValidEmail("test@example.com"), "Should validate correct email")
        XCTAssertTrue(sut.isValidEmail("user.name@domain.co.uk"), "Should validate complex email")
        
        XCTAssertFalse(sut.isValidEmail("invalid"), "Should reject invalid email")
        XCTAssertFalse(sut.isValidEmail("@example.com"), "Should reject email without local part")
        XCTAssertFalse(sut.isValidEmail("test@"), "Should reject email without domain")
    }
    
    func testValidatePhone() {
        XCTAssertTrue(sut.isValidPhone("123-456-7890"), "Should validate phone with dashes")
        XCTAssertTrue(sut.isValidPhone("(123) 456-7890"), "Should validate phone with parentheses")
        XCTAssertTrue(sut.isValidPhone("1234567890"), "Should validate phone without formatting")
        
        XCTAssertFalse(sut.isValidPhone("123"), "Should reject too short phone")
        XCTAssertFalse(sut.isValidPhone("abc-def-ghij"), "Should reject non-numeric phone")
    }
    
    // MARK: - Sorting Tests
    
    func testSortByName() {
        let testSuppliers = [
            createSupplier(name: "Zebra Supplier"),
            createSupplier(name: "Alpha Supplier"),
            createSupplier(name: "Beta Supplier")
        ]
        mockRepository.suppliersToReturn = testSuppliers
        sut.loadSuppliers()
        
        sut.sortBy(.name)
        
        let sorted = sut.sortedSuppliers
        XCTAssertEqual(sorted[0].name, "Alpha Supplier", "Should sort alphabetically")
        XCTAssertEqual(sorted[1].name, "Beta Supplier")
        XCTAssertEqual(sorted[2].name, "Zebra Supplier")
    }
    
    // MARK: - Statistics Tests
    
    func testSupplierCount() {
        let testSuppliers = createTestSuppliers(count: 10)
        mockRepository.suppliersToReturn = testSuppliers
        sut.loadSuppliers()
        
        XCTAssertEqual(sut.totalSuppliers, 10, "Should count total suppliers")
    }
    
    func testSuppliersWithIngredients() {
        let testSuppliers = createTestSuppliers(count: 5)
        mockRepository.suppliersToReturn = testSuppliers
        mockRepository.ingredientCountsToReturn = [
            testSuppliers[0].id: 10,
            testSuppliers[1].id: 0,
            testSuppliers[2].id: 5
        ]
        sut.loadSuppliers()
        
        let withIngredients = sut.suppliersWithIngredients
        XCTAssertEqual(withIngredients.count, 2, "Should find 2 suppliers with ingredients")
    }
    
    // MARK: - Performance Tests
    
    func testLoadLargeDatasetPerformance() {
        let testSuppliers = createTestSuppliers(count: 1000)
        mockRepository.suppliersToReturn = testSuppliers
        
        measure {
            sut.loadSuppliers()
        }
    }
    
    func testSearchPerformance() {
        let testSuppliers = createTestSuppliers(count: 1000)
        mockRepository.suppliersToReturn = testSuppliers
        sut.loadSuppliers()
        
        measure {
            sut.searchText = "Supplier 500"
            _ = sut.filteredSuppliers
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestSuppliers(count: Int) -> [Supplier] {
        return (0..<count).map { index in
            createSupplier(name: "Supplier \(index)")
        }
    }
    
    private func createSupplier(
        name: String,
        contactPerson: String? = nil,
        phone: String? = nil,
        email: String? = nil
    ) -> Supplier {
        return Supplier(
            id: UUID(),
            name: name,
            contactPerson: contactPerson,
            phone: phone,
            email: email,
            address: nil,
            notes: nil
        )
    }
}

// MARK: - Mock Repository

class MockSupplierRepository: SupplierRepositoryProtocol {
    var suppliersToReturn: [Supplier] = []
    var shouldThrowError = false
    var createWasCalled = false
    var updateWasCalled = false
    var deleteWasCalled = false
    var hasIngredientsToReturn = false
    var ingredientCountsToReturn: [UUID: Int] = [:]
    
    func fetchAll() throws -> [Supplier] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: -1, userInfo: nil)
        }
        return suppliersToReturn
    }
    
    func fetch(by id: UUID) throws -> Supplier? {
        return suppliersToReturn.first { $0.id == id }
    }
    
    func search(query: String) throws -> [Supplier] {
        return suppliersToReturn.filter {
            $0.name.contains(query) ||
            $0.contactPerson?.contains(query) == true ||
            $0.phone?.contains(query) == true
        }
    }
    
    func create(_ supplier: Supplier) throws {
        createWasCalled = true
        suppliersToReturn.append(supplier)
    }
    
    func update(_ supplier: Supplier) throws {
        updateWasCalled = true
        if let index = suppliersToReturn.firstIndex(where: { $0.id == supplier.id }) {
            suppliersToReturn[index] = supplier
        }
    }
    
    func delete(_ supplier: Supplier) throws {
        if hasIngredientsToReturn {
            throw NSError(domain: "TestError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Cannot delete supplier with ingredients"
            ])
        }
        deleteWasCalled = true
        suppliersToReturn.removeAll { $0.id == supplier.id }
    }
    
    func hasIngredients(_ supplierId: UUID) throws -> Bool {
        return hasIngredientsToReturn
    }
    
    func ingredientCount(for supplierId: UUID) throws -> Int {
        return ingredientCountsToReturn[supplierId] ?? 0
    }
}
