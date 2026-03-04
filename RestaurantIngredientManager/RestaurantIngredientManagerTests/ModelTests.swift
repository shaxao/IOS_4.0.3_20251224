//
//  ModelTests.swift
//  RestaurantIngredientManagerTests
//
//  Created on 2024
//

import XCTest
@testable import RestaurantIngredientManager

class ModelTests: XCTestCase {
    
    // MARK: - Category Tests
    
    func testCategoryEnumValues() {
        XCTAssertEqual(Category.vegetables.rawValue, "蔬菜")
        XCTAssertEqual(Category.meat.rawValue, "肉类")
        XCTAssertEqual(Category.seafood.rawValue, "海鲜")
        XCTAssertEqual(Category.dairy.rawValue, "乳制品")
        XCTAssertEqual(Category.dryGoods.rawValue, "干货")
    }
    
    func testCategoryEnglishNames() {
        XCTAssertEqual(Category.vegetables.englishName, "Vegetables")
        XCTAssertEqual(Category.meat.englishName, "Meat")
        XCTAssertEqual(Category.seafood.englishName, "Seafood")
    }
    
    // MARK: - StorageLocation Tests
    
    func testStorageLocationCreation() {
        let location = StorageLocation(
            name: "冰箱A",
            type: .refrigerator,
            temperature: 4.0
        )
        
        XCTAssertEqual(location.name, "冰箱A")
        XCTAssertEqual(location.type, .refrigerator)
        XCTAssertEqual(location.temperature, 4.0)
        XCTAssertFalse(location.isCustom)
    }
    
    func testStorageLocationValidation() throws {
        let validLocation = StorageLocation(name: "冰箱", type: .refrigerator)
        XCTAssertNoThrow(try validLocation.validate())
        
        let emptyNameLocation = StorageLocation(name: "", type: .refrigerator)
        XCTAssertThrowsError(try emptyNameLocation.validate()) { error in
            XCTAssertTrue(error is StorageLocation.ValidationError)
        }
        
        let longNameLocation = StorageLocation(name: String(repeating: "A", count: 101), type: .refrigerator)
        XCTAssertThrowsError(try longNameLocation.validate())
    }
    
    // MARK: - Supplier Tests
    
    func testSupplierCreation() {
        let supplier = Supplier(
            name: "新鲜食材供应商",
            contactPerson: "张三",
            phone: "13800138000",
            email: "supplier@example.com"
        )
        
        XCTAssertEqual(supplier.name, "新鲜食材供应商")
        XCTAssertEqual(supplier.contactPerson, "张三")
        XCTAssertEqual(supplier.phone, "13800138000")
        XCTAssertEqual(supplier.email, "supplier@example.com")
    }
    
    func testSupplierValidation() throws {
        let validSupplier = Supplier(
            name: "供应商",
            phone: "13800138000",
            email: "test@example.com"
        )
        XCTAssertNoThrow(try validSupplier.validate())
        
        let emptyNameSupplier = Supplier(name: "")
        XCTAssertThrowsError(try emptyNameSupplier.validate())
        
        let invalidPhoneSupplier = Supplier(name: "供应商", phone: "123")
        XCTAssertThrowsError(try invalidPhoneSupplier.validate())
        
        let invalidEmailSupplier = Supplier(name: "供应商", email: "invalid-email")
        XCTAssertThrowsError(try invalidEmailSupplier.validate())
    }
    
    // MARK: - Ingredient Tests
    
    func testIngredientCreation() {
        let location = StorageLocation(name: "冰箱", type: .refrigerator)
        let ingredient = Ingredient(
            name: "西红柿",
            category: .vegetables,
            quantity: 10.0,
            unit: "kg",
            expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            storageLocation: location,
            minimumStockThreshold: 2.0
        )
        
        XCTAssertEqual(ingredient.name, "西红柿")
        XCTAssertEqual(ingredient.category, .vegetables)
        XCTAssertEqual(ingredient.quantity, 10.0)
        XCTAssertEqual(ingredient.unit, "kg")
        XCTAssertEqual(ingredient.minimumStockThreshold, 2.0)
    }
    
