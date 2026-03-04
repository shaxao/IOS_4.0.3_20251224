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
    @Published var quantity: Double = 0
    
    /// 单位
    @Published var unit: String = ""
    
    /// 最小库存量
    @Published var minimumStockThreshold: Double = 0
    
    /// 保质期
    @Published var expirationDate: Date?
    
    /// 供应商
    @Published var supplier: Supplier?
    
    /// 存储位置
    @Published var storageLocation: StorageLocation = StorageLocation(name: "默认位置", type: .custom)
    
    /// 条形码
    @Published var barcode: String?
    
    /// 备注
    @Published var notes: String?

    @Published var selectedCategoryProfileID: UUID?
    @Published var thawDurationMinutes: Int = 0
    @Published var preserveDurationMinutes: Int = 0
    @Published private(set) var calculatedUseTime: Date = Date()
    @Published private(set) var calculatedExpTime: Date = Date()
    @Published var dynamicFieldValues: [String: String] = [:]
    
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
    private let categoryStore: IngredientCategoryProfileStore
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// 是否为编辑模式
    var isEditMode: Bool {
        ingredientID != nil
    }
    
    /// 是否可以保存
    var canSave: Bool {
        !name.isEmpty && validationErrors.isEmpty
    }

    var activeCategoryProfile: IngredientCategoryProfile? {
        categoryStore.profile(by: selectedCategoryProfileID)
    }
    
    // MARK: - Initialization
    
    init(
        repository: IngredientRepository = IngredientRepository.shared,
        categoryStore: IngredientCategoryProfileStore = .shared
    ) {
        self.repository = repository
        self.categoryStore = categoryStore
        if let defaultProfile = categoryStore.profiles.first {
            self.selectedCategoryProfileID = defaultProfile.id
        }
        recalculateTimes()
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
        quantity = ingredient.quantity
        unit = ingredient.unit
        minimumStockThreshold = ingredient.minimumStockThreshold
        expirationDate = ingredient.expirationDate
        supplier = ingredient.supplier
        storageLocation = ingredient.storageLocation
        barcode = ingredient.barcode
        notes = ingredient.plainNotes
        if let metadata = ingredient.dynamicMetadata {
            selectedCategoryProfileID = metadata.categoryProfileID
            thawDurationMinutes = metadata.thawMinutes ?? 0
            preserveDurationMinutes = metadata.preserveMinutes ?? 0
            dynamicFieldValues = metadata.fieldValues
            calculatedUseTime = metadata.useTimestamp ?? Date()
            calculatedExpTime = metadata.expTimestamp ?? ingredient.expirationDate
        } else {
            if let profile = categoryStore.profiles.first(where: { $0.name == ingredient.category.rawValue }) {
                selectedCategoryProfileID = profile.id
            }
            dynamicFieldValues = [:]
            recalculateTimes()
        }
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
                ingredient.quantity = quantity
                ingredient.unit = unit
                ingredient.minimumStockThreshold = minimumStockThreshold
                let timeline = currentTimeline()
                ingredient.expirationDate = timeline.expTime
                ingredient.supplier = supplier
                ingredient.storageLocation = storageLocation
                ingredient.barcode = barcode
                let profile = activeCategoryProfile
                let metadata = IngredientDynamicMetadata(
                    categoryProfileID: profile?.id,
                    categoryProfileName: profile?.name,
                    thawMinutes: thawDurationMinutes,
                    preserveMinutes: preserveDurationMinutes,
                    thawTimestamp: timeline.thawTime,
                    useTimestamp: timeline.useTime,
                    expTimestamp: timeline.expTime,
                    fieldValues: dynamicFieldValues
                )
                ingredient = ingredient.applying(plainNotes: notes, metadata: metadata)
                ingredient.updatedAt = Date()
                
                try await repository.update(ingredient)
            } else {
                let timeline = currentTimeline()
                let profile = activeCategoryProfile
                let metadata = IngredientDynamicMetadata(
                    categoryProfileID: profile?.id,
                    categoryProfileName: profile?.name,
                    thawMinutes: thawDurationMinutes,
                    preserveMinutes: preserveDurationMinutes,
                    thawTimestamp: timeline.thawTime,
                    useTimestamp: timeline.useTime,
                    expTimestamp: timeline.expTime,
                    fieldValues: dynamicFieldValues
                )
                // 创建新食材
                let ingredient = Ingredient(
                    name: name,
                    category: category,
                    quantity: quantity,
                    unit: unit,
                    expirationDate: timeline.expTime,
                    storageLocation: storageLocation,
                    supplier: supplier,
                    barcode: barcode,
                    qrCode: nil,
                    minimumStockThreshold: minimumStockThreshold,
                    notes: nil
                ).applying(plainNotes: notes, metadata: metadata)
                
                try await repository.create(ingredient)
                ingredientID = ingredient.id
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
        
        quantity = newQuantity
        
        do {
            guard var ingredient = try await repository.fetch(by: id) else {
                errorMessage = "未找到食材"
                return false
            }
            
            ingredient.quantity = newQuantity
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
        quantity = 0
        unit = ""
        minimumStockThreshold = 0
        expirationDate = nil
        supplier = nil
        storageLocation = StorageLocation(name: "默认位置", type: .custom)
        barcode = nil
        notes = nil
        selectedCategoryProfileID = categoryStore.profiles.first?.id
        thawDurationMinutes = 0
        preserveDurationMinutes = 0
        dynamicFieldValues = [:]
        recalculateTimes()
        errorMessage = nil
        validationErrors = []
    }

    func updateDynamicFieldValue(_ value: String, for key: IngredientFieldKey) {
        dynamicFieldValues[key.rawValue] = value
    }

    func recalculateTimes(from thawTime: Date = Date()) {
        let useTime = Calendar.current.date(byAdding: .minute, value: thawDurationMinutes, to: thawTime) ?? thawTime
        let expTime = Calendar.current.date(byAdding: .minute, value: preserveDurationMinutes, to: useTime) ?? useTime
        calculatedUseTime = useTime
        calculatedExpTime = expTime
        expirationDate = expTime
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
                    if unit.count > 20 {
                        errors.append("单位不能超过20个字符")
                    }
                    return errors
                },
                // 验证数量
                $quantity.map { quantity -> [String] in
                    var errors: [String] = []
                    if quantity < 0 {
                        errors.append("当前数量不能为负数")
                    }
                    return errors
                },
                // 验证最小库存
                $minimumStockThreshold.map { stock -> [String] in
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

        Publishers.CombineLatest($thawDurationMinutes, $preserveDurationMinutes)
            .sink { [weak self] _, _ in
                self?.recalculateTimes()
            }
            .store(in: &cancellables)
    }
}

private extension IngredientDetailViewModel {
    func currentTimeline() -> (thawTime: Date, useTime: Date, expTime: Date) {
        let thawTime = Date()
        let useTime = Calendar.current.date(byAdding: .minute, value: thawDurationMinutes, to: thawTime) ?? thawTime
        let expTime = Calendar.current.date(byAdding: .minute, value: preserveDurationMinutes, to: useTime) ?? useTime
        return (thawTime, useTime, expTime)
    }
}
