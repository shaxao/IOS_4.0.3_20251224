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
    @ObservedObject private var viewModel: IngredientDetailViewModel
    @State private var showingEditSheet = false
    @State private var showingPrintSheet = false
    @Environment(\.presentationMode) private var presentationMode
    
    init(ingredient: Ingredient) {
        self.ingredient = ingredient
        _viewModel = ObservedObject(wrappedValue: IngredientDetailViewModel(ingredient: ingredient))
    }
    
    var body: some View {
        List {
            // 基本信息
            Section(header: Text("基本信息")) {
                DetailRow(label: "名称", value: viewModel.name)
                DetailRow(label: "类别", value: viewModel.category.rawValue)
                DetailRow(label: "当前数量", value: "\(formattedNumber(viewModel.quantity)) \(viewModel.unit)")
                DetailRow(label: "最小库存", value: "\(formattedNumber(viewModel.minimumStockThreshold)) \(viewModel.unit)")
            }
            
            // 日期信息
            Section(header: Text("日期信息")) {
                if let expiryDate = viewModel.expirationDate {
                    HStack {
                        Text("保质期")
                        Spacer()
                        Text(formattedDate(expiryDate))
                            .foregroundColor(ingredient.isExpiringSoon(within: 3) ? .orange : .primary)
                        if ingredient.isExpiringSoon(within: 3) {
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
                Section(header: Text("条形码")) {
                    Text(barcode)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            // 备注
            if let notes = viewModel.notes, !notes.isEmpty {
                Section(header: Text("备注")) {
                    Text(notes)
                        .foregroundColor(.secondary)
                }
            }
            
            // 操作按钮
            Section(header: Text("")) {
                Button {
                    showingPrintSheet = true
                } label: {
                    HStack {
                        Image(systemName: "printer")
                        Text("打印标签")
                    }
                }
                
                Button {
                    showingEditSheet = true
                } label: {
                    HStack {
                        Image(systemName: "pencil")
                        Text("编辑")
                    }
                }
            }
        }
        .navigationBarTitle("食材详情", displayMode: .inline)
        .navigationBarItems(trailing: Button("完成") {
            presentationMode.wrappedValue.dismiss()
        })
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
        .alert(isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("错误"),
                message: Text(viewModel.errorMessage ?? ""),
                dismissButton: .default(Text("确定")) {
                    viewModel.errorMessage = nil
                }
            )
        }
    }
    
    private func formattedNumber(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
    
    private func formattedDate(_ date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
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
            quantity: 5,
            unit: "kg",
            expirationDate: Date().addingTimeInterval(86400 * 2),
            storageLocation: StorageLocation(name: "冷藏区", type: .refrigerator),
            barcode: "1234567890",
            minimumStockThreshold: 2,
            notes: "新鲜鸡胸肉"
        ))
    }
}
