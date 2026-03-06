//
//  PrinterViewModelTests.swift
//  RestaurantIngredientManagerTests
//
//  Unit tests for PrinterViewModel
//

import XCTest
import Combine
@testable import RestaurantIngredientManager

class PrinterViewModelTests: XCTestCase {
    
    var sut: PrinterViewModel!
    var mockPrinterService: MockPrinterService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockPrinterService = MockPrinterService()
        sut = PrinterViewModel(printerService: mockPrinterService)
        cancellables = []
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockPrinterService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(sut, "ViewModel should initialize")
        XCTAssertTrue(sut.availablePrinters.isEmpty, "Should start with no printers")
        XCTAssertNil(sut.connectedPrinter, "Should have no connected printer")
        XCTAssertFalse(sut.isScanning, "Should not be scanning initially")
    }
    
    // MARK: - Printer Discovery Tests
    
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
        
        XCTAssertFalse(sut.isScanning, "Should not be scanning after stop")
        XCTAssertTrue(mockPrinterService.stopScanningCalled, "Should call stop on service")
    }
    
    func testDiscoverPrinters() {
        let expectation = XCTestExpectation(description: "Discover printers")
        
        let testPrinters = createTestPrinters(count: 3)
        mockPrinterService.printersToReturn = testPrinters
        
        sut.$availablePrinters
            .dropFirst()
            .sink { printers in
                XCTAssertEqual(printers.count, 3, "Should discover 3 printers")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.startScanning()
        mockPrinterService.simulateDiscovery()
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Connection Tests
    
    func testConnectToPrinter() {
        let expectation = XCTestExpectation(description: "Connect to printer")
        
        let printer = createTestPrinter(name: "Test Printer")
        mockPrinterService.connectionSuccess = true
        
        sut.$connectedPrinter
            .dropFirst()
            .sink { connectedPrinter in
                XCTAssertNotNil(connectedPrinter, "Should have connected printer")
                XCTAssertEqual(connectedPrinter?.name, "Test Printer")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.connect(to: printer)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testConnectToPrinterFailure() {
        let expectation = XCTestExpectation(description: "Handle connection failure")
        
        let printer = createTestPrinter(name: "Test Printer")
        mockPrinterService.connectionSuccess = false
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage, "Should set error message")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.connect(to: printer)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testDisconnect() {
        let printer = createTestPrinter(name: "Test Printer")
        mockPrinterService.connectionSuccess = true
        sut.connect(to: printer)
        
        sut.disconnect()
        
        XCTAssertNil(sut.connectedPrinter, "Should have no connected printer")
        XCTAssertTrue(mockPrinterService.disconnectCalled, "Should call disconnect on service")
    }
    
    // MARK: - Printing Tests
    
    func testPrintLabel() {
        let expectation = XCTestExpectation(description: "Print label")
        
        let printer = createTestPrinter(name: "Test Printer")
        mockPrinterService.connectionSuccess = true
        mockPrinterService.printSuccess = true
        sut.connect(to: printer)
        
        let ingredient = createTestIngredient()
        
        sut.$isPrinting
            .dropFirst()
            .sink { isPrinting in
                if !isPrinting {
                    XCTAssertTrue(self.mockPrinterService.printCalled, "Should call print on service")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        sut.printLabel(for: ingredient)
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testPrintLabelWithoutConnection() {
        let expectation = XCTestExpectation(description: "Handle print without connection")
        
        let ingredient = createTestIngredient()
        
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNotNil(errorMessage, "Should set error message")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.printLabel(for: ingredient)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testBatchPrint() {
        let expectation = XCTestExpectation(description: "Batch print")
        
        let printer = createTestPrinter(name: "Test Printer")
        mockPrinterService.connectionSuccess = true
        mockPrinterService.printSuccess = true
        sut.connect(to: printer)
        
        let ingredients = (0..<5).map { _ in createTestIngredient() }
        
        sut.$isPrinting
            .dropFirst()
            .sink { isPrinting in
                if !isPrinting {
                    XCTAssertEqual(self.mockPrinterService.printCallCount, 5, "Should print 5 labels")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        sut.batchPrint(ingredients: ingredients)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    // MARK: - Printer Status Tests
    
    func testPrinterStatusMonitoring() {
        let expectation = XCTestExpectation(description: "Monitor printer status")
        
        let printer = createTestPrinter(name: "Test Printer")
        mockPrinterService.connectionSuccess = true
        sut.connect(to: printer)
        
        sut.$printerStatus
            .dropFirst()
            .sink { status in
                XCTAssertNotNil(status, "Should have printer status")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        mockPrinterService.simulateStatusUpdate(.ready)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testHandlePrinterError() {
        let expectation = XCTestExpectation(description: "Handle printer error")
        
        let printer = createTestPrinter(name: "Test Printer")
        mockPrinterService.connectionSuccess = true
        sut.connect(to: printer)
        
        sut.$printerStatus
            .dropFirst()
            .sink { status in
                if status == .error {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockPrinterService.simulateStatusUpdate(.error)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestPrinters(count: Int) -> [PrinterDevice] {
        return (0..<count).map { index in
            createTestPrinter(name: "Printer \(index)")
        }
    }
    
    private func createTestPrinter(name: String) -> PrinterDevice {
        return PrinterDevice(
            id: UUID().uuidString,
            name: name,
            type: .bluetooth,
            isConnected: false
        )
    }
    
    private func createTestIngredient() -> Ingredient {
        return Ingredient(
            id: UUID(),
            name: "Test Ingredient",
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
            barcode: nil,
            qrCode: nil,
            minimumStockThreshold: 5,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

// MARK: - Mock Printer Service

class MockPrinterService: PrinterServiceProtocol {
    var printersToReturn: [PrinterDevice] = []
    var connectionSuccess = false
    var printSuccess = false
    var stopScanningCalled = false
    var disconnectCalled = false
    var printCalled = false
    var printCallCount = 0
    
    private var discoveryCallback: (([PrinterDevice]) -> Void)?
    private var statusCallback: ((PrinterStatus) -> Void)?
    
    func startScanning(onDiscovery: @escaping ([PrinterDevice]) -> Void) {
        discoveryCallback = onDiscovery
    }
    
    func stopScanning() {
        stopScanningCalled = true
    }
    
    func connect(to printer: PrinterDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        if connectionSuccess {
            completion(.success(()))
        } else {
            completion(.failure(NSError(domain: "TestError", code: -1, userInfo: nil)))
        }
    }
    
    func disconnect() {
        disconnectCalled = true
    }
    
    func print(label: LabelData, completion: @escaping (Result<Void, Error>) -> Void) {
        printCalled = true
        printCallCount += 1
        
        if printSuccess {
            completion(.success(()))
        } else {
            completion(.failure(NSError(domain: "TestError", code: -1, userInfo: nil)))
        }
    }
    
    func monitorStatus(callback: @escaping (PrinterStatus) -> Void) {
        statusCallback = callback
    }
    
    func simulateDiscovery() {
        discoveryCallback?(printersToReturn)
    }
    
    func simulateStatusUpdate(_ status: PrinterStatus) {
        statusCallback?(status)
    }
}
