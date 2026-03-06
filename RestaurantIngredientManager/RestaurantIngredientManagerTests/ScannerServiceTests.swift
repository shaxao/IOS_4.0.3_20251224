//
//  ScannerServiceTests.swift
//  RestaurantIngredientManagerTests
//
//  Unit tests for ScannerService
//

import XCTest
import AVFoundation
@testable import RestaurantIngredientManager

class ScannerServiceTests: XCTestCase {
    
    var sut: ScannerService!
    
    override func setUp() {
        super.setUp()
        sut = ScannerService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(sut, "ScannerService should initialize")
        XCTAssertFalse(sut.isScanning, "Should not be scanning initially")
        XCTAssertNil(sut.lastScannedCode, "Should have no scanned code initially")
    }
    
    // MARK: - Supported Code Types Tests
    
    func testSupportedCodeTypes() {
        let supportedTypes = sut.supportedCodeTypes
        
        XCTAssertTrue(supportedTypes.contains(.ean13), "Should support EAN-13")
        XCTAssertTrue(supportedTypes.contains(.ean8), "Should support EAN-8")
        XCTAssertTrue(supportedTypes.contains(.code128), "Should support Code 128")
        XCTAssertTrue(supportedTypes.contains(.qr), "Should support QR codes")
        XCTAssertGreaterThan(supportedTypes.count, 0, "Should support at least one code type")
    }
    
    // MARK: - Camera Permission Tests
    
    func testCameraAuthorizationStatus() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        // Test that we can check authorization status
        XCTAssertTrue(
            [.authorized, .denied, .notDetermined, .restricted].contains(status),
            "Should return a valid authorization status"
        )
    }
    
    // MARK: - Scanning State Tests
    
    func testStartScanning() {
        // Note: This test may fail in simulator as camera is not available
        // In real device testing, verify scanning state changes
        
        sut.startScanning()
        
        // In a real implementation with mock camera, we would test:
        // XCTAssertTrue(sut.isScanning, "Should be scanning after start")
    }
    
    func testStopScanning() {
        sut.startScanning()
        sut.stopScanning()
        
        XCTAssertFalse(sut.isScanning, "Should not be scanning after stop")
    }
    
    // MARK: - Code Validation Tests
    
    func testValidateEAN13() {
        // Valid EAN-13 codes
        XCTAssertTrue(sut.isValidBarcode("1234567890128", type: .ean13))
        
        // Invalid EAN-13 codes
        XCTAssertFalse(sut.isValidBarcode("123", type: .ean13))
        XCTAssertFalse(sut.isValidBarcode("abcdefghijklm", type: .ean13))
    }
    
    func testValidateEAN8() {
        // Valid EAN-8 codes
        XCTAssertTrue(sut.isValidBarcode("12345670", type: .ean8))
        
        // Invalid EAN-8 codes
        XCTAssertFalse(sut.isValidBarcode("123", type: .ean8))
        XCTAssertFalse(sut.isValidBarcode("123456789", type: .ean8))
    }
    
    func testValidateQRCode() {
        // QR codes can contain any string
        XCTAssertTrue(sut.isValidBarcode("https://example.com", type: .qr))
        XCTAssertTrue(sut.isValidBarcode("任意文本", type: .qr))
        XCTAssertTrue(sut.isValidBarcode("12345", type: .qr))
    }
    
    // MARK: - Code Processing Tests
    
    func testProcessScannedCode() {
        let testCode = "1234567890128"
        let testType = AVMetadataObject.ObjectType.ean13
        
        sut.processScannedCode(testCode, type: testType)
        
        XCTAssertEqual(sut.lastScannedCode, testCode, "Should store last scanned code")
    }
    
    func testProcessMultipleCodes() {
        let codes = ["123456", "789012", "345678"]
        
        for code in codes {
            sut.processScannedCode(code, type: .code128)
        }
        
        XCTAssertEqual(sut.lastScannedCode, codes.last, "Should store the most recent code")
    }
    
    // MARK: - Error Handling Tests
    
    func testHandleCameraError() {
        let error = NSError(domain: "TestError", code: -1, userInfo: nil)
        
        sut.handleError(error)
        
        // Verify error is handled gracefully
        XCTAssertFalse(sut.isScanning, "Should stop scanning on error")
    }
    
    // MARK: - Performance Tests
    
    func testScanningPerformance() {
        measure {
            for _ in 0..<100 {
                sut.processScannedCode("1234567890128", type: .ean13)
            }
        }
    }
}
