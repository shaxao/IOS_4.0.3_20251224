//
//  Supplier.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//

import Foundation

/// 供应商模型
struct Supplier: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var contactPerson: String?
    var phone: String?
    var email: String?
    var address: String?
    var notes: String?
    
    init(id: UUID = UUID(), name: String, contactPerson: String? = nil, phone: String? = nil, email: String? = nil, address: String? = nil, notes: String? = nil) {
        self.id = id
        self.name = name
        self.contactPerson = contactPerson
        self.phone = phone
        self.email = email
        self.address = address
        self.notes = notes
    }
    
    /// 验证供应商数据
    func validate() throws {
        guard !name.isEmpty else {
            throw ValidationError.emptyName
        }
        guard name.count <= 100 else {
            throw ValidationError.nameTooLong
        }
        
        if let phone = phone, !phone.isEmpty {
            guard isValidPhone(phone) else {
                throw ValidationError.invalidPhone
            }
        }
        
        if let email = email, !email.isEmpty {
            guard isValidEmail(email) else {
                throw ValidationError.invalidEmail
            }
        }
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        // 简单的电话号码验证：至少包含7个数字
        let digits = phone.filter { $0.isNumber }
        return digits.count >= 7
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    enum ValidationError: LocalizedError {
        case emptyName
        case nameTooLong
        case invalidPhone
        case invalidEmail
        
        var errorDescription: String? {
            switch self {
            case .emptyName:
                return "供应商名称不能为空"
            case .nameTooLong:
                return "供应商名称不能超过100个字符"
            case .invalidPhone:
                return "电话号码格式无效"
            case .invalidEmail:
                return "电子邮件格式无效"
            }
        }
    }
}
