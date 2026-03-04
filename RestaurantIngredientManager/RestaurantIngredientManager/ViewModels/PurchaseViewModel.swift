//
//  PurchaseViewModel.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  采购视图模型
//

import Foundation
import Combine

/// 采购视图模型
@MainActor
class PurchaseViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 采购记录列表
    @Published private(set) var purchaseRecords: [PurchaseRecord] = []
    
    /// 筛选后的采购记录
    @Published private(set) var filteredRecords: [PurchaseRecord] = []
    
    /// 选中的食材ID筛选
    @Published var selectedIngredientID: UUID?
    
    /// 选中的供应商ID筛选
    @Published var selectedSupplierID: UUID?
    
    /// 开始日期筛选
    @Published var startDate: Date?
    
    /// 结束日期筛选
    @Published var endDate: Date?
    
    /// 是否正在加载
    @Published private(set) var isLoading: Bool = false
    
    /// 是否正在保存
    @Published private(set) var isSaving: Bool = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 成功信息
    @Published var successMessage: String?
    
    /// 总成本
    @Published private(set) var totalCost: Double = 0
    
    /// 按类别的成本
    @Published private(set) var costByCategory: [Category: Double] = [:]
    
    /// 按供应商的成本
    @Published private(set) var costBySupplier: [UUID: Double] = [:]
    
    // MARK: - Private Properties
    
    private let repository: PurchaseRecordRepository
    private let ingredientRepository: IngredientRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        repository: PurchaseRecordRepository = PurchaseRecordRepository.shared,
        ingredientRepository: IngredientRepository = IngredientRepository.shared
    ) {
        self.repository = repository
        self.ingredientRepository = ingredientRepository
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    /// 加载采购记录
    func loadPurchaseRecords() async {
        isLoading = true
        errorMessage = nil
        
        do {
            purchaseRecords = try await repository.fetchAll()
            applyFilters()
            await calculateCosts()
        } catch {
            errorMessage = "加载采购记录失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 创建采购记录
    func createPurchaseRecord(
        ingredientID: UUID,
        supplierID: UUID?,
        quantity: Double,
        unitPrice: Double,
        totalCost: Double,
        purchaseDate: Date,
        notes: String?
    ) async -> Bool {
        isSaving = true
        errorMessage = nil
        
        do {
            guard let supplierID = supplierID else {
                errorMessage = "请选择供应商"
                isSaving = false
                return false
            }
            let record = PurchaseRecord(
                ingredientId: ingredientID,
                supplierId: supplierID,
                quantity: quantity,
                unitCost: unitPrice,
                totalCost: totalCost,
                purchaseDate: purchaseDate,
                notes: notes
            )
            
            try await repository.create(record)
            successMessage = "采购记录创建成功"
            await loadPurchaseRecords()
            isSaving = false
            return true
        } catch {
            errorMessage = "创建采购记录失败: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
    
    /// 删除采购记录
    func deletePurchaseRecord(_ record: PurchaseRecord) async -> Bool {
        do {
            try await repository.delete(record)
            successMessage = "采购记录删除成功"
            await loadPurchaseRecords()
            return true
        } catch {
            errorMessage = "删除采购记录失败: \(error.localizedDescription)"
            return false
        }
    }
    
    /// 按食材查询
    func filterByIngredient(_ ingredientID: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let criteria = PurchaseRecordQueryCriteria(ingredientIds: [ingredientID])
            purchaseRecords = try await repository.query(by: criteria)
            applyFilters()
            await calculateCosts()
        } catch {
            errorMessage = "查询失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 按供应商查询
    func filterBySupplier(_ supplierID: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let criteria = PurchaseRecordQueryCriteria(supplierIds: [supplierID])
            purchaseRecords = try await repository.query(by: criteria)
            applyFilters()
            await calculateCosts()
        } catch {
            errorMessage = "查询失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 按日期范围查询
    func filterByDateRange(start: Date, end: Date) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let criteria = PurchaseRecordQueryCriteria(dateRange: start...end)
            purchaseRecords = try await repository.query(by: criteria)
            applyFilters()
            await calculateCosts()
        } catch {
            errorMessage = "查询失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 清除筛选
    func clearFilters() {
        selectedIngredientID = nil
        selectedSupplierID = nil
        startDate = nil
        endDate = nil
    }
    
    /// 导出数据
    func exportData() async -> String? {
        do {
            let criteria = buildCriteria()
            let data = try await repository.exportData(by: criteria)
            return String(data: data, encoding: .utf8)
        } catch {
            errorMessage = "导出失败: \(error.localizedDescription)"
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    /// 设置绑定
    private func setupBindings() {
        // 监听筛选条件变化
        Publishers.CombineLatest4(
            $selectedIngredientID,
            $selectedSupplierID,
            $startDate,
            $endDate
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.applyFilters()
        }
        .store(in: &cancellables)
    }
    
    /// 应用筛选
    private func applyFilters() {
        var filtered = purchaseRecords
        
        // 食材筛选
        if let ingredientID = selectedIngredientID {
            filtered = filtered.filter { $0.ingredientId == ingredientID }
        }
        
        // 供应商筛选
        if let supplierID = selectedSupplierID {
            filtered = filtered.filter { $0.supplierId == supplierID }
        }
        
        // 日期范围筛选
        if let start = startDate {
            filtered = filtered.filter { $0.purchaseDate >= start }
        }
        
        if let end = endDate {
            filtered = filtered.filter { $0.purchaseDate <= end }
        }
        
        filteredRecords = filtered
    }
    
    /// 计算成本
    private func calculateCosts() async {
        let records = filteredRecords
        totalCost = records.reduce(0) { $0 + $1.totalCost }
        
        do {
            let ingredientIds = Set(records.map { $0.ingredientId })
            var ingredientMap: [UUID: Ingredient] = [:]
            
            for id in ingredientIds {
                if let ingredient = try await ingredientRepository.fetch(by: id) {
                    ingredientMap[id] = ingredient
                }
            }
            
            var categoryTotals: [Category: Double] = [:]
            for record in records {
                if let ingredient = ingredientMap[record.ingredientId] {
                    categoryTotals[ingredient.category, default: 0] += record.totalCost
                }
            }
            costByCategory = categoryTotals
            
            var supplierTotals: [UUID: Double] = [:]
            for record in records {
                supplierTotals[record.supplierId, default: 0] += record.totalCost
            }
            costBySupplier = supplierTotals
        } catch {
            errorMessage = "计算成本失败: \(error.localizedDescription)"
        }
    }
    
    private func buildCriteria() -> PurchaseRecordQueryCriteria {
        var criteria = PurchaseRecordQueryCriteria()
        if let ingredientID = selectedIngredientID {
            criteria.ingredientIds = [ingredientID]
        }
        if let supplierID = selectedSupplierID {
            criteria.supplierIds = [supplierID]
        }
        if let start = startDate, let end = endDate {
            criteria.dateRange = start...end
        }
        return criteria
    }
}
