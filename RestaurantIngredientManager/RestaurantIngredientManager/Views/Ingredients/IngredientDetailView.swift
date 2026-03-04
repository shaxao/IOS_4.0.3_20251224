//
//  IngredientDetailView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  食材详情视图
//

import SwiftUI

/// 食材详情视图
struct IngredientDetailView: View {
    let ingredient: Ingredient
    @StateObject private var viewModel: IngredientDetailViewModel
    @State private var showingEditSheet = false
    @State private var showingPrintSheet = false
    @Environment(\.dismiss) private var dismiss
    
    init(ingredient: Ingredient) {
        self.ingredient = ingredient
        _viewModel = StateObject(wrappedValue: IngredientDetailViewModel(ingredient: ingredient))
    }
    
    var body: some View {
        List {
            // 基本信息
            Section("基本信息") {
                DetailRow(label: "名称", value: viewModel.name)
                DetailRow(label: "类别", value: viewModel.category.rawValue)
                DetailRow(label: "当前数量", value: "\(viewModel.currentQuantity.formatted()) \(viewModel.unit)")
                DetailRow(label: "最小库存", value: "\(viewModel.minimumStock.formatted()) \(viewModel.unit)")
            }
            
            // 日期信息
            Section("日期信息") {
                if let expiryDate = viewModel.expiryDate {
                    HStack {
                        Text("保质期")
                        Spacer()
                        Text(expiryDate, style: .date)
                            .foregroundColor(ingredient.isExpiringSoon() ? .orange : .primary)
                        if ingredient.isExpiringSoon() {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                } else {
                    DetailRow(label: "保质期", value: "未设置")
                }
            }
            
            // 条形码
            if let barcode = viewModel.barcode {
                Section("条形码") {
                    Text(barcode)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            // 备注
            if let notes = viewModel.notes, !notes.isEmpty {
                Section("备注") {
                    Text(notes)
                        .foregroundColor(.secondary)
                }
            }
            
            // 操作按钮
            Section {
                Button {
                    showingPrintSheet = true
                } label: {
                    Label("打印标签", systemImage: "printer")
                }
                
                Button {
                    showingEditSheet = true
                } label: {
                    Label("编辑", systemImage: "pencil")
                }
            }
        }
        .navigationTitle("食材详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationView {
                IngredientFormView(mode: .edit(ingredient))
            }
        }
        .sheet(isPresented: $showingPrintSheet) {
            NavigationView {
                LabelPrintView(ingredient: ingredient)
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
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationView {
        IngredientDetailView(ingredient: Ingredient(
            name: "鸡胸肉",
            category: .meat,
            currentQuantity: 5,
            unit: "kg",
            minimumStock: 2,
            expiryDate: Date().addingTimeInterval(86400 * 2),
            barcode: "1234567890",
            notes: "新鲜鸡胸肉"
        ))
    }
}
