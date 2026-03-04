//
//  Ingredient.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//

import Foundation

/// 食材模型
struct Ingredient: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: Category
    var quantity: Double
    var unit: String
    var expirationDate: Date
    var storageLocation: StorageLocation
    var supplier: Supplier?
    var barcode: String?
    var qrCode: String?
    var minimumStockThreshold: Double
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        category: Category,
        quantity: Double,
        unit: String,
        expirationDate: Date,
        storageLocation: StorageLocation,
        supplier: Supplier? = nil,
        barcode: String? = nil,
        qrCode: String? = nil,
        minimumStockThreshold: Double = 0,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
        self.unit = unit
        self.expirationDate = expirationDate
        self.storageLocation = storageLocation
        self.supplier = supplier
        self.barcode = barcode
        self.qrCode = qrCode
        self.minimumStockThreshold = minimumStockThreshold
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// 验证食材数据
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyName
        }
        guard name.count <= 100 else {
            throw ValidationError.nameTooLong
        }
        guard quantity >= 0 else {
            throw ValidationError.negativeQuantity
        }
        if !unit.isEmpty && unit.count > 20 {
            throw ValidationError.unitTooLong
        }
        guard minimumStockThreshold >= 0 else {
            throw ValidationError.negativeThreshold
        }
        
        // 验证存储位置
        try storageLocation.validate()
        
        // 验证供应商（如果存在）
        if let supplier = supplier {
            try supplier.validate()
        }
    }
    
    /// 检查是否即将过期（在指定天数内）
    func isExpiringSoon(within days: Int) -> Bool {
        let calendar = Calendar.current
        guard let thresholdDate = calendar.date(byAdding: .day, value: days, to: Date()) else {
            return false
        }
        return expirationDate <= thresholdDate && expirationDate > Date()
    }
    
    /// 检查是否已过期
    var isExpired: Bool {
        return expirationDate < Date()
    }
    
    /// 检查是否库存不足
    var isLowStock: Bool {
        return quantity < minimumStockThreshold && quantity > 0
    }
    
    /// 检查是否缺货
    var isOutOfStock: Bool {
        return quantity == 0
    }
    
    enum ValidationError: LocalizedError {
        case emptyName
        case nameTooLong
        case negativeQuantity
        case unitTooLong
        case negativeThreshold
        
        var errorDescription: String? {
            switch self {
            case .emptyName:
                return "食材名称不能为空"
            case .nameTooLong:
                return "食材名称不能超过100个字符"
            case .negativeQuantity:
                return "数量不能为负数"
            case .unitTooLong:
                return "单位不能超过20个字符"
            case .negativeThreshold:
                return "最低库存阈值不能为负数"
            }
        }
    }
}

extension Ingredient {
    var notesPayload: IngredientNotesPayload {
        IngredientNotesCodec.decode(notes)
    }

    var plainNotes: String? {
        notesPayload.plainNotes
    }

    var dynamicMetadata: IngredientDynamicMetadata? {
        notesPayload.metadata
    }

    func applying(plainNotes: String?, metadata: IngredientDynamicMetadata?) -> Ingredient {
        var updated = self
        updated.notes = IngredientNotesCodec.encode(plainNotes: plainNotes, metadata: metadata)
        return updated
    }
}
