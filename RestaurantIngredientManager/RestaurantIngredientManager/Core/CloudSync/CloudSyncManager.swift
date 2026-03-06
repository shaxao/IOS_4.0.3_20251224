//
//  CloudSyncManager.swift
//  RestaurantIngredientManager
//
//  iCloud同步管理器
//

import Foundation
import CloudKit
import Combine

/// iCloud同步状态
enum CloudSyncStatus {
    case idle
    case syncing
    case success
    case failed(Error)
}

/// iCloud同步管理器
class CloudSyncManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var syncStatus: CloudSyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var isCloudAvailable: Bool = false
    
    // MARK: - Private Properties
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Record Types
    
    private enum RecordType {
        static let ingredient = "Ingredient"
        static let supplier = "Supplier"
        static let storageLocation = "StorageLocation"
        static let purchaseRecord = "PurchaseRecord"
    }
    
    // MARK: - Initialization
    
    init(containerIdentifier: String = "iCloud.com.restaurant.ingredientmanager") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
        
        checkCloudAvailability()
        setupNotifications()
    }
    
    // MARK: - Cloud Availability
    
    /// 检查iCloud可用性
    func checkCloudAvailability() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.isCloudAvailable = (status == .available)
                
                if let error = error {
                    print("❌ iCloud账户检查失败: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Sync Operations
    
    /// 同步所有数据到iCloud
    func syncToCloud() async throws {
        guard isCloudAvailable else {
            throw CloudSyncError.cloudNotAvailable
        }
        
        DispatchQueue.main.async {
            self.syncStatus = .syncing
        }
        
        do {
            // 同步各类数据
            try await syncIngredients()
            try await syncSuppliers()
            try await syncStorageLocations()
            try await syncPurchaseRecords()
            
            DispatchQueue.main.async {
                self.syncStatus = .success
                self.lastSyncDate = Date()
            }
            
            print("✅ 数据同步到iCloud成功")
        } catch {
            DispatchQueue.main.async {
                self.syncStatus = .failed(error)
            }
            throw error
        }
    }
    
    /// 从iCloud同步数据
    func syncFromCloud() async throws {
        guard isCloudAvailable else {
            throw CloudSyncError.cloudNotAvailable
        }
        
        DispatchQueue.main.async {
            self.syncStatus = .syncing
        }
        
        do {
            // 从云端获取数据
            try await fetchIngredients()
            try await fetchSuppliers()
            try await fetchStorageLocations()
            try await fetchPurchaseRecords()
            
            DispatchQueue.main.async {
                self.syncStatus = .success
                self.lastSyncDate = Date()
            }
            
            print("✅ 从iCloud同步数据成功")
        } catch {
            DispatchQueue.main.async {
                self.syncStatus = .failed(error)
            }
            throw error
        }
    }
    
    // MARK: - Ingredient Sync
    
    private func syncIngredients() async throws {
        // 获取本地食材数据
        // 转换为CKRecord
        // 保存到iCloud
        
        let records: [CKRecord] = [] // 实际实现中从Core Data获取
        
        try await saveRecords(records, to: privateDatabase)
    }
    
    private func fetchIngredients() async throws {
        let query = CKQuery(recordType: RecordType.ingredient, predicate: NSPredicate(value: true))
        let records = try await fetchRecords(query: query, from: privateDatabase)
        
        // 将CKRecord转换为本地数据模型
        // 保存到Core Data
        
        print("✅ 获取到 \(records.count) 个食材记录")
    }
    
    // MARK: - Supplier Sync
    
    private func syncSuppliers() async throws {
        let records: [CKRecord] = []
        try await saveRecords(records, to: privateDatabase)
    }
    
    private func fetchSuppliers() async throws {
        let query = CKQuery(recordType: RecordType.supplier, predicate: NSPredicate(value: true))
        let records = try await fetchRecords(query: query, from: privateDatabase)
        print("✅ 获取到 \(records.count) 个供应商记录")
    }
    
    // MARK: - Storage Location Sync
    
    private func syncStorageLocations() async throws {
        let records: [CKRecord] = []
        try await saveRecords(records, to: privateDatabase)
    }
    
    private func fetchStorageLocations() async throws {
        let query = CKQuery(recordType: RecordType.storageLocation, predicate: NSPredicate(value: true))
        let records = try await fetchRecords(query: query, from: privateDatabase)
        print("✅ 获取到 \(records.count) 个存储位置记录")
    }
    
    // MARK: - Purchase Record Sync
    
    private func syncPurchaseRecords() async throws {
        let records: [CKRecord] = []
        try await saveRecords(records, to: privateDatabase)
    }
    
    private func fetchPurchaseRecords() async throws {
        let query = CKQuery(recordType: RecordType.purchaseRecord, predicate: NSPredicate(value: true))
        let records = try await fetchRecords(query: query, from: privateDatabase)
        print("✅ 获取到 \(records.count) 个采购记录")
    }
    
    // MARK: - Helper Methods
    
    private func saveRecords(_ records: [CKRecord], to database: CKDatabase) async throws {
        guard !records.isEmpty else { return }
        
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInitiated
        
        return try await withCheckedThrowingContinuation { continuation in
            operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
            
            database.add(operation)
        }
    }
    
    private func fetchRecords(query: CKQuery, from database: CKDatabase) async throws -> [CKRecord] {
        return try await withCheckedThrowingContinuation { continuation in
            database.perform(query, inZoneWith: nil) { records, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: records ?? [])
                }
            }
        }
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        // 监听iCloud账户变化
        NotificationCenter.default.publisher(for: .CKAccountChanged)
            .sink { [weak self] _ in
                self?.checkCloudAvailability()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Conflict Resolution
    
    /// 解决同步冲突
    func resolveConflict(localRecord: CKRecord, cloudRecord: CKRecord) -> CKRecord {
        // 使用最新修改时间的记录
        let localModified = localRecord.modificationDate ?? Date.distantPast
        let cloudModified = cloudRecord.modificationDate ?? Date.distantPast
        
        return localModified > cloudModified ? localRecord : cloudRecord
    }
    
    // MARK: - Manual Sync
    
    /// 手动触发同步
    func manualSync() {
        Task {
            do {
                try await syncToCloud()
                try await syncFromCloud()
            } catch {
                print("❌ 手动同步失败: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Cloud Sync Error

enum CloudSyncError: LocalizedError {
    case cloudNotAvailable
    case syncFailed(String)
    case conflictResolutionFailed
    
    var errorDescription: String? {
        switch self {
        case .cloudNotAvailable:
            return "iCloud不可用，请检查iCloud设置"
        case .syncFailed(let message):
            return "同步失败: \(message)"
        case .conflictResolutionFailed:
            return "冲突解决失败"
        }
    }
}

// MARK: - Sync Settings

struct CloudSyncSettings {
    var autoSyncEnabled: Bool = true
    var syncInterval: TimeInterval = 300 // 5分钟
    var syncOnLaunch: Bool = true
    var syncOnBackground: Bool = true
    var wifiOnlySync: Bool = false
}
