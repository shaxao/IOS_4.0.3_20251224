# Core Data Model Documentation

## Overview
This document describes the Core Data model for the Restaurant Ingredient Manager application.

## Model File Location
`RestaurantIngredientManager.xcdatamodeld/RestaurantIngredientManager.xcdatamodel/contents`

## Entities

### 1. IngredientEntity
Represents a food ingredient in the restaurant inventory.

**Attributes:**
- `id` (UUID): Unique identifier
- `name` (String, 1-100 chars): Ingredient name
- `category` (String): Category (vegetables, meat, seafood, etc.)
- `quantity` (Double, default: 0.0): Current quantity
- `unit` (String, 1-20 chars): Unit of measurement
- `expirationDate` (Date): Expiration date
- `barcode` (String, optional): Barcode identifier
- `qrCode` (String, optional): QR code data
- `minimumStockThreshold` (Double, default: 0.0): Low stock threshold
- `notes` (String, optional): Additional notes
- `createdAt` (Date): Creation timestamp
- `updatedAt` (Date): Last update timestamp

**Relationships:**
- `storageLocation` (1:1, required): Link to StorageLocationEntity
- `supplier` (1:1, optional): Link to SupplierEntity
- `purchaseRecords` (1:N, cascade delete): Collection of PurchaseRecordEntity

**Constraints:**
- Unique constraint on `id`

### 2. StorageLocationEntity
Represents a physical storage location in the restaurant.

**Attributes:**
- `id` (UUID): Unique identifier
- `name` (String, 1-100 chars): Location name
- `type` (String): Location type (refrigerator, freezer, dry storage, custom)
- `temperature` (Double, optional): Storage temperature
- `isCustom` (Boolean, default: false): Whether this is a custom location

**Relationships:**
- `ingredients` (1:N): Collection of IngredientEntity stored at this location

**Constraints:**
- Unique constraint on `id`

### 3. SupplierEntity
Represents a supplier that provides ingredients.

**Attributes:**
- `id` (UUID): Unique identifier
- `name` (String, 1-100 chars): Supplier name
- `contactPerson` (String, optional): Contact person name
- `phone` (String, optional): Phone number
- `email` (String, optional): Email address
- `address` (String, optional): Physical address
- `notes` (String, optional): Additional notes

**Relationships:**
- `ingredients` (1:N): Collection of IngredientEntity from this supplier
- `purchaseRecords` (1:N, cascade delete): Collection of PurchaseRecordEntity

**Constraints:**
- Unique constraint on `id`

### 4. PurchaseRecordEntity
Represents a purchase transaction for ingredients.

**Attributes:**
- `id` (UUID): Unique identifier
- `quantity` (Double, min: 0): Quantity purchased
- `unitCost` (Double, default: 0.0): Cost per unit
- `totalCost` (Double, default: 0.0): Total cost (quantity × unitCost)
- `purchaseDate` (Date): Date of purchase
- `notes` (String, optional): Additional notes

**Relationships:**
- `ingredient` (1:1, required): Link to IngredientEntity
- `supplier` (1:1, required): Link to SupplierEntity

**Constraints:**
- Unique constraint on `id`

## Relationship Details

### One-to-One Relationships
1. **IngredientEntity ↔ StorageLocationEntity**
   - Each ingredient is stored in exactly one location
   - Deletion rule: Nullify (deleting location doesn't delete ingredients)

2. **IngredientEntity ↔ SupplierEntity** (optional)
   - Each ingredient may have one supplier
   - Deletion rule: Nullify (deleting supplier doesn't delete ingredients)

### One-to-Many Relationships
1. **StorageLocationEntity → IngredientEntity**
   - One location can contain many ingredients
   - Inverse: `ingredients` ← `storageLocation`

2. **SupplierEntity → IngredientEntity**
   - One supplier can provide many ingredients
   - Inverse: `ingredients` ← `supplier`

3. **IngredientEntity → PurchaseRecordEntity**
   - One ingredient can have many purchase records
   - Deletion rule: Cascade (deleting ingredient deletes its purchase records)
   - Inverse: `purchaseRecords` ← `ingredient`

4. **SupplierEntity → PurchaseRecordEntity**
   - One supplier can have many purchase records
   - Deletion rule: Cascade (deleting supplier deletes its purchase records)
   - Inverse: `purchaseRecords` ← `supplier`

## Validation Rules

### IngredientEntity
- `name`: Non-empty, max 100 characters
- `quantity`: >= 0
- `unit`: Non-empty, max 20 characters
- `minimumStockThreshold`: >= 0

### StorageLocationEntity
- `name`: Non-empty, max 100 characters

### SupplierEntity
- `name`: Non-empty, max 100 characters
- `phone`: Optional, must be valid phone format if provided
- `email`: Optional, must be valid email format if provided

### PurchaseRecordEntity
- `quantity`: > 0
- `unitCost`: >= 0
- `totalCost`: >= 0, must equal quantity × unitCost
- `purchaseDate`: <= current date

## Usage Notes

1. **Adding to Xcode Project**: 
   - The `.xcdatamodeld` directory should be added to the Xcode project
   - Xcode will automatically generate NSManagedObject subclasses

2. **Code Generation**:
   - Set to "Class Definition" for automatic generation
   - Generated classes will be: IngredientEntity, StorageLocationEntity, SupplierEntity, PurchaseRecordEntity

3. **Migration**:
   - This is version 1 of the model
   - Future changes should use Core Data migration

4. **Testing**:
   - Use in-memory store for unit tests
   - See PersistenceController.preview for example

## Requirements Validation

This Core Data model satisfies:
- **Requirement 1.5**: Core Data for local data persistence
- **Requirement 16.1**: Local storage of all data
