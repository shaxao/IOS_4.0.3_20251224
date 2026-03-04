//
//  IngredientListViewModel.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  食材列表视图模型
//

import Foundation
import Combine

/// 食材列表视图模型
@MainActor
class IngredientListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 食材列表
    @Published private(set) var ingredients: [Ingredient] = []
    
    /// 过滤后的食材列表
    @Published private(set) var filteredIngredients: [Ingredient] = []
    
    /// 搜索文本
    @Published var searchText: String = ""
    
    /// 选中的类别筛选
    @Published var selectedCategory: Category?
    
    /// 选中的供应商筛选
    @Published var selectedSupplierID: UUID?
    
    /// 选中的存储位置筛选
    @Published var selectedLocationID: UUID?
    
    /// 是否只显示过期食材
    @Published var showExpiringOnly: Bool = false
    
    /// 是否只显示低库存食材
    @Published var showLowStockOnly: Bool = false
    
    /// 是否正在加载
    @Published private(set) var isLoading: Bool = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 过期食材数量
    @Published private(set) var expiringCount: Int = 0
    
    /// 低库存食材数量
    @Published private(set) var lowStockCount: Int = 0
    
    // MARK: - Private Properties
    
    private let repository: IngredientRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(repository: IngredientRepository = IngredientRepository.shared) {
        self.repository = repository
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// 加载食材列表
    func loadIngredients() async {
        isLoading = true
        errorMessage = nil
        
        do {
            ingredients = try await repository.fetchAll()
            await updateCounts()
            applyFilters()
        } catch {
            errorMessage = "加载食材失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 刷新食材列表
    func refresh() async {
        await loadIngredients()
    }
    
    /// 删除食材
    func deleteIngredient(_ ingredient: Ingredient) async {
        do {
            try await repository.delete(ingredient)
            await loadIngredients()
        } catch {
            errorMessage = "删除食材失败: \(error.localizedDescription)"
        }
    }
    
    /// 批量删除食材
    func deleteIngredients(_ ingredients: [Ingredient]) async {
        for ingredient in ingredients {
            await deleteIngredient(ingredient)
        }
    }
    
    /// 搜索食材
    func search(query: String) async {
        guard !query.isEmpty else {
            await loadIngredients()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            ingredients = try await repository.search(query: query)
            applyFilters()
        } catch {
            errorMessage = "搜索失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 清除所有筛选
    func clearFilters() {
        selectedCategory = nil
        selectedSupplierID = nil
        selectedLocationID = nil
        showExpiringOnly = false
        showLowStockOnly = false
        searchText = ""
    }
    
    // MARK: - Private Methods
    
    /// 设置绑定
    private func setupBindings() {
        // 监听搜索文本变化
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task { @MainActor in
                    if query.isEmpty {
                        await self?.loadIngredients()
                    } else {
                        await self?.search(query: query)
                    }
                }
            }
            .store(in: &cancellables)
        
        // 监听筛选条件变化
        Publishers.CombineLatest4(
            $selectedCategory,
            $selectedSupplierID,
            $selectedLocationID,
            Publishers.CombineLatest($showExpiringOnly, $showLowStockOnly)
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.applyFilters()
        }
        .store(in: &cancellables)
    }
    
    /// 应用筛选
    private func applyFilters() {
        var filtered = ingredients
        
        // 类别筛选
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // 供应商筛选
        if let supplierID = selectedSupplierID {
            filtered = filtered.filter { $0.supplierID == supplierID }
        }
        
        // 存储位置筛选
        if let locationID = selectedLocationID {
            filtered = filtered.filter { $0.storageLocationID == locationID }
        }
        
        // 过期筛选
        if showExpiringOnly {
            let threshold = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
            filtered = filtered.filter { ingredient in
                guard let expiryDate = ingredient.expiryDate else { return false }
                return expiryDate <= threshold
            }
        }
        
        // 低库存筛选
        if showLowStockOnly {
            filtered = filtered.filter { $0.isLowStock() }
        }
        
        filteredIngredients = filtered
    }
    
    /// 更新统计数量
    private func updateCounts() async {
        // 计算过期食材数量
        let threshold = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        do {
            let expiring = try await repository.fetchExpiring(within: 3)
            expiringCount = expiring.count
        } catch {
            expiringCount = 0
        }
        
        // 计算低库存食材数量
        do {
            let lowStock = try await repository.fetchLowStock()
            lowStockCount = lowStock.count
        } catch {
            lowStockCount = 0
        }
    }
}