    func testIngredientValidation() throws {
        let location = StorageLocation(name: "冰箱", type: .refrigerator)
        
        let validIngredient = Ingredient(
            name: "西红柿",
            category: .vegetables,
            quantity: 10.0,
            unit: "kg",
            expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            storageLocation: location
        )
        XCTAssertNoThrow(try validIngredient.validate())
        
        let emptyNameIngredient = Ingredient(
            name: "",
            category: .vegetables,
            quantity: 10.0,
            unit: "kg",
            expirationDate: Date(),
            storageLocation: location
        )
        XCTAssertThrowsError(try emptyNameIngredient.validate())
        
        let negativeQuantityIngredient = Ingredient(
            name: "西红柿",
            category: .vegetables,
            quantity: -5.0,
            unit: "kg",
            expirationDate: Date(),
            storageLocation: location
        )
        XCTAssertThrowsError(try negativeQuantityIngredient.validate())
    }
    
    func testIngredientExpirationStatus() {
        let location = StorageLocation(name: "冰箱", type: .refrigerator)
        
        // 测试即将过期
        let expiringSoonIngredient = Ingredient(
            name: "牛奶",
            category: .dairy,
            quantity: 5.0,
            unit: "L",
            expirationDate: Date().addingTimeInterval(2 * 24 * 60 * 60), // 2天后
            storageLocation: location
        )
        XCTAssertTrue(expiringSoonIngredient.isExpiringSoon(within: 3))
        XCTAssertFalse(expiringSoonIngredient.isExpired)
        
        // 测试已过期
        let expiredIngredient = Ingredient(
            name: "过期牛奶",
            category: .dairy,
            quantity: 5.0,
            unit: "L",
            expirationDate: Date().addingTimeInterval(-1 * 24 * 60 * 60), // 1天前
            storageLocation: location
        )
        XCTAssertTrue(expiredIngredient.isExpired)
        XCTAssertFalse(expiredIngredient.isExpiringSoon(within: 3))
    }
    
    func testIngredientStockStatus() {
        let location = StorageLocation(name: "冰箱", type: .refrigerator)
        
        // 测试库存充足
        let normalStockIngredient = Ingredient(
            name: "西红柿",
            category: .vegetables,
            quantity: 10.0,
            unit: "kg",
            expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            storageLocation: location,
            minimumStockThreshold: 5.0
        )
        XCTAssertFalse(normalStockIngredient.isLowStock)
        XCTAssertFalse(normalStockIngredient.isOutOfStock)
        
        // 测试库存不足
        let lowStockIngredient = Ingredient(
            name: "西红柿",
            category: .vegetables,
            quantity: 3.0,
            unit: "kg",
            expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            storageLocation: location,
            minimumStockThreshold: 5.0
        )
        XCTAssertTrue(lowStockIngredient.isLowStock)
        XCTAssertFalse(lowStockIngredient.isOutOfStock)
        
        // 测试缺货
        let outOfStockIngredient = Ingredient(
            name: "西红柿",
            category: .vegetables,
            quantity: 0.0,
            unit: "kg",
            expirationDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            storageLocation: location,
            minimumStockThreshold: 5.0
        )
        XCTAssertFalse(outOfStockIngredient.isLowStock)
        XCTAssertTrue(outOfStockIngredient.isOutOfStock)
    }
    
    // MARK: - PurchaseRecord Tests
    
    func testPurchaseRecordCreation() {
        let ingredientId = UUID()
        let supplierId = UUID()
        
        let record = PurchaseRecord(
            ingredientId: ingredientId,
            supplierId: supplierId,
            quantity: 10.0,
            unitCost: 5.0,
            purchaseDate: Date()
        )
        
        XCTAssertEqual(record.ingredientId, ingredientId)
        XCTAssertEqual(record.supplierId, supplierId)
        XCTAssertEqual(record.quantity, 10.0)
        XCTAssertEqual(record.unitCost, 5.0)
        XCTAssertEqual(record.totalCost, 50.0)
    }
    
    func testPurchaseRecordValidation() throws {
        let ingredientId = UUID()
        let supplierId = UUID()
        
        let validRecord = PurchaseRecord(
            ingredientId: ingredientId,
            supplierId: supplierId,
            quantity: 10.0,
            unitCost: 5.0,
            purchaseDate: Date()
        )
        XCTAssertNoThrow(try validRecord.validate())
        
        let invalidQuantityRecord = PurchaseRecord(
            ingredientId: ingredientId,
            supplierId: supplierId,
            quantity: 0.0,
            unitCost: 5.0,
            purchaseDate: Date()
        )
        XCTAssertThrowsError(try invalidQuantityRecord.validate())
        
        let negativeCostRecord = PurchaseRecord(
            ingredientId: ingredientId,
            supplierId: supplierId,
            quantity: 10.0,
            unitCost: -5.0,
            purchaseDate: Date()
        )
        XCTAssertThrowsError(try negativeCostRecord.validate())
        
        let futureDateRecord = PurchaseRecord(
            ingredientId: ingredientId,
            supplierId: supplierId,
            quantity: 10.0,
            unitCost: 5.0,
            purchaseDate: Date().addingTimeInterval(24 * 60 * 60)
        )
        XCTAssertThrowsError(try futureDateRecord.validate())
    }
    
