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
    @Published var thawDuration: DurationValue = DurationValue()
    @Published var preserveDuration: DurationValue = DurationValue()
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
        !name.isEmpty && validationErrors.isEmpty && requiredFieldsSatisfied()
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
            thawDuration = metadata.thawDuration ?? DurationValue()
            preserveDuration = metadata.preserveDuration ?? DurationValue()
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
                ingredient.category = mappedCategoryFromProfile()
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
                    thawDuration: thawDuration,
                    preserveDuration: preserveDuration,
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
                    thawDuration: thawDuration,
                    preserveDuration: preserveDuration,
                    thawTimestamp: timeline.thawTime,
                    useTimestamp: timeline.useTime,
                    expTimestamp: timeline.expTime,
                    fieldValues: dynamicFieldValues
                )
                // 创建新食材
                let ingredient = Ingredient(
                    name: name,
                    category: mappedCategoryFromProfile(),
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
        thawDuration = DurationValue()
        preserveDuration = DurationValue()
        dynamicFieldValues = [:]
        recalculateTimes()
        errorMessage = nil
        validationErrors = []
    }

    func updateDynamicFieldValue(_ value: String, for key: IngredientFieldKey) {
        dynamicFieldValues[key.rawValue] = value
    }

    func recalculateTimes(from thawTime: Date = Date()) {
        let useTime = DurationCalculator.add(thawDuration, to: thawTime)
        let expTime = DurationCalculator.add(preserveDuration, to: useTime)
        calculatedUseTime = useTime
        calculatedExpTime = expTime
        expirationDate = expTime
        dynamicFieldValues[IngredientFieldKey.thawTime.rawValue] = DurationCalculator.formatAsChineseDuration(thawDuration)
        dynamicFieldValues[IngredientFieldKey.preserveTime.rawValue] = DurationCalculator.formatAsChineseDuration(preserveDuration)
        dynamicFieldValues[IngredientFieldKey.useTime.rawValue] = useTime.formatted(date: .numeric, time: .shortened)
        dynamicFieldValues[IngredientFieldKey.expTime.rawValue] = expTime.formatted(date: .numeric, time: .shortened)
    }

    func updateDurationAmount(_ amount: Int, for key: IngredientFieldKey) {
        switch key {
        case .thawTime:
            thawDuration.amount = max(amount, 0)
        case .preserveTime:
            preserveDuration.amount = max(amount, 0)
        default:
            break
        }
        recalculateTimes()
    }

    func updateDurationUnit(_ unit: DurationUnit, for key: IngredientFieldKey) {
        switch key {
        case .thawTime:
            thawDuration.unit = unit
        case .preserveTime:
            preserveDuration.unit = unit
        default:
            break
        }
        recalculateTimes()
    }

    func updateCustomMinutes(_ minutes: Int, for key: IngredientFieldKey) {
        let value = max(minutes, 0)
        switch key {
        case .thawTime:
            thawDuration.customMinutes = value
        case .preserveTime:
            preserveDuration.customMinutes = value
        default:
            break
        }
        recalculateTimes()
    }

    func durationValue(for key: IngredientFieldKey) -> DurationValue {
        switch key {
        case .thawTime:
            return thawDuration
        case .preserveTime:
            return preserveDuration
        default:
            return DurationValue()
        }
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

        Publishers.CombineLatest($thawDuration, $preserveDuration)
            .sink { [weak self] _, _ in
                self?.recalculateTimes()
            }
            .store(in: &cancellables)
    }
}

private extension IngredientDetailViewModel {
    func mappedCategoryFromProfile() -> Category {
        guard let profileName = activeCategoryProfile?.name else {
            return category
        }
        let matched = Category.allCases.first(where: { $0.rawValue == profileName })
        return matched ?? .other
    }

    func requiredFieldsSatisfied() -> Bool {
        guard let profile = activeCategoryProfile else {
            return true
        }
        for field in profile.fields where field.enabled && field.required {
            switch field.key {
            case .name:
                if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return false
                }
            case .thawTime:
                if DurationCalculator.totalMinutes(for: thawDuration) <= 0 {
                    return false
                }
            case .preserveTime:
                if DurationCalculator.totalMinutes(for: preserveDuration) <= 0 {
                    return false
                }
            case .stock, .unit, .useTime, .expTime, .operatorName, .storageCondition:
                let value = dynamicFieldValues[field.key.rawValue] ?? ""
                if field.kind == .text && value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && field.key != .unit {
                    return false
                }
            }
        }
        return true
    }

    func currentTimeline() -> (thawTime: Date, useTime: Date, expTime: Date) {
        let thawTime = Date()
        let useTime = DurationCalculator.add(thawDuration, to: thawTime)
        let expTime = DurationCalculator.add(preserveDuration, to: useTime)
        return (thawTime, useTime, expTime)
    }
}
