//
//  IngredientDetailViewModelTests.swift
//  RestaurantIngredientManagerTests
//
//  Unit tests for IngredientDetailViewModel
//

import XCTest
import Combine
@testable import RestaurantIngredientManager

class IngredientDetailViewModelTests: XCTestCase {
    
    var sut: IngredientDetailViewModel!
    var mockRepository: MockIngredientRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockIngredientRepository()
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitializationWithNewIngredient() {
        sut = IngredientDetailViewModel(ingredient: nil, repository: mockRepository)
        
        XCTAssertNotNil(sut, "ViewModel should initialize")
        XCTAssertTrue(sut.isNewIngredient, "Should be new ingredient")
        XCTAssertEqual(sut.name, "", "Name should be empty")
        XCTAssertEqual(sut.quantity, 0, "Quantity should be 0")
    }
    
    func testInitializationWithExistingIngredient() {
        let ingredient = createTestIngredient(name: "Test Ingredient", quantity: 10)
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        
        XCTAssertFalse(sut.isNewIngredient, "Should not be new ingredient")
        XCTAssertEqual(sut.name, "Test Ingredient", "Should load ingredient name")
        XCTAssertEqual(sut.quantity, 10, "Should load ingredient quantity")
    }
    
    // MARK: - Validation Tests
    
    func testValidateEmptyName() {
        sut = IngredientDetailViewModel(ingredient: nil, repository: mockRepository)
        sut.name = ""
        
        let isValid = sut.validate()
        
        XCTAssertFalse(isValid, "Should not validate with empty name")
        XCTAssertNotNil(sut.errorMessage, "Should have error message")
        XCTAssertTrue(sut.errorMessage!.contains("名称"), "Error should mention name")
    }
    
    func testValidateNegativeQuantity() {
        sut = IngredientDetailViewModel(ingredient: nil, repository: mockRepository)
        sut.name = "Valid Name"
        sut.quantity = -5
        
        let isValid = sut.validate()
        
        XCTAssertFalse(isValid, "Should not validate with negative quantity")
        XCTAssertNotNil(sut.errorMessage, "Should have error message")
    }
    
    func testValidateEmptyUnit() {
        sut = IngredientDetailViewModel(ingredient: nil, repository: mockRepository)
        sut.name = "Valid Name"
        sut.quantity = 10
        sut.unit = ""
        
        let isValid = sut.validate()
        
        XCTAssertFalse(isValid, "Should not validate with empty unit")
        XCTAssertNotNil(sut.errorMessage, "Should have error message")
    }
    
    func testValidateNoStorageLocation() {
        sut = IngredientDetailViewModel(ingredient: nil, repository: mockRepository)
        sut.name = "Valid Name"
        sut.quantity = 10
        sut.unit = "kg"
        sut.selectedLocation = nil
        
        let isValid = sut.validate()
        
        XCTAssertFalse(isValid, "Should not validate without storage location")
        XCTAssertNotNil(sut.errorMessage, "Should have error message")
    }
    
    func testValidateValidData() {
        sut = IngredientDetailViewModel(ingredient: nil, repository: mockRepository)
        sut.name = "Valid Name"
        sut.quantity = 10
        sut.unit = "kg"
        sut.selectedLocation = createStorageLocation()
        sut.expirationDate = Date().addingTimeInterval(86400 * 7)
        
        let isValid = sut.validate()
        
        XCTAssertTrue(isValid, "Should validate with valid data")
        XCTAssertNil(sut.errorMessage, "Should have no error message")
    }
    
    // MARK: - Save Tests
    
    func testSaveNewIngredient() {
        let expectation = XCTestExpectation(description: "Save new ingredient")
        
        sut = IngredientDetailViewModel(ingredient: nil, repository: mockRepository)
        sut.name = "New Ingredient"
        sut.quantity = 10
        sut.unit = "kg"
        sut.selectedLocation = createStorageLocation()
        sut.selectedCategory = .fruit
        sut.expirationDate = Date().addingTimeInterval(86400 * 7)
        
        sut.save()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockRepository.createWasCalled, "Should call create on repository")
            XCTAssertEqual(self.mockRepository.ingredientsToReturn.count, 1, "Should have 1 ingredient")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSaveExistingIngredient() {
        let expectation = XCTestExpectation(description: "Save existing ingredient")
        
        let ingredient = createTestIngredient(name: "Original Name")
        mockRepository.ingredientsToReturn = [ingredient]
        
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        sut.name = "Updated Name"
        
        sut.save()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockRepository.updateWasCalled, "Should call update on repository")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSaveInvalidData() {
        let expectation = XCTestExpectation(description: "Handle invalid data")
        
        sut = IngredientDetailViewModel(ingredient: nil, repository: mockRepository)
        sut.name = "" // Invalid
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage, "Should set error message")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.save()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Expiration Tests
    