    // MARK: - LabelTemplate Tests
    
    func testLabelTemplateCreation() {
        let template = LabelTemplate(
            name: "标准标签",
            width: 50.0,
            height: 30.0
        )
        
        XCTAssertEqual(template.name, "标准标签")
        XCTAssertEqual(template.width, 50.0)
        XCTAssertEqual(template.height, 30.0)
        XCTAssertTrue(template.elements.isEmpty)
        XCTAssertFalse(template.isDefault)
    }
    
    func testLabelTemplateValidation() throws {
        let validTemplate = LabelTemplate(
            name: "标准标签",
            width: 50.0,
            height: 30.0
        )
        XCTAssertNoThrow(try validTemplate.validate())
        
        let emptyNameTemplate = LabelTemplate(
            name: "",
            width: 50.0,
            height: 30.0
        )
        XCTAssertThrowsError(try emptyNameTemplate.validate())
        
        let invalidWidthTemplate = LabelTemplate(
            name: "标签",
            width: 0.0,
            height: 30.0
        )
        XCTAssertThrowsError(try invalidWidthTemplate.validate())
    }
    
    func testLabelElementCreation() {
        let element = LabelTemplate.LabelElement(
            type: .text,
            x: 5.0,
            y: 5.0,
            width: 40.0,
            height: 10.0,
            fontSize: 12.0,
            content: "食材名称"
        )
        
        XCTAssertEqual(element.type, .text)
        XCTAssertEqual(element.x, 5.0)
        XCTAssertEqual(element.y, 5.0)
        XCTAssertEqual(element.fontSize, 12.0)
        XCTAssertEqual(element.content, "食材名称")
    }
    
    func testLabelElementValidation() throws {
        let validElement = LabelTemplate.LabelElement(
            type: .text,
            x: 5.0,
            y: 5.0,
            width: 40.0,
            height: 10.0,
            fontSize: 12.0
        )
        XCTAssertNoThrow(try validElement.validate(templateWidth: 50.0, templateHeight: 30.0))
        
        let outOfBoundsElement = LabelTemplate.LabelElement(
            type: .text,
            x: 45.0,
            y: 5.0,
            width: 10.0,
            height: 10.0,
            fontSize: 12.0
        )
        XCTAssertThrowsError(try outOfBoundsElement.validate(templateWidth: 50.0, templateHeight: 30.0))
        
        let textWithoutFontSize = LabelTemplate.LabelElement(
            type: .text,
            x: 5.0,
            y: 5.0,
            width: 40.0,
            height: 10.0
        )
        XCTAssertThrowsError(try textWithoutFontSize.validate(templateWidth: 50.0, templateHeight: 30.0))
    }
    
    // MARK: - Codable Tests
    
    func testIngredientCodable() throws {
        let location = StorageLocation(name: "冰箱", type: .refrigerator)
        let supplier = Supplier(name: "供应商")
        let ingredient = Ingredient(
            name: "西红柿",
            category: .vegetables,
            quantity: 10.0,
            unit: "kg",
            expirationDate: Date(),
            storageLocation: location,
            supplier: supplier
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(ingredient)
        
        let decoder = JSONDecoder()
        let decodedIngredient = try decoder.decode(Ingredient.self, from: data)
        
        XCTAssertEqual(ingredient.id, decodedIngredient.id)
        XCTAssertEqual(ingredient.name, decodedIngredient.name)
        XCTAssertEqual(ingredient.category, decodedIngredient.category)
        XCTAssertEqual(ingredient.quantity, decodedIngredient.quantity)
    }
    
    func testSupplierCodable() throws {
        let supplier = Supplier(
            name: "供应商",
            contactPerson: "张三",
            phone: "13800138000",
            email: "test@example.com"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(supplier)
        
        let decoder = JSONDecoder()
        let decodedSupplier = try decoder.decode(Supplier.self, from: data)
        
        XCTAssertEqual(supplier.id, decodedSupplier.id)
        XCTAssertEqual(supplier.name, decodedSupplier.name)
        XCTAssertEqual(supplier.contactPerson, decodedSupplier.contactPerson)
    }
}
