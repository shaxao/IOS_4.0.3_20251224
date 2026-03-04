//
//  CostAnalysisView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  成本分析视图
//

import SwiftUI

/// 成本分析视图
struct CostAnalysisView: View {
    @ObservedObject var viewModel: PurchaseViewModel
    @Environment(\.presentationMode) private var presentationMode
    @State private var showingExportSheet = false
    
    private var sortedCategories: [Category] {
        viewModel.costByCategory.keys.sorted { $0.rawValue < $1.rawValue }
    }
    
    private var supplierIds: [UUID] {
        Array(viewModel.costBySupplier.keys)
    }
    
    var body: some View {
        List {
            // 总成本
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("总成本")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("¥\(viewModel.totalCost, specifier: "%.2f")")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            // 按类别统计
            if !viewModel.costByCategory.isEmpty {
                Section(header: Text("按类别统计")) {
                    ForEach(sortedCategories, id: \.self) { category in
                        if let cost = viewModel.costByCategory[category] {
                            HStack {
                                Label(category.rawValue, systemImage: category.icon)
                                    .foregroundColor(category.color)
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("¥\(cost, specifier: "%.2f")")
                                        .fontWeight(.semibold)
                                    
                                    if viewModel.totalCost > 0 {
                                        Text("\(Int((cost / viewModel.totalCost) * 100))%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // 按供应商统计
            if !viewModel.costBySupplier.isEmpty {
                Section(header: Text("按供应商统计")) {
                    ForEach(supplierIds, id: \.self) { supplierID in
                        if let cost = viewModel.costBySupplier[supplierID] {
                            HStack {
                                Text("供应商")
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("¥\(cost, specifier: "%.2f")")
                                        .fontWeight(.semibold)
                                    
                                    if viewModel.totalCost > 0 {
                                        Text("\(Int((cost / viewModel.totalCost) * 100))%")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            // 导出按钮
            Section {
                Button {
                    Task {
                        if let csvData = await viewModel.exportData() {
                            showingExportSheet = true
                        }
                    }
                } label: {
                    Label("导出CSV", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("成本分析")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        CostAnalysisView(viewModel: PurchaseViewModel())
    }
}
