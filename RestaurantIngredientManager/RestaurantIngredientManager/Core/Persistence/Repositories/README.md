# Repositories

This directory contains repository implementations for data persistence layer.

## IngredientRepository

The `IngredientRepository` class provides a clean interface for managing ingredient data persistence using Core Data.

### Features

- **CRUD Operations**: Create, Read, Update, Delete ingredients
- **Search**: Search ingredients by name, category, or supplier
- **Filter**: Filter ingredients by multiple criteria (category, storage location, expiration date, supplier)
- **Special Queries**: 
  - Fetch expiring ingredients (within specified days)
  - Fetch low stock ingredients
- **Error Handling**: Comprehensive error handling with descriptive error messages
- **Logging**: Detailed logging for debugging and monitoring
- **Async/Await**: Modern Swift concurrency support

### Usage

```swift
// Initialize repository
let repository = IngredientRepository()

// Create an ingredient
let ingredient = Ingredient(...)
try await repository.create(ingredient)

// Fetch all ingredients
let ingredients = try await repository.fetchAll()

// Search ingredients
let results = try await repository.search(query: "carrot")

// Filter ingredients
let criteria = FilterCriteria(categories: [.vegetables])
let filtered = try await repository.filter(by: criteria)

// Fetch expiring ingredients (within 3 days)
let expiring = try await repository.fetchExpiring(within: 3)

// Fetch low stock ingredients
let lowStock = try await repository.fetchLowStock()

// Update an ingredient
try await repository.update(updatedIngredient)

// Delete an ingredient
try await repository.delete(ingredient)
```

### Requirements Satisfied

- **1.1**: Create new ingredient records
- **1.2**: Display ingredient information
- **1.3**: Modify existing ingredient records
- **1.4**: Delete ingredient records
- **1.6**: Immediately save changes
- **2.2**: Search ingredients by name, category, or supplier
- **2.3**: Filter by category
- **2.4**: Filter by storage location
- **2.5**: Filter by expiration date range
- **2.6**: Apply multiple filter criteria
- **3.4**: Display ingredients sorted by expiration date
- **4.3**: Display low stock ingredients

### Testing

Unit tests are provided in `IngredientRepositoryTests.swift` covering:
- Create operations with valid and invalid data
- Fetch operations (all, by ID, not found)
- Search operations (by name, category, empty query)
- Filter operations (by category, expiration date range)
- Update operations (existing and non-existent)
- Delete operations (existing and non-existent)
- Expiring ingredients query
- Low stock ingredients query

### Error Handling

The repository uses `RepositoryError` enum for error handling:
- `fetchFailed(Error)`: Failed to fetch data
- `createFailed(Error)`: Failed to create data
- `updateFailed(Error)`: Failed to update data
- `deleteFailed(Error)`: Failed to delete data
- `notFound`: Data not found
- `invalidData`: Invalid data

All errors include localized descriptions for user-friendly error messages.

### Performance Considerations

- Uses background contexts for all operations to avoid blocking the main thread
- Implements proper Core Data concurrency patterns
- Uses fetch limits where appropriate
- Optimized predicates for efficient queries
- Batch operations support through Core Data

### Future Enhancements

- Batch create/update/delete operations
- Pagination support for large datasets
- Caching layer for frequently accessed data
- Real-time updates using Combine publishers

---

## SupplierRepository

The `SupplierRepository` class provides a clean interface for managing supplier data persistence using Core Data.

### Features

- **CRUD Operations**: Create, Read, Update, Delete suppliers
- **Association Queries**: Fetch all ingredients associated with a supplier
- **Delete Constraints**: Prevent deletion of suppliers with associated ingredients
- **Error Handling**: Comprehensive error handling with descriptive error messages
- **Logging**: Detailed logging for debugging and monitoring
- **Async/Await**: Modern Swift concurrency support

### Usage

