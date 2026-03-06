//
//  ContentView.swift
//  RestaurantIngredientManager Watch App
//
//  Apple Watch主视图
//

import SwiftUI
import WatchConnectivity

struct WatchContentView: View {
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // 库存概览
                Section("库存概览") {
                    NavigationLink(destination: InventoryOverviewView()) {
                        Label("食材库存", systemImage: "list.bullet")
                    }
                    
                    NavigationLink(destination: LowStockView()) {
                        HStack {
                            Label("低库存", systemImage: "exclamationmark.triangle")
                            Spacer()
                            if viewModel.lowStockCount > 0 {
                                Text("\(viewModel.lowStockCount)")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // 过期提醒
                Section("过期提醒") {
                    NavigationLink(destination: ExpirationView()) {
                        HStack {
                            Label("即将过期", systemImage: "clock")
                            Spacer()
                            if viewModel.expiringCount > 0 {
                                Text("\(viewModel.expiringCount)")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // 快速操作
                Section("快速操作") {
                    Button(action: {
                        viewModel.requestSync()
                    }) {
                        Label("同步数据", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .navigationTitle("食材管理")
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

/// 库存概览视图
struct InventoryOverviewView: View {
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.ingredients.prefix(10)) { ingredient in
                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.name)
                        .font(.headline)
                    
                    HStack {
                        Text("\(Int(ingredient.quantity)) \(ingredient.unit)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if ingredient.quantity <= ingredient.minimumStockThreshold {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("库存")
    }
}

/// 低库存视图
struct LowStockView: View {
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.lowStockIngredients) { ingredient in
                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.name)
                        .font(.headline)
                    
                    Text("剩余: \(Int(ingredient.quantity)) \(ingredient.unit)")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Text("最低: \(Int(ingredient.minimumStockThreshold))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("低库存")
    }
}

/// 过期提醒视图
struct ExpirationView: View {
    @StateObject private var viewModel = WatchViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.expiringIngredients) { ingredient in
                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.name)
                        .font(.headline)
                    
                    Text(ingredient.expirationDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text(daysUntilExpiration(ingredient.expirationDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("即将过期")
    }
    
    private func daysUntilExpiration(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return "\(days)天后过期"
    }
}

/// Watch ViewModel
class WatchViewModel: NSObject, ObservableObject {
    @Published var ingredients: [Ingredient] = []
    @Published var lowStockCount: Int = 0
    @Published var expiringCount: Int = 0
    
    var lowStockIngredients: [Ingredient] {
        ingredients.filter { $0.quantity <= $0.minimumStockThreshold }
    }
    
    var expiringIngredients: [Ingredient] {
        let sevenDaysLater = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        return ingredients.filter { $0.expirationDate < sevenDaysLater && $0.expirationDate > Date() }
    }
    
    private var session: WCSession?
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    func loadData() {
        requestDataFromPhone()
    }
    
    func requestSync() {
        requestDataFromPhone()
    }
    
    private func requestDataFromPhone() {
        guard let session = session, session.isReachable else {
            print("⚠️ iPhone不可达")
            return
        }
        
        session.sendMessage(["action": "requestData"], replyHandler: { reply in
            DispatchQueue.main.async {
                self.handleDataFromPhone(reply)
            }
        }) { error in
            print("❌ 请求数据失败: \(error.localizedDescription)")
        }
    }
    
    private func handleDataFromPhone(_ data: [String: Any]) {
        // 解析从iPhone接收的数据
        // 实际实现中需要解码Ingredient数组
        
        if let count = data["lowStockCount"] as? Int {
            lowStockCount = count
        }
        
        if let count = data["expiringCount"] as? Int {
            expiringCount = count
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchViewModel: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ Watch连接激活失败: \(error.localizedDescription)")
        } else {
            print("✅ Watch连接已激活")
            loadData()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleDataFromPhone(message)
        }
    }
}

#Preview {
    WatchContentView()
}
