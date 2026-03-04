//
//  ErrorHandler.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  全局错误处理
//

import Foundation
import SwiftUI

/// 应用错误类型
enum AppError: LocalizedError {
    case dataLoadFailed(String)
    case dataSaveFailed(String)
    case dataDeleteFailed(String)
    case validationFailed(String)
    case networkError(String)
    case permissionDenied(String)
    case printerError(String)
    case scannerError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .dataLoadFailed(let message):
            return NSLocalizedString("error.loadFailed", comment: "").replacingOccurrences(of: "%@", with: message)
        case .dataSaveFailed(let message):
            return NSLocalizedString("error.saveFailed", comment: "").replacingOccurrences(of: "%@", with: message)
        case .dataDeleteFailed(let message):
            return NSLocalizedString("error.deleteFailed", comment: "").replacingOccurrences(of: "%@", with: message)
        case .validationFailed(let message):
            return message
        case .networkError(let message):
            return message
        case .permissionDenied(let message):
            return message
        case .printerError(let message):
            return NSLocalizedString("error.printFailed", comment: "").replacingOccurrences(of: "%@", with: message)
        case .scannerError(let message):
            return NSLocalizedString("error.scanFailed", comment: "").replacingOccurrences(of: "%@", with: message)
        case .unknown(let message):
            return message
        }
    }
}

/// 错误处理器
@MainActor
class ErrorHandler: ObservableObject {
    /// 共享实例
    static let shared = ErrorHandler()
    
    /// 当前错误
    @Published var currentError: Error?
    
    /// 是否显示错误
    @Published var showError = false
    
    private init() {}
    
    /// 处理错误
    func handle(_ error: Error) {
        currentError = error
        showError = true
        
        // 记录错误日志
        logError(error)
    }
    
    /// 清除错误
    func clearError() {
        currentError = nil
        showError = false
    }
    
    /// 记录错误日志
    private func logError(_ error: Error) {
        print("❌ Error: \(error.localizedDescription)")
        
        // 在生产环境中，这里可以发送到错误追踪服务
        // 例如：Crashlytics, Sentry等
    }
}

/// 错误提示视图修饰符
struct ErrorAlert: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: $errorHandler.showError) {
                Alert(
                    title: Text(NSLocalizedString("common.error", comment: "")),
                    message: Text(errorHandler.currentError?.localizedDescription ?? ""),
                    dismissButton: .default(Text(NSLocalizedString("common.ok", comment: ""))) {
                        errorHandler.clearError()
                    }
                )
            }
    }
}

extension View {
    /// 添加全局错误处理
    func withErrorHandling() -> some View {
        modifier(ErrorAlert(errorHandler: ErrorHandler.shared))
    }
}
