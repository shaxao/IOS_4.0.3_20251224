//
//  IngredientDetailViewModel.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  食材详情视图模型
//

import Foundation
import Combine

/// 食材详情视图模型
@MainActor
class IngredientDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 食材ID（编辑模式）
    @Published var ingredientID: UUID?
    
    /// 食材名称
    @Published var name: String = ""
    
    /// 类别
    @Published var category: Category = .vegetables
    
    /// 当前数量
    @Published var currentQuantity: Double = 0
    
    /// 单位
    @Published var unit: String = ""
    
    /// 最小库存量
    @Published var minimumStock: Double = 0
    
    /// 保质期
    @Published var expiryDate: Date?
    
    /// 供应商ID
    @Published var supplierID: UUID?
    
    /// 存储位置ID
    @Published var storageLocationID: UUID?
    
    /// 条形码
    @Published var barcode: String?
    
    /// 备注
    @Published var notes: String?
    
    /// 是否正在保存
    @Published private(set) var isSaving: Bool = false
    
    /// 是否正在加载
    @Published private(set) var isLoading: Bool = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 验证错误
    @Published var validationErrors: [String] = []
    
    // MARK: - Private Properties
    
    private let repository: IngredientRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// 是否为编辑模式
    var isEditMode: Bool {
        ingredientID != nil
    }
    
    /// 是否可以保存
    var canSave: Bool {
        !name.isEmpty && !unit.isEmpty && validationErrors.isEmpty
    }
    
    // MARK: - Initialization
    
    init(repository: IngredientRepository = IngredientRepository.shared) {
        self.repository = repository
        setupValidation()
    }
    
    /// 使用现有食材初始化（编辑模式）
    convenience init(ingredient: Ingredient, repository: IngredientRepository = IngredientRepository.shared) {
        self.init(repository: repository)
        loadIngredient(ingredient)
    }
    
    // MARK: - Public Methods
    
    /// 加载食材数据
    func loadIngredient(_ ingredient: Ingredient) {
        ingredientID = ingredient.id
        name = ingredient.name
        category = ingredient.category
        currentQuantity = ingredient.currentQuantity
        unit = ingredient.unit
        minimumStock = ingredient.minimumStock
        expiryDate = ingredient.expiryDate
        supplierID = ingredient.supplierID
        storageLocationID = ingredient.storageLocationID
        barcode = ingredient.barcode
        notes = ingredient.notes
    }
    
    /// 通过ID加载食材
    func loadIngredient(id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let ingredient = try await repository.fetch(by: id) {
                loadIngredient(ingredient)
            } else {
                errorMessage = "未找到食材"
            }
        } catch {
            errorMessage = "加载食材失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 保存食材
    func save() async -> Bool {
        guard canSave else {
            errorMessage = "请填写所有必填字段"
            return false
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            if let id = ingredientID {
                // 更新现有食材
                guard var ingredient = try await repository.fetch(by: id) else {
                    errorMessage = "未找到要更新的食材"
                    isSaving = false
                    return false
                }
                
                ingredient.name = name
                ingredient.category = category
                ingredient.currentQuantity = currentQuantity
                ingredient.unit = unit
                ingredient.minimumStock = minimumStock
                ingredient.expiryDate = expiryDate
                ingredient.supplierID = supplierID
                ingredient.storageLocationID = storageLocationID
                ingredient.barcode = barcode
                ingredient.notes = notes
                ingredient.updatedAt = Date()
                
                try await repository.update(ingredient)
            } else {
                // 创建新食材
                let ingredient = Ingredient(
                    name: name,
                    category: category,
                    currentQuantity: currentQuantity,
                    unit: unit,
                    minimumStock: minimumStock,
                    expiryDate: expiryDate,
                    supplierID: supplierID,
                    storageLocationID: storageLocationID,
                    barcode: barcode,
                    notes: notes
                )
                
                let created = try await repository.create(ingredient)
                ingredientID = created.id
            }
            
            isSaving = false
            return true
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
    
    /// 更新数量
    func updateQuantity(_ newQuantity: Double) async -> Bool {
        guard let id = ingredientID else {
            errorMessage = "无法更新数量：食材未保存"
            return false
        }
        
        currentQuantity = newQuantity
        
        do {
            guard var ingredient = try await repository.fetch(by: id) else {
                errorMessage = "未找到食材"
                return false
            }
            
            ingredient.currentQuantity = newQuantity
            ingredient.updatedAt = Date()
            
            try await repository.update(ingredient)
            return true
        } catch {
            errorMessage = "更新数量失败: \(error.localizedDescription)"
            return false
        }
    }
    
    /// 重置表单
    func reset() {
        ingredientID = nil
        name = ""
        category = .vegetables
        currentQuantity = 0
        unit = ""
        minimumStock = 0
        expiryDate = nil
        supplierID = nil
        storageLocationID = nil
        barcode = nil
        notes = nil
        errorMessage = nil
        validationErrors = []
    }
    
    // MARK: - Private Methods
    
    /// 设置验证
    private func setupValidation() {
        // 验证名称
        $name
            .map { name -> [String] in
                var errors: [String] = []
                if name.isEmpty {
                    errors.append("食材名称不能为空")
                } else if name.count > 100 {
                    errors.append("食材名称不能超过100个字符")
                }
                return errors
            }
            .combineLatest(
                // 验证单位
                $unit.map { unit -> [String] in
                    var errors: [String] = []
                    if unit.isEmpty {
                        errors.append("单位不能为空")
                    } else if unit.count > 20 {
                        errors.append("单位不能超过20个字符")
                    }
                    return errors
                },
                // 验证数量
                $currentQuantity.map { quantity -> [String] in
                    var errors: [String] = []
                    if quantity < 0 {
                        errors.append("当前数量不能为负数")
                    }
                    return errors
                },
                // 验证最小库存
                $minimumStock.map { stock -> [String] in
                    var errors: [String] = []
                    if stock < 0 {
                        errors.append("最小库存不能为负数")
                    }
                    return errors
                }
            )
            .map { nameErrors, unitErrors, quantityErrors, stockErrors in
                nameErrors + unitErrors + quantityErrors + stockErrors
            }
            .assign(to: &$validationErrors)
    }
}
