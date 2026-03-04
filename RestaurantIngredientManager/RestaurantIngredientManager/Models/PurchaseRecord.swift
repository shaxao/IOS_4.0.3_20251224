//
//  PurchaseRecord.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//

import Foundation

/// 采购记录模型
struct PurchaseRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var ingredientId: UUID
    var supplierId: UUID
    var quantity: Double
    var unitCost: Double
    var totalCost: Double
    var purchaseDate: Date
    var notes: String?
    
    init(
        id: UUID = UUID(),
        ingredientId: UUID,
        supplierId: UUID,
        quantity: Double,
        unitCost: Double,
        totalCost: Double,
        purchaseDate: Date,
        notes: String? = nil
    ) {
        self.id = id
        self.ingredientId = ingredientId
        self.supplierId = supplierId
        self.quantity = quantity
        self.unitCost = unitCost
        self.totalCost = totalCost
        self.purchaseDate = purchaseDate
        self.notes = notes
    }
    
    /// 便利初始化器，自动计算总成本
    init(
        id: UUID = UUID(),
        ingredientId: UUID,
        supplierId: UUID,
        quantity: Double,
        unitCost: Double,
        purchaseDate: Date,
        notes: String? = nil
    ) {
        self.id = id
        self.ingredientId = ingredientId
        self.supplierId = supplierId
        self.quantity = quantity
        self.unitCost = unitCost
        self.totalCost = quantity * unitCost
        self.purchaseDate = purchaseDate
        self.notes = notes
    }
    
    /// 验证采购记录数据
    func validate() throws {
        guard quantity > 0 else {
            throw ValidationError.invalidQuantity
        }
        guard unitCost >= 0 else {
            throw ValidationError.negativeUnitCost
        }
        guard totalCost >= 0 else {
            throw ValidationError.negativeTotalCost
        }
        
        // 验证总成本是否等于数量乘以单价（允许小的浮点误差）
        let calculatedTotal = quantity * unitCost
        let epsilon = 0.01 // 允许1分钱的误差
        guard abs(totalCost - calculatedTotal) < epsilon else {
            throw ValidationError.totalCostMismatch
        }
        
        guard purchaseDate <= Date() else {
            throw ValidationError.futurePurchaseDate
        }
    }
    
    enum ValidationError: LocalizedError {
        case invalidQuantity
        case negativeUnitCost
        case negativeTotalCost
        case totalCostMismatch
        case futurePurchaseDate
        
        var errorDescription: String? {
            switch self {
            case .invalidQuantity:
                return "采购数量必须大于0"
            case .negativeUnitCost:
                return "单价不能为负数"
            case .negativeTotalCost:
                return "总成本不能为负数"
            case .totalCostMismatch:
                return "总成本必须等于数量乘以单价"
            case .futurePurchaseDate:
                return "采购日期不能晚于当前日期"
            }
        }
    }
}
