# Core Data Setup Instructions

## Task 2.3: Core Data Model File Created ✓

The Core Data model has been created with the following components:

### Files Created

1. **RestaurantIngredientManager.xcdatamodeld/RestaurantIngredientManager.xcdatamodel/contents**
   - Core Data model definition file
   - Defines 4 entities: IngredientEntity, StorageLocationEntity, SupplierEntity, PurchaseRecordEntity
   - Configures relationships and constraints

2. **CoreDataExtensions.swift**
   - Extension methods to convert between Swift structs and Core Data entities
   - Provides `toEntity()` and `init(from:)` methods for all models

3. **CoreDataModel.md**
   - Complete documentation of the Core Data model
   - Entity descriptions, relationships, and validation rules

### Entities Defined

#### 1. IngredientEntity
- **Attributes**: id, name, category, quantity, unit, expirationDate, barcode, qrCode, minimumStockThreshold, notes, createdAt, updatedAt
- **Relationships**: 
  - storageLocation (1:1 with StorageLocationEntity)
  - supplier (1:1 optional with SupplierEntity)
  - purchaseRecords (1:N with PurchaseRecordEntity, cascade delete)

#### 2. StorageLocationEntity
- **Attributes**: id, name, type, temperature, isCustom
- **Relationships**: 
  - ingredients (1:N with IngredientEntity)

#### 3. SupplierEntity
- **Attributes**: id, name, contactPerson, phone, email, address, notes
- **Relationships**: 
  - ingredients (1:N with IngredientEntity)
  - purchaseRecords (1:N with PurchaseRecordEntity, cascade delete)

#### 4. PurchaseRecordEntity
- **Attributes**: id, quantity, unitCost, totalCost, purchaseDate, notes
- **Relationships**: 
  - ingredient (1:1 with IngredientEntity)
  - supplier (1:1 with SupplierEntity)

### Relationship Configuration

**One-to-One Relationships:**
- IngredientEntity ↔ StorageLocationEntity (required)
- IngredientEntity ↔ SupplierEntity (optional)

**One-to-Many Relationships:**
- StorageLocationEntity → IngredientEntity (nullify on delete)
- SupplierEntity → IngredientEntity (nullify on delete)
- IngredientEntity → PurchaseRecordEntity (cascade delete)
- SupplierEntity → PurchaseRecordEntity (cascade delete)

### Constraints and Defaults

**Attribute Constraints:**
- All `id` fields have uniqueness constraints
- `name` fields: min 1 char, max 100 chars
- `unit`: min 1 char, max 20 chars
- `quantity`: default 0.0
- `minimumStockThreshold`: default 0.0
- `isCustom`: default false

**Validation Rules:**
- Implemented in Swift model structs (see Models/ directory)
- Enforced at application layer before saving to Core Data

### Next Steps in Xcode

To complete the Core Data setup, you need to:

1. **Open the project in Xcode**
   ```
   open RestaurantIngredientManager.xcodeproj
   ```

2. **Add the Core Data model to the project:**
   - Right-click on the "Core/Persistence" group in Xcode
   - Select "Add Files to RestaurantIngredientManager..."
   - Navigate to and select `RestaurantIngredientManager.xcdatamodeld`
   - Ensure "Copy items if needed" is checked
   - Click "Add"

3. **Add CoreDataExtensions.swift to the project:**
   - Right-click on the "Core/Persistence" group
   - Select "Add Files to RestaurantIngredientManager..."
   - Select `CoreDataExtensions.swift`
   - Click "Add"

4. **Verify the model:**
   - Click on `RestaurantIngredientManager.xcdatamodeld` in Xcode
   - You should see the visual editor with 4 entities
   - Verify all attributes and relationships are correct

5. **Configure code generation:**
   - Select each entity in the model editor
   - In the Data Model Inspector (right panel):
     - Set "Codegen" to "Class Definition"
     - This will auto-generate NSManagedObject subclasses

6. **Build the project:**
   ```
   ⌘ + B (Command + B)
   ```
   - This will generate the Core Data entity classes
   - Classes will be: IngredientEntity, StorageLocationEntity, SupplierEntity, PurchaseRecordEntity

### Verification

After adding to Xcode, verify:
- [ ] Model file appears in project navigator
- [ ] No build errors
- [ ] PersistenceController can load the model
- [ ] Entity classes are generated (check in DerivedData)

### Requirements Satisfied

✓ **Requirement 1.5**: Core Data for local data persistence
✓ **Requirement 16.1**: Local storage of all data

### Task Details Completed

- [x] 定义IngredientEntity、StorageLocationEntity、SupplierEntity、PurchaseRecordEntity
- [x] 配置实体关系（一对一、一对多）
- [x] 设置属性约束和默认值

## Testing

Once added to Xcode, you can test the Core Data stack:

```swift
// In a test or preview
let controller = PersistenceController(inMemory: true)
let context = controller.container.viewContext

// Create a test entity
let location = StorageLocationEntity(context: context)
location.id = UUID()
location.name = "Test Refrigerator"
location.type = "refrigerator"
location.isCustom = false

try? context.save()
```

## Troubleshooting

**If the model doesn't load:**
1. Check that the model name in PersistenceController matches: "RestaurantIngredientManager"
2. Verify the .xcdatamodeld directory structure is correct
3. Clean build folder (⌘ + Shift + K) and rebuild

**If entities aren't generated:**
1. Check Codegen setting is "Class Definition"
2. Clean and rebuild
3. Check DerivedData for generated files

**If relationships cause errors:**
1. Verify inverse relationships are set correctly
2. Check deletion rules match the design
3. Ensure all required relationships are set before saving
