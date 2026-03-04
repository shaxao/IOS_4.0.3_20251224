//
//  CoreDataExtensions.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  Extensions for converting between Swift models and Core Data entities
//

import CoreData
import Foundation

// MARK: - Ingredient Extensions

extension Ingredient {
    /// Convert Ingredient struct to IngredientEntity
    func toEntity(context: NSManagedObjectContext) -> IngredientEntity {
        let entity = IngredientEntity(context: context)
        entity.id = self.id
        entity.name = self.name
        entity.category = self.category.rawValue
        entity.quantity = self.quantity
        entity.unit = self.unit
        entity.expirationDate = self.expirationDate
        entity.barcode = self.barcode
        entity.qrCode = self.qrCode
        entity.minimumStockThreshold = self.minimumStockThreshold
        entity.notes = self.notes
        entity.createdAt = self.createdAt
        entity.updatedAt = self.updatedAt
        
        // Set relationships
        entity.storageLocation = self.storageLocation.toEntity(context: context)
        if let supplier = self.supplier {
            entity.supplier = supplier.toEntity(context: context)
        }
        
        return entity
    }
    
    /// Create Ingredient struct from IngredientEntity
    init?(from entity: IngredientEntity) {
        guard let id = entity.id,
              let name = entity.name,
              let categoryString = entity.category,
              let category = Category(rawValue: categoryString),
              let unit = entity.unit,
              let expirationDate = entity.expirationDate,
              let storageLocationEntity = entity.storageLocation,
              let storageLocation = StorageLocation(from: storageLocationEntity),
              let createdAt = entity.createdAt,
              let updatedAt = entity.updatedAt else {
            return nil
        }
        
        let supplier: Supplier?
        if let supplierEntity = entity.supplier {
            supplier = Supplier(from: supplierEntity)
        } else {
            supplier = nil
        }
        
        self.init(
            id: id,
            name: name,
            category: category,
            quantity: entity.quantity,
            unit: unit,
            expirationDate: expirationDate,
            storageLocation: storageLocation,
            supplier: supplier,
            barcode: entity.barcode,
            qrCode: entity.qrCode,
            minimumStockThreshold: entity.minimumStockThreshold,
            notes: entity.notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}


// MARK: - StorageLocation Extensions

extension StorageLocation {
    /// Convert StorageLocation struct to StorageLocationEntity
    func toEntity(context: NSManagedObjectContext) -> StorageLocationEntity {
        let entity = StorageLocationEntity(context: context)
        entity.id = self.id
        entity.name = self.name
        entity.type = self.type.rawValue
        entity.temperature = self.temperature ?? 0
        entity.isCustom = self.isCustom
        return entity
    }
    
    /// Create StorageLocation struct from StorageLocationEntity
    init?(from entity: StorageLocationEntity) {
        guard let id = entity.id,
              let name = entity.name,
              let typeString = entity.type,
              let type = LocationType(rawValue: typeString) else {
            return nil
        }
        
        let temperature = entity.temperature == 0 ? nil : entity.temperature
        
        self.init(
            id: id,
            name: name,
            type: type,
            temperature: temperature,
            isCustom: entity.isCustom
        )
    }
}

// MARK: - Supplier Extensions

extension Supplier {
    /// Convert Supplier struct to SupplierEntity
    func toEntity(context: NSManagedObjectContext) -> SupplierEntity {
        let entity = SupplierEntity(context: context)
        entity.id = self.id
        entity.name = self.name
        entity.contactPerson = self.contactPerson
        entity.phone = self.phone
        entity.email = self.email
        entity.address = self.address
        entity.notes = self.notes
        return entity
    }
    
    /// Create Supplier struct from SupplierEntity
    init?(from entity: SupplierEntity) {
        guard let id = entity.id,
              let name = entity.name else {
            return nil
        }
        
        self.init(
            id: id,
            name: name,
            contactPerson: entity.contactPerson,
            phone: entity.phone,
            email: entity.email,
            address: entity.address,
            notes: entity.notes
        )
    }
}

// MARK: - PurchaseRecord Extensions

extension PurchaseRecord {
    /// Convert PurchaseRecord struct to PurchaseRecordEntity
    func toEntity(context: NSManagedObjectContext, ingredient: IngredientEntity, supplier: SupplierEntity) -> PurchaseRecordEntity {
        let entity = PurchaseRecordEntity(context: context)
        entity.id = self.id
        entity.quantity = self.quantity
        entity.unitCost = self.unitCost
        entity.totalCost = self.totalCost
        entity.purchaseDate = self.purchaseDate
        entity.notes = self.notes
        entity.ingredient = ingredient
        entity.supplier = supplier
        return entity
    }
    
    /// Create PurchaseRecord struct from PurchaseRecordEntity
    init?(from entity: PurchaseRecordEntity) {
        guard let id = entity.id,
              let purchaseDate = entity.purchaseDate,
              let ingredient = entity.ingredient,
              let ingredientId = ingredient.id,
              let supplier = entity.supplier,
              let supplierId = supplier.id else {
            return nil
        }
        
        self.init(
            id: id,
            ingredientId: ingredientId,
            supplierId: supplierId,
            quantity: entity.quantity,
            unitCost: entity.unitCost,
            totalCost: entity.totalCost,
            purchaseDate: purchaseDate,
            notes: entity.notes
        )
    }
}
