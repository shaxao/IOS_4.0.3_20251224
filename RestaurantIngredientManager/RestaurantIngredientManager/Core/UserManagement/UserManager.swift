//
//  UserManager.swift
//  RestaurantIngredientManager
//
//  用户管理系统
//

import Foundation
import Combine
import CryptoKit

/// 用户角色
enum UserRole: String, Codable {
    case admin = "管理员"
    case manager = "经理"
    case staff = "员工"
    case viewer = "查看者"
    
    var permissions: [Permission] {
        switch self {
        case .admin:
            return Permission.allCases
        case .manager:
            return [.viewIngredients, .editIngredients, .viewPurchases, 
                   .createPurchases, .exportData, .viewReports, .manageSuppliers]
        case .staff:
            return [.viewIngredients, .editIngredients, .viewPurchases, .createPurchases]
        case .viewer:
            return [.viewIngredients, .viewPurchases, .viewReports]
        }
    }
}

/// 权限类型
enum Permission: String, Codable, CaseIterable {
    case viewIngredients = "查看食材"
    case editIngredients = "编辑食材"
    case deleteIngredients = "删除食材"
    case viewPurchases = "查看采购"
    case createPurchases = "创建采购"
    case exportData = "导出数据"
    case manageUsers = "管理用户"
    case viewReports = "查看报表"
    case manageSuppliers = "管理供应商"
    case manageLocations = "管理存储位置"
    case systemSettings = "系统设置"
}

/// 用户模型
struct User: Identifiable, Codable {
    let id: UUID
    var username: String
    var email: String
    var role: UserRole
    var customPermissions: [Permission]
    var isActive: Bool
    var createdAt: Date
    var lastLoginAt: Date?
    var profileImageURL: String?
    
    var allPermissions: [Permission] {
        return Array(Set(role.permissions + customPermissions))
    }
    
    func hasPermission(_ permission: Permission) -> Bool {
        return allPermissions.contains(permission)
    }
}