```swift
// Initialize repository
let repository = SupplierRepository()

// Create a supplier
let supplier = Supplier(name: "Fresh Vegetables Co.", contactPerson: "John Doe", phone: "13800138000")
try await repository.create(supplier)

// Fetch all suppliers
let suppliers = try await repository.fetchAll()

// Fetch supplier by ID
let fetched = try await repository.fetch(by: supplier.id)

// Fetch ingredients for a supplier
let ingredients = try await repository.fetchIngredients(for: supplier)

// Check if supplier can be deleted
let canDelete = try await repository.canDelete(supplier)

// Update a supplier
try await repository.update(updatedSupplier)

// Delete a supplier (only if no associated ingredients)
try await repository.delete(supplier)
```

### Requirements Satisfied

- **12.1**: Create supplier records with name, contact information, and notes
- **12.2**: Assign suppliers to ingredients
- **12.3**: List all suppliers
- **12.4**: Display all ingredients associated with a supplier
- **12.5**: Edit supplier information
- **12.6**: Delete suppliers without associated ingredients

### Testing

Unit tests are provided in `SupplierRepositoryTests.swift` covering:
- Create operations with valid and invalid data
- Fetch operations (all, by ID, not found)
- Update operations (existing and non-existent)
- Delete operations (with and without associated ingredients)
- Association queries (fetch ingredients for supplier)
- Delete constraint validation

---

## StorageLocationRepository

The `StorageLocationRepository` class provides a clean interface for managing storage location data persistence using Core Data.

### Features

- **CRUD Operations**: Create, Read, Update, Delete storage locations
- **Association Queries**: Fetch all ingredients stored in a location
- **Delete Constraints**: Prevent deletion of locations with associated ingredients
- **Error Handling**: Comprehensive error handling with descriptive error messages
- **Logging**: Detailed logging for debugging and monitoring
- **Async/Await**: Modern Swift concurrency support

### Usage

```swift
// Initialize repository
let repository = StorageLocationRepository()

// Create a storage location
let location = StorageLocation(name: "Main Refrigerator", type: .refrigerator, temperature: 4.0)
try await repository.create(location)

// Fetch all storage locations
let locations = try await repository.fetchAll()

// Fetch location by ID
let fetched = try await repository.fetch(by: location.id)

// Fetch ingredients in a location
let ingredients = try await repository.fetchIngredients(for: location)

// Check if location can be deleted
let canDelete = try await repository.canDelete(location)

// Update a storage location
try await repository.update(updatedLocation)

// Delete a storage location (only if no associated ingredients)
try await repository.delete(location)
```

### Requirements Satisfied

- **11.1**: Provide predefined storage location options
- **11.2**: Create custom storage location entries
- **11.3**: Assign storage locations to ingredients
- **11.4**: Display ingredients grouped by storage location
- **11.5**: Edit or delete custom storage locations
- **11.6**: Prompt to reassign ingredients when deleting a location

### Testing

Unit tests are provided in `StorageLocationRepositoryTests.swift` covering:
- Create operations with valid and invalid data (including custom locations)
- Fetch operations (all, by ID, not found)
- Update operations (existing and non-existent)
- Delete operations (with and without associated ingredients)
- Association queries (fetch ingredients for location)
- Delete constraint validation
- Grouping ingredients by storage location

---

## PurchaseRecordRepository

The `PurchaseRecordRepository` class provides a clean interface for managing purchase record data persistence using Core Data.

### Features

- **CRUD Operations**: Create, Read, Update, Delete purchase records
- **Query Operations**: Query by ingredient, supplier, and date range
- **Cost Aggregation**: Calculate total costs, costs by category, and costs by supplier
- **Data Export**: Export purchase data to CSV format
- **Error Handling**: Comprehensive error handling with descriptive error messages
- **Logging**: Detailed logging for debugging and monitoring
- **Async/Await**: Modern Swift concurrency support

### Usage

