//
//  ScannerViewModelTests.swift
//  RestaurantIngredientManagerTests
//
//  Unit tests for ScannerViewModel
//

import XCTest
import Combine
import AVFoundation
@testable import RestaurantIngredientManager

class ScannerViewModelTests: XCTestCase {
    
    var sut: ScannerViewModel!
    var mockScannerService: MockScannerService!
    var mockIngredientRepository: MockIngredientRepository!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockScannerService = MockScannerService()
        mockIngredientRepository = MockIngredientRepository()
        sut = ScannerViewModel(
            scannerService: mockScannerService,
            ingredientRepository: mockIngredientRepository
        )
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockScannerService = nil
        mockIngredientRepository = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(sut, "ViewModel should initialize")
        XCTAssertFalse(sut.isScanning, "Should not be scanning initially")
        XCTAssertNil(sut.scannedCode, "Should have no scanned code")
        XCTAssertNil(sut.foundIngredient, "Should have no found ingredient")
    }
    
    // MARK: - Camera Permission Tests
    
    func testCheckCameraPermission() {
        let expectation = XCTestExpectation(description: "Check camera permission")
        
        sut.$cameraPermissionStatus
            .dropFirst()
            .sink { status in
                XCTAssertNotNil(status, "Should have permission status")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.checkCameraPermission()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRequestCameraPermission() {
        let expectation = XCTestExpectation(description: "Request camera permission")
        
        sut.requestCameraPermission { granted in
            // In test environment, this may not actually request permission
            // Just verify the callback is called
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Scanning Tests
    
    func testStartScanning() {
        let expectation = XCTestExpectation(description: "Start scanning")
        
        sut.$isScanning
            .dropFirst()
            .sink { isScanning in
                XCTAssertTrue(isScanning, "Should be scanning")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.startScanning()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testStopScanning() {
        sut.startScanning()
        sut.stopScanning()
        
        XCTAssertFalse(sut.isScanning, "Should not be scanning")
        XCTAssertTrue(mockScannerService.stopScanningCalled, "Should call stop on service")
    }
    
    func testToggleScanning() {
        XCTAssertFalse(sut.isScanning, "Should start not scanning")
        
        sut.toggleScanning()
        XCTAssertTrue(sut.isScanning, "Should be scanning after toggle")
        
        sut.toggleScanning()
        XCTAssertFalse(sut.isScanning, "Should not be scanning after second toggle")
    }
    
    // MARK: - Code Processing Tests
    
    func testProcessScannedBarcode() {
        let expectation = XCTestExpectation(description: "Process scanned barcode")
        
        let testCode = "1234567890128"
        let testIngredient = createTestIngredient(barcode: testCode)
        mockIngredientRepository.ingredientsToReturn = [testIngredient]
        
        sut.$scannedCode
            .dropFirst()
            .sink { code in
                XCTAssertEqual(code, testCode, "Should set scanned code")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.processScannedCode(testCode, type: .ean13)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testProcessScannedQRCode() {
        let expectation = XCTestExpectation(description: "Process scanned QR code")
        
        let testCode = "https://example.com/ingredient/123"
        let testIngredient = createTestIngredient(qrCode: testCode)
        mockIngredientRepository.ingredientsToReturn = [testIngredient]
        
        sut.$scannedCode
            .dropFirst()
            .sink { code in
                XCTAssertEqual(code, testCode, "Should set scanned code")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.processScannedCode(testCode, type: .qr)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFindIngredientByBarcode() {
        let expectation = XCTestExpectation(description: "Find ingredient by barcode")
        
        let testCode = "1234567890128"
        let testIngredient = createTestIngredient(name: "Found Ingredient", barcode: testCode)
        mockIngredientRepository.ingredientsToReturn = [testIngredient]
        
        sut.$foundIngredient
            .dropFirst()
            .sink { ingredient in
                XCTAssertNotNil(ingredient, "Should find ingredient")
                XCTAssertEqual(ingredient?.name, "Found Ingredient")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.processScannedCode(testCode, type: .ean13)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFindIngredientByQRCode() {
        let expectation = XCTestExpectation(description: "Find ingredient by QR code")
        
        let testCode = "https://example.com/ingredient/123"
        let testIngredient = createTestIngredient(name: "QR Ingredient", qrCode: testCode)
        mockIngredientRepository.ingredientsToReturn = [testIngredient]
        
        sut.$foundIngredient
            .dropFirst()
            .sink { ingredient in
                XCTAssertNotNil(ingredient, "Should find ingredient")
                XCTAssertEqual(ingredient?.name, "QR Ingredient")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.processScannedCode(testCode, type: .qr)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testIngredientNotFound() {
        let expectation = XCTestExpectation(description: "Handle ingredient not found")
        
        mockIngredientRepository.ingredientsToReturn = []
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage, "Should set error message")
                XCTAssertTrue(errorMessage!.contains("未找到"), "Should indicate not found")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.processScannedCode("unknown_code", type: .ean13)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Scan History Tests
    
    func testAddToScanHistory() {
        let code1 = "1234567890128"
        let code2 = "9876543210987"
        
        sut.processScannedCode(code1, type: .ean13)
        sut.processScannedCode(code2, type: .ean13)
        
        XCTAssertEqual(sut.scanHistory.count, 2, "Should have 2 items in history")
        XCTAssertEqual(sut.scanHistory.last?.code, code2, "Last item should be most recent")
    }
    
    func testScanHistoryLimit() {
        // Scan more than the limit (assume limit is 50)
        for i in 0..<60 {
            sut.processScannedCode("code_\(i)", type: .ean13)
        }
        
        XCTAssertLessThanOrEqual(sut.scanHistory.count, 50, "Should limit history size")
    }
    
    func testClearScanHistory() {
        sut.processScannedCode("1234567890128", type: .ean13)
        sut.processScannedCode("9876543210987", type: .ean13)
        
        sut.clearScanHistory()
        
        XCTAssertTrue(sut.scanHistory.isEmpty, "Should clear history")
    }
    
    // MARK: - Reset Tests
    
    func testResetScanner() {
        sut.processScannedCode("1234567890128", type: .ean13)
        sut.startScanning()
        
        sut.reset()
        
        XCTAssertNil(sut.scannedCode, "Should clear scanned code")
        XCTAssertNil(sut.foundIngredient, "Should clear found ingredient")
        XCTAssertFalse(sut.isScanning, "Should stop scanning")
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleScanError() {
        let expectation = XCTestExpectation(description: "Handle scan error")
        
        let error = NSError(domain: "TestError", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Scan failed"
        ])
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage, "Should set error message")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.handleError(error)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Supported Code Types Tests
    
    func testSupportedCodeTypes() {
        let supportedTypes = sut.supportedCodeTypes
        
        XCTAssertTrue(supportedTypes.contains(.ean13), "Should support EAN-13")
        XCTAssertTrue(supportedTypes.contains(.ean8), "Should support EAN-8")
        XCTAssertTrue(supportedTypes.contains(.code128), "Should support Code 128")
        XCTAssertTrue(supportedTypes.contains(.qr), "Should support QR codes")
    }
    
    // MARK: - Continuous Scanning Tests
    
    func testContinuousScanningMode() {
        sut.setContinuousScanning(true)
        
        sut.processScannedCode("1234567890128", type: .ean13)
        
        XCTAssertTrue(sut.isScanning, "Should continue scanning in continuous mode")
    }
    
    func testSingleScanMode() {
        sut.setContinuousScanning(false)
        sut.startScanning()
        
        sut.processScannedCode("1234567890128", type: .ean13)
        
        XCTAssertFalse(sut.isScanning, "Should stop scanning in single scan mode")
    }
    
    // MARK: - Performance Tests
    
    func testScanningPerformance() {
        measure {
            for i in 0..<100 {
                sut.processScannedCode("code_\(i)", type: .ean13)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestIngredient(
        name: String = "Test Ingredient",
        barcode: String? = nil,
        qrCode: String? = nil
    ) -> Ingredient {
        return Ingredient(
            id: UUID(),
            name: name,
            category: .other,
            quantity: 10,
            unit: "kg",
            expirationDate: Date().addingTimeInterval(86400 * 7),
            storageLocation: StorageLocation(
                id: UUID(),
                name: "Test Location",
                type: .refrigerator,
                temperature: nil,
                isCustom: false
            ),
            supplier: nil,
            barcode: barcode,
            qrCode: qrCode,
            minimumStockThreshold: 5,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Scanner Service

class MockScannerService: ScannerServiceProtocol {
    var isScanning = false
    var stopScanningCalled = false
    var lastScannedCode: String?
    
    func startScanning() {
        isScanning = true
    }
    
    func stopScanning() {
        isScanning = false
        stopScanningCalled = true
    }
    
    func processScannedCode(_ code: String, type: AVMetadataObject.ObjectType) {
        lastScannedCode = code
    }
    
    var supportedCodeTypes: [AVMetadataObject.ObjectType] {
        return [.ean13, .ean8, .code128, .qr]
    }
    
    func isValidBarcode(_ code: String, type: AVMetadataObject.ObjectType) -> Bool {
        return !code.isEmpty
    }
    
    func handleError(_ error: Error) {
        isScanning = false
    }
}
