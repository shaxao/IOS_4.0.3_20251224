//
//  StorageLocationViewModel.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  存储位置视图模型
//

import Foundation
import Combine

/// 存储位置视图模型
@MainActor
class StorageLocationViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 存储位置列表
    @Published private(set) var locations: [StorageLocation] = []
    
    /// 按区域分组的位置
    @Published private(set) var locationsByArea: [String: [StorageLocation]] = [:]
    
    /// 是否正在加载
    @Published private(set) var isLoading: Bool = false
    
    /// 是否正在保存
    @Published private(set) var isSaving: Bool = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 成功信息
    @Published var successMessage: String?
    
    // MARK: - Private Properties
    
    private let repository: StorageLocationRepository
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(repository: StorageLocationRepository = StorageLocationRepository.shared) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    
    /// 加载存储位置列表
    func loadLocations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            locations = try await repository.fetchAll()
            groupLocationsByArea()
        } catch {
            errorMessage = "加载存储位置失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 创建存储位置
    func createLocation(name: String, area: String, temperature: Double?, humidity: Double?, notes: String?) async -> Bool {
        guard !name.isEmpty else {
            errorMessage = "存储位置名称不能为空"
            return false
        }
        
        guard !area.isEmpty else {
            errorMessage = "区域不能为空"
            return false
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            let location = StorageLocation(
                name: name,
                area: area,
                temperature: temperature,
                humidity: humidity,
                notes: notes
            )
            
            _ = try await repository.create(location)
            successMessage = "存储位置创建成功"
            await loadLocations()
            isSaving = false
            return true
        } catch {
            errorMessage = "创建存储位置失败: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
    
    /// 更新存储位置
    func updateLocation(_ location: StorageLocation) async -> Bool {
        isSaving = true
        errorMessage = nil
        
        do {
            try await repository.update(location)
            successMessage = "存储位置更新成功"
            await loadLocations()
            isSaving = false
            return true
        } catch {
            errorMessage = "更新存储位置失败: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }
    
    /// 删除存储位置
    func deleteLocation(_ location: StorageLocation) async -> Bool {
        // 检查是否可以删除
        let canDelete = await checkCanDelete(location)
        if !canDelete {
            errorMessage = "该存储位置有关联的食材，无法删除"
            return false
        }
        
        do {
            try await repository.delete(location)
            successMessage = "存储位置删除成功"
            await loadLocations()
            return true
        } catch {
            errorMessage = "删除存储位置失败: \(error.localizedDescription)"
            return false
        }
    }
    
    /// 检查是否可以删除
    func checkCanDelete(_ location: StorageLocation) async -> Bool {
        do {
            return try await repository.canDelete(location)
        } catch {
            return false
        }
    }
    
    /// 获取存储位置的食材数量
    func getIngredientCount(for location: StorageLocation) async -> Int {
        do {
            let ingredients = try await repository.fetchIngredients(for: location)
            return ingredients.count
        } catch {
            return 0
        }
    }
    
    /// 按区域获取位置
    func getLocations(in area: String) -> [StorageLocation] {
        locationsByArea[area] ?? []
    }
    
    /// 获取所有区域
    func getAllAreas() -> [String] {
        Array(locationsByArea.keys).sorted()
    }
    
    // MARK: - Private Methods
    
    /// 按区域分组位置
    private func groupLocationsByArea() {
        locationsByArea = Dictionary(grouping: locations, by: { $0.area })
    }
}
