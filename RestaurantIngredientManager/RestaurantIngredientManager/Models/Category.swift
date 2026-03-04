//
//  Category.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//

import Foundation

/// 食材类别枚举
enum Category: String, Codable, CaseIterable, Identifiable {
    case vegetables = "蔬菜"
    case meat = "肉类"
    case seafood = "海鲜"
    case dairy = "乳制品"
    case dryGoods = "干货"
    case frozen = "冷冻食品"
    case beverages = "饮料"
    case condiments = "调味品"
    case other = "其他"
    
    var id: String { rawValue }
    
    /// 英文名称
    var englishName: String {
        switch self {
        case .vegetables: return "Vegetables"
        case .meat: return "Meat"
        case .seafood: return "Seafood"
        case .dairy: return "Dairy"
        case .dryGoods: return "Dry Goods"
        case .frozen: return "Frozen"
        case .beverages: return "Beverages"
        case .condiments: return "Condiments"
        case .other: return "Other"
        }
    }
}
