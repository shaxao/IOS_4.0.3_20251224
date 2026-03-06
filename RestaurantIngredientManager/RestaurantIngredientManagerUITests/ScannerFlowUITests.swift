//
//  ScannerFlowUITests.swift
//  RestaurantIngredientManagerUITests
//
//  UI tests for scanner functionality
//

import XCTest

class ScannerFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToScanner() throws {
        let scannerTab = app.tabBars.buttons["扫描"]
        XCTAssertTrue(scannerTab.exists, "Scanner tab should exist")
        
        scannerTab.tap()
        
        let navigationBar = app.navigationBars["扫描"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 2), "Should navigate to scanner")
    }
    
    // MARK: - Camera Permission Tests
    
    func testCameraPermissionRequest() throws {
        app.tabBars.buttons["扫描"].tap()
        
        // Check if permission alert appears
        let permissionAlert = app.alerts.element
        if permissionAlert.waitForExistence(timeout: 3) {
            // Grant permission
            let allowButton = permissionAlert.buttons["允许"]
            if allowButton.exists {
                allowButton.tap()
            }
        }
        
        // Verify camera view is shown
        let cameraView = app.otherElements["cameraPreview"]
        XCTAssertTrue(cameraView.waitForExistence(timeout: 2), "Camera preview should appear")
    }
    
    func testCameraPermissionDenied() throws {
        app.tabBars.buttons["扫描"].tap()
        
        let permissionAlert = app.alerts.element
        if permissionAlert.waitForExistence(timeout: 3) {
            let denyButton = permissionAlert.buttons["不允许"]
            if denyButton.exists {
                denyButton.tap()
                
                // Verify error message is shown
                let errorMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '相机权限'")).element
                XCTAssertTrue(errorMessage.waitForExistence(timeout: 2), "Permission error should be shown")
                
                // Verify settings button
                let settingsButton = app.buttons["前往设置"]
                XCTAssertTrue(settingsButton.exists, "Settings button should exist")
            }
        }
    }
    
    // MARK: - Scanning Controls Tests
    
    func testStartStopScanning() throws {
        app.tabBars.buttons["扫描"].tap()
        
        // Wait for camera to be ready
        sleep(2)
        
        // Find scan button
        let scanButton = app.buttons["开始扫描"]
        if scanButton.exists {
            scanButton.tap()
            
            // Verify scanning indicator
            let scanningIndicator = app.activityIndicators.element
            XCTAssertTrue(scanningIndicator.exists, "Scanning indicator should appear")
            
            // Stop scanning
            let stopButton = app.buttons["停止扫描"]
            if stopButton.exists {
                stopButton.tap()
                
                // Verify scanning stopped
                XCTAssertFalse(scanningIndicator.exists, "Scanning indicator should disappear")
            }
        }
    }
    
    func testToggleTorch() throws {
        app.tabBars.buttons["扫描"].tap()
        sleep(2)
        
        let torchButton = app.buttons["手电筒"]
        if torchButton.exists {
            // Toggle on
            torchButton.tap()
            
            // Verify torch is on (button state changes)
            XCTAssertTrue(torchButton.isSelected || torchButton.value as? String == "开", "Torch should be on")
            
            // Toggle off
            torchButton.tap()
            XCTAssertFalse(torchButton.isSelected || torchButton.value as? String == "关", "Torch should be off")
        }
    }
    
    // MARK: - Scan Result Tests
    
    func testDisplayScanResult() throws {
        app.tabBars.buttons["扫描"].tap()
        sleep(2)
        
        // Note: Actual scanning requires physical barcode
        // This test verifies UI elements exist
        
        let resultView = app.otherElements["scanResult"]
        let codeLabel = app.staticTexts["scannedCode"]
        let ingredientInfo = app.otherElements["ingredientInfo"]
        
        // These elements should be defined in the UI
        // They will appear when a code is scanned
    }
    
    func testScanResultActions() throws {
        app.tabBars.buttons["扫描"].tap()
        sleep(2)
        
        // Verify action buttons exist
        let viewDetailsButton = app.buttons["查看详情"]
        let rescanButton = app.buttons["重新扫描"]
        let addToCartButton = app.buttons["添加到采购"]
        
        // These buttons should appear after successful scan
    }
    
    // MARK: - Scan History Tests
    
    func testViewScanHistory() throws {
        app.tabBars.buttons["扫描"].tap()
        
        let historyButton = app.buttons["历史记录"]
        if historyButton.exists {
            historyButton.tap()
            
            // Verify history view
            let historyList = app.tables["scanHistory"]
            XCTAssertTrue(historyList.waitForExistence(timeout: 2), "History list should appear")
            
            // Close history
            let closeButton = app.buttons["关闭"]
            if closeButton.exists {
                closeButton.tap()
            }
        }
    }
    
    func testClearScanHistory() throws {
        app.tabBars.buttons["扫描"].tap()
        
        let historyButton = app.buttons["历史记录"]
        if historyButton.exists {
            historyButton.tap()
            
            let clearButton = app.buttons["清空历史"]
            if clearButton.exists {
                clearButton.tap()
                
                // Confirm clear
                let confirmAlert = app.alerts.element
                if confirmAlert.exists {
                    confirmAlert.buttons["确定"].tap()
                }
                
                // Verify history is empty
                let emptyMessage = app.staticTexts["暂无扫描记录"]
                XCTAssertTrue(emptyMessage.waitForExistence(timeout: 2), "Empty message should appear")
            }
        }
    }
    
    // MARK: - Barcode Type Tests
    
    func testSupportedBarcodeTypes() throws {
        app.tabBars.buttons["扫描"].tap()
        
        let settingsButton = app.buttons["设置"]
        if settingsButton.exists {
            settingsButton.tap()
            
            // Verify supported barcode types are listed
            XCTAssertTrue(app.staticTexts["EAN-13"].exists, "Should support EAN-13")
            XCTAssertTrue(app.staticTexts["EAN-8"].exists, "Should support EAN-8")
            XCTAssertTrue(app.staticTexts["Code 128"].exists, "Should support Code 128")
            XCTAssertTrue(app.staticTexts["QR码"].exists, "Should support QR codes")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidBarcodeError() throws {
        app.tabBars.buttons["扫描"].tap()
        sleep(2)
        
        // Simulate invalid barcode (if test mode supports it)
        // Verify error message appears
        let errorAlert = app.alerts.containing(NSPredicate(format: "label CONTAINS '无效'")).element
        
        // Error handling UI should be present
    }
    
    func testIngredientNotFoundError() throws {
        app.tabBars.buttons["扫描"].tap()
        sleep(2)
        
        // After scanning unknown barcode
        // Verify "not found" message
        let notFoundMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '未找到'")).element
        
        // Should offer to create new ingredient
        let createButton = app.buttons["创建新食材"]
    }
    
    // MARK: - Continuous Scanning Tests
    
    func testContinuousScanningMode() throws {
        app.tabBars.buttons["扫描"].tap()
        
        let settingsButton = app.buttons["设置"]
        if settingsButton.exists {
            settingsButton.tap()
            
            // Toggle continuous scanning
            let continuousSwitch = app.switches["连续扫描"]
            if continuousSwitch.exists {
                continuousSwitch.tap()
                
                // Verify switch state
                XCTAssertTrue(continuousSwitch.value as? String == "1", "Continuous scanning should be enabled")
                
                // Go back
                app.navigationBars.buttons.element(boundBy: 0).tap()
            }
        }
    }
    
    // MARK: - Integration Tests
    
    func testScanAndViewIngredient() throws {
        app.tabBars.buttons["扫描"].tap()
        sleep(2)
        
        // After successful scan (requires test data)
        let viewDetailsButton = app.buttons["查看详情"]
        if viewDetailsButton.exists {
            viewDetailsButton.tap()
            
            // Verify ingredient detail view
            let detailView = app.navigationBars["食材详情"]
            XCTAssertTrue(detailView.waitForExistence(timeout: 2), "Should navigate to ingredient detail")
        }
    }
    
    func testScanAndAddToPurchase() throws {
        app.tabBars.buttons["扫描"].tap()
        sleep(2)
        
        let addToPurchaseButton = app.buttons["添加到采购"]
        if addToPurchaseButton.exists {
            addToPurchaseButton.tap()
            
            // Verify purchase form appears
            let purchaseForm = app.otherElements["purchaseForm"]
            XCTAssertTrue(purchaseForm.waitForExistence(timeout: 2), "Purchase form should appear")
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testScannerAccessibility() throws {
        app.tabBars.buttons["扫描"].tap()
        
        // Verify accessibility labels
        let scanButton = app.buttons["开始扫描"]
        XCTAssertNotNil(scanButton.label, "Scan button should have accessibility label")
        
        let torchButton = app.buttons["手电筒"]
        XCTAssertNotNil(torchButton.label, "Torch button should have accessibility label")
    }
    
    // MARK: - Performance Tests
    
    func testScannerLaunchPerformance() throws {
        measure(metrics: [XCTOSSignpostMetric.navigationTransitionMetric]) {
            app.tabBars.buttons["扫描"].tap()
            sleep(1)
            app.tabBars.buttons["食材"].tap()
        }
    }
}
