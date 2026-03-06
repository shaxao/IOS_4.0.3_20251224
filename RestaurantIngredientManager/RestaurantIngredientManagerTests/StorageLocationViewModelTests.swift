//
//  StorageLocationViewModelTests.swift
//  RestaurantIngredientManagerTests
//
//  Unit tests for StorageLocationViewModel
//

import XCTest
import Combine
@testable import RestaurantIngredientManager

class StorageLocationViewModelTests: XCTestCase {
    
    var sut: StorageLocationViewModel!
    var mockRepository: MockStorageLocationRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockStorageLocationRepository()
        sut = StorageLocationViewModel(repository: mockRepository)
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
        XCTAssertTrue(sut.locations.isEmpty, "Should start with empty locations")
        XCTAssertEqual(sut.searchText, "", "Search text should be empty")
    }
    
    // MARK: - Load Locations Tests
    
    func testLoadLocations() {
        let expectation = XCTestExpectation(description: "Load locations")
        
        let testLocations = createTestLocations(count: 5)
        mockRepository.locationsToReturn = testLocations
        
        sut.$locations
            .dropFirst()
            .sink { locations in
                XCTAssertEqual(locations.count, 5, "Should load 5 locations")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.loadLocations()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadLocationsError() {
        let expectation = XCTestExpectation(description: "Handle load error")
        
        mockRepository.shouldThrowError = true
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage, "Should set error message")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.loadLocations()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Search Tests
    
    func testSearchLocations() {
        let testLocations = [
            createLocation(name: "冰箱A", type: .refrigerator),
            createLocation(name: "冷冻室", type: .freezer),
            createLocation(name: "冰箱B", type: .refrigerator)
        ]
        mockRepository.locationsToReturn = testLocations
        sut.loadLocations()
        
        sut.searchText = "冰箱"
        
        let filtered = sut.filteredLocations
        XCTAssertEqual(filtered.count, 2, "Should find 2 locations with 冰箱")
    }
    
    // MARK: - Filter by Type Tests
    
    func testFilterByType() {
        let testLocations = [
            createLocation(name: "冰箱", type: .refrigerator),
            createLocation(name: "冷冻室", type: .freezer),
            createLocation(name: "干货区", type: .dryStorage),
            createLocation(name: "冰箱2", type: .refrigerator)
        ]
        mockRepository.locationsToReturn = testLocations
        sut.loadLocations()
        
        sut.selectedType = .refrigerator
        
        let filtered = sut.filteredLocations
        XCTAssertEqual(filtered.count, 2, "Should filter to 2 refrigerators")
        XCTAssertTrue(filtered.allSatisfy { $0.type == .refrigerator })
    }
    
    // MARK: - Group by Type Tests
    
    func testGroupByType() {
        let testLocations = [
            createLocation(name: "冰箱A", type: .refrigerator),
            createLocation(name: "冷冻室A", type: .freezer),
            createLocation(name: "冰箱B", type: .refrigerator),
            createLocation(name: "干货区", type: .dryStorage)
        ]
        mockRepository.locationsToReturn = testLocations
        sut.loadLocations()
        
        let grouped = sut.locationsByType
        
        XCTAssertEqual(grouped[.refrigerator]?.count, 2, "Should have 2 refrigerators")
        XCTAssertEqual(grouped[.freezer]?.count, 1, "Should have 1 freezer")
        XCTAssertEqual(grouped[.dryStorage]?.count, 1, "Should have 1 dry storage")
    }
    
    // MARK: - Create Location Tests
    
    func testCreateLocation() {
        let expectation = XCTestExpectation(description: "Create location")
        
        sut.createLocation(
            name: "新位置",
            type: .refrigerator,
            temperature: 4.0
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockRepository.createWasCalled, "Should call create on repository")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCreateLocationValidation() {
        let expectation = XCTestExpectation(description: "Validate location creation")
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage, "Should set error for empty name")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.createLocation(name: "", type: .refrigerator, temperature: nil)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Update Location Tests
    
    func testUpdateLocation() {
        let expectation = XCTestExpectation(description: "Update location")
        
        let location = createLocation(name: "原名称")
        mockRepository.locationsToReturn = [location]
        sut.loadLocations()
        
        var updatedLocation = location
        updatedLocation.name = "新名称"
        
        sut.updateLocation(updatedLocation)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockRepository.updateWasCalled, "Should call update on repository")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Delete Location Tests
    
    func testDeleteLocation() {
        let expectation = XCTestExpectation(description: "Delete location")
        
        let location = createLocation(name: "待删除")
        mockRepository.locationsToReturn = [location]
        sut.loadLocations()
        
        sut.deleteLocation(location)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockRepository.deleteWasCalled, "Should call delete on repository")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDeleteLocationWithIngredients() {
        let expectation = XCTestExpectation(description: "Handle delete with ingredients")
        
        let location = createLocation(name: "有食材")
        mockRepository.locationsToReturn = [location]
        mockRepository.hasIngredientsToReturn = true
        sut.loadLocations()
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage, "Should show error for location with ingredients")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.deleteLocation(location)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Predefined Locations Tests
    
    func testGetPredefinedLocations() {
        let predefined = sut.predefinedLocations
        
        XCTAssertGreaterThan(predefined.count, 0, "Should have predefined locations")
        XCTAssertTrue(predefined.contains { $0.type == .refrigerator }, "Should include refrigerator")
        XCTAssertTrue(predefined.contains { $0.type == .freezer }, "Should include freezer")
        XCTAssertTrue(predefined.contains { $0.type == .dryStorage }, "Should include dry storage")
    }
    
    func testAddPredefinedLocation() {
        let expectation = XCTestExpectation(description: "Add predefined location")
        
        let predefined = sut.predefinedLocations.first!
        
        sut.addPredefinedLocation(predefined)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.mockRepository.createWasCalled, "Should create predefined location")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Custom Location Tests
    
    func testFilterCustomLocations() {
        let testLocations = [
            createLocation(name: "预定义", type: .refrigerator, isCustom: false),
            createLocation(name: "自定义1", type: .custom, isCustom: true),
            createLocation(name: "自定义2", type: .custom, isCustom: true)
        ]
        mockRepository.locationsToReturn = testLocations
        sut.loadLocations()
        
        let customLocations = sut.customLocations
        
        XCTAssertEqual(customLocations.count, 2, "Should have 2 custom locations")
        XCTAssertTrue(customLocations.allSatisfy { $0.isCustom })
    }
    
    // MARK: - Temperature Validation Tests
    
    func testValidateTemperature() {
        XCTAssertTrue(sut.isValidTemperature(-20, for: .freezer), "Should accept -20°C for freezer")
        XCTAssertTrue(sut.isValidTemperature(4, for: .refrigerator), "Should accept 4°C for refrigerator")
        XCTAssertTrue(sut.isValidTemperature(20, for: .dryStorage), "Should accept 20°C for dry storage")
        
        XCTAssertFalse(sut.isValidTemperature(10, for: .freezer), "Should reject 10°C for freezer")
        XCTAssertFalse(sut.isValidTemperature(-10, for: .dryStorage), "Should reject -10°C for dry storage")
    }
    
    func testRecommendedTemperatureRange() {
        let freezerRange = sut.recommendedTemperatureRange(for: .freezer)
        XCTAssertLessThan(freezerRange.lowerBound, 0, "Freezer should be below 0°C")
        
        let refrigeratorRange = sut.recommendedTemperatureRange(for: .refrigerator)
        XCTAssertGreaterThan(refrigeratorRange.lowerBound, 0, "Refrigerator should be above 0°C")
        XCTAssertLessThan(refrigeratorRange.upperBound, 10, "Refrigerator should be below 10°C")
    }
    
    // MARK: - Statistics Tests
    
    func testLocationCount() {
        let testLocations = createTestLocations(count: 10)
        mockRepository.locationsToReturn = testLocations
        sut.loadLocations()
        
        XCTAssertEqual(sut.totalLocations, 10, "Should count total locations")
    }
    
    func testLocationsWithIngredients() {
        let testLocations = createTestLocations(count: 5)
        mockRepository.locationsToReturn = testLocations
        mockRepository.ingredientCountsToReturn = [
            testLocations[0].id: 10,
            testLocations[1].id: 0,
            testLocations[2].id: 5
        ]
        sut.loadLocations()
        
        let withIngredients = sut.locationsWithIngredients
        XCTAssertEqual(withIngredients.count, 2, "Should find 2 locations with ingredients")
    }
    
    func testEmptyLocations() {
        let testLocations = createTestLocations(count: 5)
        mockRepository.locationsToReturn = testLocations
        mockRepository.ingredientCountsToReturn = [
            testLocations[0].id: 10,
            testLocations[1].id: 0,
            testLocations[2].id: 0
        ]
        sut.loadLocations()
        
        let emptyLocations = sut.emptyLocations
        XCTAssertEqual(emptyLocations.count, 2, "Should find 2 empty locations")
    }
    
    // MARK: - Sorting Tests
    
    func testSortByName() {
        let testLocations = [
            createLocation(name: "C位置", type: .refrigerator),
            createLocation(name: "A位置", type: .freezer),
            createLocation(name: "B位置", type: .dryStorage)
        ]
        mockRepository.locationsToReturn = testLocations
        sut.loadLocations()
        
        sut.sortBy(.name)
        
        let sorted = sut.sortedLocations
        XCTAssertEqual(sorted[0].name, "A位置", "Should sort alphabetically")
        XCTAssertEqual(sorted[1].name, "B位置")
        XCTAssertEqual(sorted[2].name, "C位置")
    }
    
    func testSortByType() {
        let testLocations = [
            createLocation(name: "位置1", type: .dryStorage),
            createLocation(name: "位置2", type: .refrigerator),
            createLocation(name: "位置3", type: .freezer)
        ]
        mockRepository.locationsToReturn = testLocations
        sut.loadLocations()
        
        sut.sortBy(.type)
        
        let sorted = sut.sortedLocations
        // Verify locations are grouped by type
        XCTAssertEqual(sorted.count, 3, "Should have all locations")
    }
    
    // MARK: - Performance Tests
    
    func testLoadLargeDatasetPerformance() {
        let testLocations = createTestLocations(count: 1000)
        mockRepository.locationsToReturn = testLocations
        
        measure {
            sut.loadLocations()
        }
    }
    
    func testFilterPerformance() {
        let testLocations = createTestLocations(count: 1000)
        mockRepository.locationsToReturn = testLocations
        sut.loadLocations()
        
        measure {
            sut.searchText = "位置500"
            _ = sut.filteredLocations
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestLocations(count: Int) -> [StorageLocation] {
        return (0..<count).map { index in
            createLocation(name: "位置\(index)", type: .refrigerator)
        }
    }
    
    private func createLocation(
        name: String,
        type: StorageLocationType = .refrigerator,
        isCustom: Bool = false
    ) -> StorageLocation {
        return StorageLocation(
            id: UUID(),
            name: name,
            type: type,
            temperature: nil,
            isCustom: isCustom
        )
    }
}

// MARK: - Mock Repository

class MockStorageLocationRepository: StorageLocationRepositoryProtocol {
    var locationsToReturn: [StorageLocation] = []
    var shouldThrowError = false
    var createWasCalled = false
    var updateWasCalled = false
    var deleteWasCalled = false
    var hasIngredientsToReturn = false
    var ingredientCountsToReturn: [UUID: Int] = [:]
    
    func fetchAll() throws -> [StorageLocation] {
        if shouldThrowError {
            throw NSError(domain: "TestError", code: -1, userInfo: nil)
        }
        return locationsToReturn
    }
    
    func fetch(by id: UUID) throws -> StorageLocation? {
        return locationsToReturn.first { $0.id == id }
    }
    
    func search(query: String) throws -> [StorageLocation] {
        return locationsToReturn.filter { $0.name.contains(query) }
    }
    
    func create(_ location: StorageLocation) throws {
        createWasCalled = true
        locationsToReturn.append(location)
    }
    
    func update(_ location: StorageLocation) throws {
        updateWasCalled = true
        if let index = locationsToReturn.firstIndex(where: { $0.id == location.id }) {
            locationsToReturn[index] = location
        }
    }
    
    func delete(_ location: StorageLocation) throws {
        if hasIngredientsToReturn {
            throw NSError(domain: "TestError", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Cannot delete location with ingredients"
            ])
        }
        deleteWasCalled = true
        locationsToReturn.removeAll { $0.id == location.id }
    }
    
    func hasIngredients(_ locationId: UUID) throws -> Bool {
        return hasIngredientsToReturn
    }
    
    func ingredientCount(for locationId: UUID) throws -> Int {
        return ingredientCountsToReturn[locationId] ?? 0
    }
}