    func testIsExpired() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let ingredient = createTestIngredient(expirationDate: yesterday)
        
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        
        XCTAssertTrue(sut.isExpired, "Should be expired")
    }
    
    func testIsNotExpired() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let ingredient = createTestIngredient(expirationDate: tomorrow)
        
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        
        XCTAssertFalse(sut.isExpired, "Should not be expired")
    }
    
    func testIsExpiringSoon() {
        let inTwoDays = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let ingredient = createTestIngredient(expirationDate: inTwoDays)
        
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        
        XCTAssertTrue(sut.isExpiringSoon(days: 3), "Should be expiring soon")
        XCTAssertFalse(sut.isExpiringSoon(days: 1), "Should not be expiring soon")
    }
    
    func testDaysUntilExpiration() {
        let inThreeDays = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        let ingredient = createTestIngredient(expirationDate: inThreeDays)
        
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        
        let days = sut.daysUntilExpiration
        XCTAssertEqual(days, 3, "Should calculate days correctly")
    }
    
    // MARK: - Stock Level Tests
    
    func testIsLowStock() {
        let ingredient = createTestIngredient(quantity: 5, minimumThreshold: 10)
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        
        XCTAssertTrue(sut.isLowStock, "Should be low stock")
    }
    
    func testIsNotLowStock() {
        let ingredient = createTestIngredient(quantity: 15, minimumThreshold: 10)
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        
        XCTAssertFalse(sut.isLowStock, "Should not be low stock")
    }
    
    func testStockPercentage() {
        let ingredient = createTestIngredient(quantity: 5, minimumThreshold: 10)
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        
        let percentage = sut.stockPercentage
        XCTAssertEqual(percentage, 50, "Should calculate 50% stock level")
    }
    
    // MARK: - Barcode/QR Code Tests
    
    func testSetBarcode() {
        sut = IngredientDetailViewModel(ingredient: nil, repository: mockRepository)
        
        sut.setBarcode("1234567890128")
        
        XCTAssertEqual(sut.barcode, "1234567890128", "Should set barcode")
    }
    
    func testSetQRCode() {
        sut = IngredientDetailViewModel(ingredient: nil, repository: mockRepository)
        
        sut.setQRCode("https://example.com/ingredient/123")
        
        XCTAssertEqual(sut.qrCode, "https://example.com/ingredient/123", "Should set QR code")
    }
    
    func testClearBarcode() {
        let ingredient = createTestIngredient(barcode: "1234567890128")
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        
        sut.clearBarcode()
        
        XCTAssertNil(sut.barcode, "Should clear barcode")
    }
    
    // MARK: - Quantity Adjustment Tests
    
    func testIncreaseQuantity() {
        let ingredient = createTestIngredient(quantity: 10)
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        
        sut.increaseQuantity(by: 5)
        
        XCTAssertEqual(sut.quantity, 15, "Should increase quantity")
    }
    
    func testDecreaseQuantity() {
        let ingredient = createTestIngredient(quantity: 10)
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        
        sut.decreaseQuantity(by: 3)
        
        XCTAssertEqual(sut.quantity, 7, "Should decrease quantity")
    }
    
    func testDecreaseQuantityBelowZero() {
        let ingredient = createTestIngredient(quantity: 5)
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        
        sut.decreaseQuantity(by: 10)
        
        XCTAssertEqual(sut.quantity, 0, "Should not go below zero")
    }
    
    // MARK: - Reset Tests
    
    func testReset() {
        let ingredient = createTestIngredient(name: "Original")
        sut = IngredientDetailViewModel(ingredient: ingredient, repository: mockRepository)
        
        sut.name = "Modified"
        sut.quantity = 999
        
        sut.reset()
        
        XCTAssertEqual(sut.name, "Original", "Should reset to original name")
        XCTAssertNotEqual(sut.quantity, 999, "Should reset quantity")
    }
    
    // MARK: - Helper Methods
    
    private func createTestIngredient(
        name: String = "Test Ingredient",
        quantity: Double = 10,
        minimumThreshold: Double = 5,
        expirationDate: Date? = nil,
        barcode: String? = nil
    ) -> Ingredient {
        return Ingredient(
            id: UUID(),
            name: name,
            category: .other,
            quantity: quantity,
            unit: "kg",
            expirationDate: expirationDate ?? Date().addingTimeInterval(86400 * 7),
            storageLocation: createStorageLocation(),
            supplier: nil,
            barcode: barcode,
            qrCode: nil,
            minimumStockThreshold: minimumThreshold,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
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
