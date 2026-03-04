//
//  SupplierViewModel.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  供应商视图模型
//

import Foundation
import Combine

/// 供应商视图模型
@MainActor
class SupplierViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 供应商列表
    @Published private(set) var suppliers: [Supplier] = []
    
    /// 是否正在加载
    @Published private(set) var isLoading: Bool = false
    
    /// 是否正在保存
    @Published private(set) var isSaving: Bool = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 成功信息
    @Published var successMessage: String?
    
    // MARK: - Private Properties
    
    private let repository: SupplierRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(repository: SupplierRepository = SupplierRepository.shared) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    
    /// 加载供应商列表
    func loadSuppliers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            suppliers = try await repository.fetchAll()
        } catch {
            errorMessage = "加载供应商失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 创建供应商
    func createSupplier(name: String, contactPerson: String?, phone: String?, email: String?, address: String?, notes: String?) async -> Bool {
        guard !name.isEmpty else {
            errorMessage = "供应商名称不能为空"
            return false
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            let supplier = Supplier(
                name: name,
                contactPerson: contactPerson,
                phone: phone,
                email: email,
                address: address,
                notes: notes
            )
            
            _ = try await repository.create(supplier)
            successMessage = "供应商创建成功"
            await loadSuppliers()
            isSaving = false
            return true
        } catch {
            errorMessage = "创建供应商失败: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
    
    /// 更新供应商
    func updateSupplier(_ supplier: Supplier) async -> Bool {
        isSaving = true
        errorMessage = nil
        
        do {
            try await repository.update(supplier)
            successMessage = "供应商更新成功"
            await loadSuppliers()
            isSaving = false
            return true
        } catch {
            errorMessage = "更新供应商失败: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
    
    /// 删除供应商
    func deleteSupplier(_ supplier: Supplier) async -> Bool {
        // 检查是否可以删除
        let canDelete = await checkCanDelete(supplier)
        if !canDelete {
            errorMessage = "该供应商有关联的食材，无法删除"
            return false
        }
        
        do {
            try await repository.delete(supplier)
            successMessage = "供应商删除成功"
            await loadSuppliers()
            return true
        } catch {
            errorMessage = "删除供应商失败: \(error.localizedDescription)"
            return false
        }
    }
    
    /// 检查是否可以删除
    func checkCanDelete(_ supplier: Supplier) async -> Bool {
        do {
            return try await repository.canDelete(supplier)
        } catch {
            return false
        }
    }
    
    /// 获取供应商的食材数量
    func getIngredientCount(for supplier: Supplier) async -> Int {
        do {
            let ingredients = try await repository.fetchIngredients(for: supplier)
            return ingredients.count
        } catch {
            return 0
        }
    }
}
