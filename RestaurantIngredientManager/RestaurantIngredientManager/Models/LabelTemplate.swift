//
//  LabelTemplate.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//

import Foundation

/// 标签模板模型
struct LabelTemplate: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var width: Double  // 毫米
    var height: Double // 毫米
    var elements: [LabelElement]
    var isDefault: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        width: Double,
        height: Double,
        elements: [LabelElement] = [],
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.width = width
        self.height = height
        self.elements = elements
        self.isDefault = isDefault
    }
    
    /// 标签元素
    struct LabelElement: Codable, Equatable, Identifiable {
        let id: UUID
        var type: ElementType
        var x: Double
        var y: Double
        var width: Double
        var height: Double
        var fontSize: Double?
        var content: String?
        
        init(
            id: UUID = UUID(),
            type: ElementType,
            x: Double,
            y: Double,
            width: Double,
            height: Double,
            fontSize: Double? = nil,
            content: String? = nil
        ) {
            self.id = id
            self.type = type
            self.x = x
            self.y = y
            self.width = width
            self.height = height
            self.fontSize = fontSize
            self.content = content
        }
        
        /// 元素类型
        enum ElementType: String, Codable, CaseIterable {
            case text
            case qrCode
            case barcode
            case line
            case rectangle
            
            var displayName: String {
                switch self {
                case .text: return "文本"
                case .qrCode: return "二维码"
                case .barcode: return "条形码"
                case .line: return "线条"
                case .rectangle: return "矩形"
                }
            }
        }
    }
    
    /// 验证标签模板数据
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyName
        }
        guard name.count <= 100 else {
            throw ValidationError.nameTooLong
        }
        guard width > 0 else {
            throw ValidationError.invalidWidth
        }
        guard height > 0 else {
            throw ValidationError.invalidHeight
        }
        
        // 验证所有元素
        for element in elements {
            try element.validate(templateWidth: width, templateHeight: height)
        }
    }
    
    enum ValidationError: LocalizedError {
        case emptyName
        case nameTooLong
        case invalidWidth
        case invalidHeight
        
        var errorDescription: String? {
            switch self {
            case .emptyName:
                return "模板名称不能为空"
            case .nameTooLong:
                return "模板名称不能超过100个字符"
            case .invalidWidth:
                return "模板宽度必须大于0"
            case .invalidHeight:
                return "模板高度必须大于0"
            }
        }
    }
}

extension LabelTemplate.LabelElement {
    /// 验证元素数据
    func validate(templateWidth: Double, templateHeight: Double) throws {
        guard x >= 0 && x < templateWidth else {
            throw ValidationError.invalidX
        }
        guard y >= 0 && y < templateHeight else {
            throw ValidationError.invalidY
        }
        guard width > 0 && (x + width) <= templateWidth else {
            throw ValidationError.invalidWidth
        }
        guard height > 0 && (y + height) <= templateHeight else {
            throw ValidationError.invalidHeight
        }
        
        // 文本元素需要字体大小
        if type == .text {
            guard let fontSize = fontSize, fontSize > 0 else {
                throw ValidationError.missingFontSize
            }
        }
    }
    
    enum ValidationError: LocalizedError {
        case invalidX
        case invalidY
        case invalidWidth
        case invalidHeight
        case missingFontSize
        
        var errorDescription: String? {
            switch self {
            case .invalidX:
                return "元素X坐标无效"
            case .invalidY:
                return "元素Y坐标无效"
            case .invalidWidth:
                return "元素宽度无效"
            case .invalidHeight:
                return "元素高度无效"
            case .missingFontSize:
                return "文本元素必须指定字体大小"
            }
        }
    }
}
