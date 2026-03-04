//
//  PurchaseRecordView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  采购记录视图
//

import SwiftUI

/// 采购记录视图
struct PurchaseRecordView: View {
    @StateObject private var viewModel = PurchaseViewModel()
    @State private var showingAddSheet = false
    @State private var showingFilterSheet = false
    @State private var showingAnalysisSheet = false
    
    var body: some View {
        List {
            // 统计信息
            if !viewModel.filteredRecords.isEmpty {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("总成本")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("¥\(viewModel.totalCost, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Spacer()
                        
                        Button {
                            showingAnalysisSheet = true
                        } label: {
                            Label("分析", systemImage: "chart.bar")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
            
            // 采购记录列表
            Section {
                if viewModel.isLoading && viewModel.purchaseRecords.isEmpty {
                    ProgressView("加载中...")
                } else if viewModel.filteredRecords.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "cart")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("没有采购记录")
                            .font(.headline)
                        Text("点击右上角 + 添加采购记录")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 140)
                    .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.filteredRecords) { record in
                        PurchaseRecordRow(record: record)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deletePurchaseRecord(record)
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("采购记录")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: viewModel.selectedIngredientID != nil ||
                          viewModel.selectedSupplierID != nil ||
                          viewModel.startDate != nil ||
                          viewModel.endDate != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            await viewModel.loadPurchaseRecords()
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationView {
                PurchaseRecordFormView()
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            NavigationView {
                PurchaseFilterView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingAnalysisSheet) {
            NavigationView {
                CostAnalysisView(viewModel: viewModel)
            }
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .task {
            await viewModel.loadPurchaseRecords()
        }
    }
}

// MARK: - Purchase Record Row

struct PurchaseRecordRow: View {
    let record: PurchaseRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.purchaseDate, style: .date)
                    .font(.headline)
                Spacer()
                Text("¥\(record.totalCost, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("数量: \(record.quantity.formatted())")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("·")
                    .foregroundColor(.secondary)
                
                Text("单价: ¥\(record.unitCost, specifier: "%.2f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let notes = record.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Purchase Filter View

struct PurchaseFilterView: View {
    @ObservedObject var viewModel: PurchaseViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("日期范围") {
                DatePicker(
                    "开始日期",
                    selection: Binding(
                        get: { viewModel.startDate ?? Date() },
                        set: { viewModel.startDate = $0 }
                    ),
                    displayedComponents: .date
                )
                
                Toggle("设置开始日期", isOn: Binding(
                    get: { viewModel.startDate != nil },
                    set: { if !$0 { viewModel.startDate = nil } }
                ))
                
                DatePicker(
                    "结束日期",
                    selection: Binding(
                        get: { viewModel.endDate ?? Date() },
                        set: { viewModel.endDate = $0 }
                    ),
                    displayedComponents: .date
                )
                
                Toggle("设置结束日期", isOn: Binding(
                    get: { viewModel.endDate != nil },
                    set: { if !$0 { viewModel.endDate = nil } }
                ))
            }
            
            Section {
                Button("清除所有筛选") {
                    viewModel.clearFilters()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("筛选")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Purchase Record Form View

struct PurchaseRecordFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var quantity: Double = 0
    @State private var unitPrice: Double = 0
    @State private var purchaseDate = Date()
    @State private var notes = ""
    
    var totalCost: Double {
        quantity * unitPrice
    }
    
    var body: some View {
        Form {
            Section("采购信息") {
                TextField("数量", value: $quantity, format: .number)
                    .keyboardType(.decimalPad)
                
                TextField("单价", value: $unitPrice, format: .number)
                    .keyboardType(.decimalPad)
                
                HStack {
                    Text("总价")
                    Spacer()
                    Text("¥\(totalCost, specifier: "%.2f")")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                }
                
                DatePicker("采购日期", selection: $purchaseDate, displayedComponents: .date)
            }
            
            Section("备注") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
            }
        }
        .navigationTitle("添加采购记录")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    // 保存逻辑
                    dismiss()
                }
                .disabled(quantity <= 0 || unitPrice <= 0)
            }
        }
    }
}

#Preview {
    NavigationView {
        PurchaseRecordView()
    }
}
