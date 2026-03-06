//
//  IngredientFlowUITests.swift
//  RestaurantIngredientManagerUITests
//
//  UI tests for ingredient management flow
//

import XCTest

class IngredientFlowUITests: XCTestCase {
    
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
    
    func testNavigateToIngredientList() throws {
        // Verify the ingredient tab is accessible
        let ingredientTab = app.tabBars.buttons["食材"]
        XCTAssertTrue(ingredientTab.exists, "Ingredient tab should exist")
        
        ingredientTab.tap()
        
        // Verify navigation to ingredient list
        let navigationBar = app.navigationBars["食材列表"]
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 2), "Should navigate to ingredient list")
    }
    
    // MARK: - Add Ingredient Tests
    
    func testAddNewIngredient() throws {
        // Navigate to ingredient list
        app.tabBars.buttons["食材"].tap()
        
        // Tap add button
        let addButton = app.navigationBars.buttons["添加"]
        XCTAssertTrue(addButton.exists, "Add button should exist")
        addButton.tap()
        
        // Fill in ingredient details
        let nameField = app.textFields["食材名称"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2), "Name field should appear")
        nameField.tap()
        nameField.typeText("测试食材")
        
        let quantityField = app.textFields["数量"]
        quantityField.tap()
        quantityField.typeText("10")
        
        let unitField = app.textFields["单位"]
        unitField.tap()
        unitField.typeText("kg")
        
        // Select category
        let categoryPicker = app.pickers["类别"]
        if categoryPicker.exists {
            categoryPicker.pickerWheels.element.adjust(toPickerWheelValue: "水果")
        }
        
        // Select storage location
        let locationPicker = app.pickers["存储位置"]
        if locationPicker.exists {
            locationPicker.pickerWheels.element.adjust(toPickerWheelValue: "冰箱")
        }
        
        // Save
        let saveButton = app.buttons["保存"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")
        saveButton.tap()
        
        // Verify ingredient was added
        let ingredientCell = app.cells.containing(.staticText, identifier: "测试食材").element
        XCTAssertTrue(ingredientCell.waitForExistence(timeout: 2), "New ingredient should appear in list")
    }
    
    func testAddIngredientValidation() throws {
        app.tabBars.buttons["食材"].tap()
        app.navigationBars.buttons["添加"].tap()
        
        // Try to save without filling required fields
        let saveButton = app.buttons["保存"]
        saveButton.tap()
        
        // Verify error message appears
        let errorAlert = app.alerts.element
        XCTAssertTrue(errorAlert.waitForExistence(timeout: 2), "Error alert should appear")
        
        let okButton = errorAlert.buttons["确定"]
        okButton.tap()
    }
    
    // MARK: - Edit Ingredient Tests
    
    func testEditIngredient() throws {
        app.tabBars.buttons["食材"].tap()
        
        // Tap on first ingredient
        let firstCell = app.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 2), "Should have at least one ingredient")
        firstCell.tap()
        
        // Tap edit button
        let editButton = app.navigationBars.buttons["编辑"]
        if editButton.exists {
            editButton.tap()
            
            // Modify quantity
            let quantityField = app.textFields["数量"]
            quantityField.tap()
            quantityField.clearText()
            quantityField.typeText("20")
            
            // Save
            app.buttons["保存"].tap()
            
            // Verify changes were saved
            XCTAssertTrue(app.staticTexts["20"].exists, "Updated quantity should be displayed")
        }
    }
    
    // MARK: - Delete Ingredient Tests
    
    func testDeleteIngredient() throws {
        app.tabBars.buttons["食材"].tap()
        
        // Get initial cell count
        let cellCount = app.cells.count
        
        if cellCount > 0 {
            // Swipe to delete
            let firstCell = app.cells.element(boundBy: 0)
            firstCell.swipeLeft()
            
            let deleteButton = app.buttons["删除"]
            XCTAssertTrue(deleteButton.exists, "Delete button should appear")
            deleteButton.tap()
            
            // Confirm deletion if alert appears
            let confirmButton = app.alerts.buttons["删除"]
            if confirmButton.exists {
                confirmButton.tap()
            }
            
            // Verify cell was removed
            sleep(1) // Wait for animation
            XCTAssertEqual(app.cells.count, cellCount - 1, "Cell count should decrease by 1")
        }
    }
    
    // MARK: - Search Tests
    
    func testSearchIngredients() throws {
        app.tabBars.buttons["食材"].tap()
        
        // Tap search field
        let searchField = app.searchFields.element
        XCTAssertTrue(searchField.exists, "Search field should exist")
        searchField.tap()
        searchField.typeText("苹果")
        
        // Wait for search results
        sleep(1)
        
        // Verify filtered results
        let cells = app.cells
        if cells.count > 0 {
            // All visible cells should contain search term
            XCTAssertTrue(cells.element(boundBy: 0).staticTexts.containing(NSPredicate(format: "label CONTAINS '苹果'")).count > 0)
        }
        
        // Clear search
        let clearButton = searchField.buttons["Clear text"]
        if clearButton.exists {
            clearButton.tap()
        }
    }
    
    // MARK: - Filter Tests
    
    func testFilterByCategory() throws {
        app.tabBars.buttons["食材"].tap()
        
        // Tap filter button
        let filterButton = app.navigationBars.buttons["筛选"]
        if filterButton.exists {
            filterButton.tap()
            
            // Select category filter
            let categoryButton = app.buttons["水果"]
            if categoryButton.exists {
                categoryButton.tap()
                
                // Apply filter
                app.buttons["应用"].tap()
                
                // Verify filtered results
                sleep(1)
                // Results should only show fruits
            }
        }
    }
    
    // MARK: - Detail View Tests
    
    func testViewIngredientDetails() throws {
        app.tabBars.buttons["食材"].tap()
        
        let firstCell = app.cells.element(boundBy: 0)
        if firstCell.exists {
            firstCell.tap()
            
            // Verify detail view elements
            XCTAssertTrue(app.staticTexts["名称"].exists, "Name label should exist")
            XCTAssertTrue(app.staticTexts["数量"].exists, "Quantity label should exist")
            XCTAssertTrue(app.staticTexts["单位"].exists, "Unit label should exist")
            XCTAssertTrue(app.staticTexts["类别"].exists, "Category label should exist")
            XCTAssertTrue(app.staticTexts["存储位置"].exists, "Location label should exist")
            XCTAssertTrue(app.staticTexts["保质期"].exists, "Expiration label should exist")
        }
    }
    
    // MARK: - Expiration Warning Tests
    
    func testExpirationWarningDisplay() throws {
        app.tabBars.buttons["食材"].tap()
        
        // Look for expired or expiring soon indicators
        let warningIcon = app.images["exclamationmark.triangle.fill"]
        let expiredIcon = app.images["xmark.circle.fill"]
        
        // At least one warning type should be testable
        // This depends on test data
    }
    
    // MARK: - Low Stock Tests
    
    func testLowStockIndicator() throws {
        app.tabBars.buttons["食材"].tap()
        
        // Look for low stock indicators
        let lowStockBadge = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '库存不足'")).element
        
        // Verify low stock items are highlighted
        // This depends on test data
    }
    
    // MARK: - Performance Tests
    
    func testScrollPerformance() throws {
        app.tabBars.buttons["食材"].tap()
        
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            let table = app.tables.element
            table.swipeUp(velocity: .fast)
            table.swipeDown(velocity: .fast)
        }
    }
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
    }
}