```swift
// Initialize repository
let repository = PurchaseRecordRepository()

// Create a purchase record
let record = PurchaseRecord(
    ingredientId: ingredient.id,
    supplierId: supplier.id,
    quantity: 10.0,
    unitCost: 5.0,
    purchaseDate: Date(),
    notes: "Weekly purchase"
)
try await repository.create(record)

// Fetch all purchase records
let records = try await repository.fetchAll()

// Query by ingredient
let criteria = PurchaseRecordQueryCriteria(ingredientIds: [ingredient.id])
let ingredientRecords = try await repository.query(by: criteria)

// Query by supplier
let supplierRecords = try await repository.fetchRecords(for: supplier)

// Query by date range
let startDate = Date().addingTimeInterval(-86400 * 30) // 30 days ago
let endDate = Date()
let dateRangeCriteria = PurchaseRecordQueryCriteria(dateRange: startDate...endDate)
let recentRecords = try await repository.query(by: dateRangeCriteria)

// Calculate total cost
let aggregation = try await repository.calculateTotalCost(by: criteria)
print("Total cost: \(aggregation.totalCost)")
print("Average cost: \(aggregation.averageCost)")

// Calculate cost by category
let categorySummaries = try await repository.calculateCostByCategory(dateRange: startDate...endDate)
for summary in categorySummaries {
    print("\(summary.category.rawValue): \(summary.totalCost)")
}

// Calculate cost by supplier
let supplierSummaries = try await repository.calculateCostBySupplier(dateRange: startDate...endDate)
for summary in supplierSummaries {
    print("\(summary.supplierName): \(summary.totalCost)")
}

// Export data to CSV
let csvData = try await repository.exportData(by: criteria)
try csvData.write(to: fileURL)

// Update a purchase record
try await repository.update(updatedRecord)

// Delete a purchase record
try await repository.delete(record)
```

### Requirements Satisfied

- **13.1**: Record purchase entries with ingredient, quantity, cost, supplier, and date
- **13.2**: Display purchase history for each ingredient
- **13.3**: Calculate and display total cost for selected time period per ingredient
- **13.4**: Provide summary view of total spending by category
- **13.5**: Provide summary view of total spending by supplier
- **13.6**: Allow users to export purchase history data

### Data Structures

#### PurchaseRecordQueryCriteria
```swift
struct PurchaseRecordQueryCriteria {
    var ingredientIds: [UUID]?
    var supplierIds: [UUID]?
    var dateRange: ClosedRange<Date>?
}
```

#### CostAggregation
```swift
struct CostAggregation {
    var totalCost: Double
    var recordCount: Int
    var averageCost: Double
}
```

#### CategoryCostSummary
```swift
struct CategoryCostSummary {
    var category: Category
    var totalCost: Double
    var recordCount: Int
}
```

#### SupplierCostSummary
```swift
struct SupplierCostSummary {
    var supplierId: UUID
    var supplierName: String
    var totalCost: Double
    var recordCount: Int
}
```

### Testing

Unit tests are provided in `PurchaseRecordRepositoryTests.swift` covering:
- Create operations with valid and invalid data
- Validation of quantity, cost, and date constraints
- Fetch operations (all, by ID, not found)
- Query operations (by ingredient, supplier, date range, multiple criteria)
- Update operations (existing and non-existent)
- Delete operations (existing and non-existent)
- Cost aggregation (total cost, by category, by supplier)
- Data export to CSV format
- Export with query criteria

### Error Handling

The repository uses `RepositoryError` enum for error handling:
- `fetchFailed(Error)`: Failed to fetch data
- `createFailed(Error)`: Failed to create data
- `updateFailed(Error)`: Failed to update data
- `deleteFailed(Error)`: Failed to delete data
- `notFound`: Data not found
- `invalidData`: Invalid data (e.g., missing ingredient or supplier)

All errors include localized descriptions for user-friendly error messages.

### Performance Considerations

- Uses background contexts for all operations to avoid blocking the main thread
- Implements proper Core Data concurrency patterns
- Efficient aggregation queries using Core Data fetch requests
- Optimized predicates for complex queries
- CSV export handles large datasets efficiently

### Future Enhancements

- Batch import from CSV/Excel files
- Advanced analytics (trends, forecasting)
- PDF export with charts and graphs
- Real-time cost tracking with Combine publishers
- Integration with accounting systems
