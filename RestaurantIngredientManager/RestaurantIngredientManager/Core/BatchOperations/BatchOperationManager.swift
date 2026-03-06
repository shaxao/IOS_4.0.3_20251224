//
//  BatchOperationManager.swift
//  RestaurantIngredientManager
//
//  批量操作管理器
//

import Foundation
import Combine

/// 批量操作类型
enum BatchOperationType {
    case delete
    case update
    case export
    case updateCategory
    case updateLocation
    case updateSupplier
}

/// 批量操作结果
struct BatchOperationResult {
    let successCount: Int
    let failureCount: Int
    let errors: [Error]
    let duration: TimeInterval
}

/// 批量操作管理器
class BatchOperationManager {
    
    // MARK: - Properties
    
    private let queue = DispatchQueue(label: "com.restaurant.batchoperations", qos: .userInitiated)
    @Published var progress: Double = 0.0
    @Published var isProcessing: Bool = false
    
    // MARK: - Batch Delete
    
    /// 批量删除食材
    func batchDeleteIngredients(
        _ ingredients: [Ingredient],
        repository: IngredientRepositoryProtocol
    ) async throws -> BatchOperationResult {
        let startTime = Date()
        var successCount = 0
        var failureCount = 0
        var errors: [Error] = []
        
        await MainActor.run {
            isProcessing = true
            progress = 0.0
        }
        
        for (index, ingredient) in ingredients.enumerated() {
            do {
                try repository.delete(ingredient)
                successCount += 1
            } catch {
                failureCount += 1
                errors.append(error)
            }
            
            let currentProgress = Double(index + 1) / Double(ingredients.count)
            await MainActor.run {
                progress = currentProgress
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
        
        let duration = Date().timeIntervalSince(startTime)
        return BatchOperationResult(
            successCount: successCount,
            failureCount: failureCount,
            errors: errors,
            duration: duration
        )
    }

    
    // MARK: - Batch Update
    
    /// 批量更新食材类别
    func batchUpdateCategory(
        _ ingredients: [Ingredient],
        newCategory: Category,
        repository: IngredientRepositoryProtocol
    ) async throws -> BatchOperationResult {
        let startTime = Date()
        var successCount = 0
        var failureCount = 0
        var errors: [Error] = []
        
        await MainActor.run {
            isProcessing = true
            progress = 0.0
        }
        
        for (index, var ingredient) in ingredients.enumerated() {
            do {
                ingredient.category = newCategory
                try repository.update(ingredient)
                successCount += 1
            } catch {
                failureCount += 1
                errors.append(error)
            }
            
            let currentProgress = Double(index + 1) / Double(ingredients.count)
            await MainActor.run {
                progress = currentProgress
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
        
        let duration = Date().timeIntervalSince(startTime)
        return BatchOperationResult(
            successCount: successCount,
            failureCount: failureCount,
            errors: errors,
            duration: duration
        )
    }
    
    /// 批量更新存储位置
    func batchUpdateLocation(
        _ ingredients: [Ingredient],
        newLocation: StorageLocation,
        repository: IngredientRepositoryProtocol
    ) async throws -> BatchOperationResult {
        let startTime = Date()
        var successCount = 0
        var failureCount = 0
        var errors: [Error] = []
        
        await MainActor.run {
            isProcessing = true
            progress = 0.0
        }
        
        for (index, var ingredient) in ingredients.enumerated() {
            do {
                ingredient.storageLocation = newLocation
                try repository.update(ingredient)
                successCount += 1
            } catch {
                failureCount += 1
                errors.append(error)
            }
            
            let currentProgress = Double(index + 1) / Double(ingredients.count)
            await MainActor.run {
                progress = currentProgress
            }
        }
        
        await MainActor.run {
            isProcessing = false
        }
        
        let duration = Date().timeIntervalSince(startTime)
        return BatchOperationResult(
            successCount: successCount,
            failureCount: failureCount,
            errors: errors,
            duration: duration
        )
    }
    
    // MARK: - Batch Export
    
    /// 批量导出
    func batchExport(
        _ ingredients: [Ingredient],
        format: ExportFormat,
        exportManager: DataExportManager
    ) async throws -> Data {
        await MainActor.run {
            isProcessing = true
            progress = 0.0
        }
        
        let data = try exportManager.exportIngredients(ingredients, format: format)
        
        await MainActor.run {
            isProcessing = false
            progress = 1.0
        }
        
        return data
    }
    
    // MARK: - Progress Tracking
    
    func resetProgress() {
        progress = 0.0
        isProcessing = false
    }
}