/// 用户管理器
class UserManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var users: [User] = []
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let keychainService = KeychainService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Keys
    
    private enum Keys {
        static let currentUserId = "currentUserId"
        static let rememberMe = "rememberMe"
    }
    
    // MARK: - Initialization
    
    init() {
        loadCurrentUser()
        setupObservers()
    }
    
    // MARK: - Authentication
    
    /// 用户登录
    func login(username: String, password: String) async throws -> User {
        // 验证用户名和密码
        guard let user = try await authenticateUser(username: username, password: password) else {
            throw AuthError.invalidCredentials
        }
        
        // 检查用户是否激活
        guard user.isActive else {
            throw AuthError.userInactive
        }
        
        // 更新最后登录时间
        var updatedUser = user
        updatedUser.lastLoginAt = Date()
        
        // 保存当前用户
        await MainActor.run {
            self.currentUser = updatedUser
            self.isAuthenticated = true
        }
        
        // 保存到UserDefaults
        userDefaults.set(user.id.uuidString, forKey: Keys.currentUserId)
        
        // 记录登录日志
        logUserAction(.login, user: user)
        
        return updatedUser
    }
    
    /// 用户登出
    func logout() {
        if let user = currentUser {
            logUserAction(.logout, user: user)
        }
        
        currentUser = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: Keys.currentUserId)
    }
    
    /// 验证用户
    private func authenticateUser(username: String, password: String) async throws -> User? {
        // 实际实现中应该从数据库或服务器验证
        // 这里使用模拟数据
        
        let hashedPassword = hashPassword(password)
        
        // 从存储中查找用户
        // 示例：返回模拟用户
        if username == "admin" && hashedPassword == hashPassword("admin123") {
            return User(
                id: UUID(),
                username: "admin",
                email: "admin@example.com",
                role: .admin,
                customPermissions: [],
                isActive: true,
                createdAt: Date(),
                lastLoginAt: nil
            )
        }
        
        return nil
    }
    
    // MARK: - User Management
    
    /// 创建新用户
    func createUser(
        username: String,
        email: String,
        password: String,
        role: UserRole
    ) throws -> User {
        // 检查权限
        guard currentUser?.hasPermission(.manageUsers) == true else {
            throw AuthError.insufficientPermissions
        }
        
        // 验证用户名唯一性
        guard !users.contains(where: { $0.username == username }) else {
            throw AuthError.usernameExists
        }
        
        // 创建用户
        let user = User(
            id: UUID(),
            username: username,
            email: email,
            role: role,
            customPermissions: [],
            isActive: true,
            createdAt: Date(),
            lastLoginAt: nil
        )
        
        // 保存密码到Keychain
        try keychainService.savePassword(password, for: username)
        
        // 添加到用户列表
        users.append(user)
        
        // 记录操作日志
        logUserAction(.createUser, user: user)
        
        return user
    }
    
    /// 更新用户
    func updateUser(_ user: User) throws {
        guard currentUser?.hasPermission(.manageUsers) == true else {
            throw AuthError.insufficientPermissions
        }
        
        guard let index = users.firstIndex(where: { $0.id == user.id }) else {
            throw AuthError.userNotFound
        }
        
        users[index] = user
        
        logUserAction(.updateUser, user: user)
    }
    
    /// 删除用户
    func deleteUser(_ user: User) throws {
        guard currentUser?.hasPermission(.manageUsers) == true else {
            throw AuthError.insufficientPermissions
        }
        
        // 不能删除自己
        guard user.id != currentUser?.id else {
            throw AuthError.cannotDeleteSelf
        }
        
        users.removeAll { $0.id == user.id }
        
        logUserAction(.deleteUser, user: user)
    }
    
    /// 修改密码
    func changePassword(oldPassword: String, newPassword: String) throws {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }
        
        // 验证旧密码
        let oldHash = hashPassword(oldPassword)
        guard let storedHash = try? keychainService.getPassword(for: user.username),
              oldHash == hashPassword(storedHash) else {
            throw AuthError.invalidCredentials
        }
        
        // 保存新密码
        try keychainService.savePassword(newPassword, for: user.username)
        
        logUserAction(.changePassword, user: user)
    }
    
    // MARK: - Permission Check
    
    /// 检查当前用户是否有权限
    func checkPermission(_ permission: Permission) -> Bool {
        return currentUser?.hasPermission(permission) ?? false
    }
    
    /// 要求权限（如果没有则抛出错误）
    func requirePermission(_ permission: Permission) throws {
        guard checkPermission(permission) else {
            throw AuthError.insufficientPermissions
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentUser() {
        guard let userIdString = userDefaults.string(forKey: Keys.currentUserId),
              let userId = UUID(uuidString: userIdString) else {
            return
        }
        
        // 从存储中加载用户
        // 实际实现中应该从数据库加载
        // currentUser = loadUserFromStorage(userId)
    }
    
    private func setupObservers() {
        // 监听应用进入后台
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.saveCurrentState()
            }
            .store(in: &cancellables)
    }
    
    private func saveCurrentState() {
        // 保存当前状态
    }
    
    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Logging
    
    private func logUserAction(_ action: UserAction, user: User) {
        let log = UserLog(
            action: action,
            userId: user.id,
            username: user.username,
            timestamp: Date()
        )
        
        // 保存日志到数据库
        print("📝 用户操作日志: \(log)")
    }
}

// MARK: - Supporting Types

enum UserAction: String {
    case login = "登录"
    case logout = "登出"
    case createUser = "创建用户"
    case updateUser = "更新用户"
    case deleteUser = "删除用户"
    case changePassword = "修改密码"
}

struct UserLog {
    let action: UserAction
    let userId: UUID
    let username: String
    let timestamp: Date
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case userInactive
    case insufficientPermissions
    case usernameExists
    case userNotFound
    case cannotDeleteSelf
    case notAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "用户名或密码错误"
        case .userInactive:
            return "用户已被停用"
        case .insufficientPermissions:
            return "权限不足"
        case .usernameExists:
            return "用户名已存在"
        case .userNotFound:
            return "用户不存在"
        case .cannotDeleteSelf:
            return "不能删除自己"
        case .notAuthenticated:
            return "未登录"
        }
    }
}

// MARK: - Keychain Service

class KeychainService {
    func savePassword(_ password: String, for username: String) throws {
        // 实现Keychain保存
    }
    
    func getPassword(for username: String) throws -> String {
        // 实现Keychain读取
        return ""
    }
    
    func deletePassword(for username: String) throws {
        // 实现Keychain删除
    }
}
