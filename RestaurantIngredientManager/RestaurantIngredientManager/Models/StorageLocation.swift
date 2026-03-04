//
//  StorageLocation.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//

import Foundation

/// 存储位置模型
struct StorageLocation: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var type: LocationType
    var temperature: Double?
    var isCustom: Bool
    
    /// 存储位置类型
    enum LocationType: String, Codable, CaseIterable {
        case refrigerator = "冰箱"
        case freezer = "冷冻柜"
        case dryStorage = "干货仓库"
        case custom = "自定义"
        
        var englishName: String {
            switch self {
            case .refrigerator: return "Refrigerator"
            case .freezer: return "Freezer"
            case .dryStorage: return "Dry Storage"
            case .custom: return "Custom"
            }
        }
    }
    
    init(id: UUID = UUID(), name: String, type: LocationType, temperature: Double? = nil, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.type = type
        self.temperature = temperature
        self.isCustom = isCustom
    }
    
    /// 验证存储位置数据
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyName
        }
        guard name.count <= 100 else {
            throw ValidationError.nameTooLong
        }
    }
    
    enum ValidationError: LocalizedError {
        case emptyName
        case nameTooLong
        
        var errorDescription: String? {
            switch self {
            case .emptyName:
                return "存储位置名称不能为空"
            case .nameTooLong:
                return "存储位置名称不能超过100个字符"
            }
        }
    }
}
