//
//  IngredientFormView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  食材表单视图
//

import SwiftUI

/// 食材表单视图
struct IngredientFormView: View {
    enum Mode {
        case create
        case edit(Ingredient)
        
        var title: String {
            switch self {
            case .create: return "添加食材"
            case .edit: return "编辑食材"
            }
        }
    }
    
    let mode: Mode
    @StateObject private var viewModel: IngredientDetailViewModel
    @State private var showingScanner = false
    @StateObject private var profileStore = IngredientCategoryProfileStore.shared
    @Environment(\.dismiss) private var dismiss
    
    init(mode: Mode) {
        self.mode = mode
        switch mode {
        case .create:
            _viewModel = StateObject(wrappedValue: IngredientDetailViewModel())
        case .edit(let ingredient):
            _viewModel = StateObject(wrappedValue: IngredientDetailViewModel(ingredient: ingredient))
        }
    }
    
    var body: some View {
        Form {
            // 基本信息
            Section("基本信息") {
                TextField("食材名称", text: $viewModel.name)

                Picker("分类", selection: $viewModel.selectedCategoryProfileID) {
                    ForEach(profileStore.profiles) { profile in
                        Text(profile.name).tag(profile.id as UUID?)
                    }
                }

                Picker("类别", selection: $viewModel.category) {
                    ForEach(Category.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
            }

            if let profile = viewModel.activeCategoryProfile {
                Section("分类字段") {
                    ForEach(profile.fields.filter(\.enabled)) { field in
                        dynamicFieldInput(field: field)
                    }
                }
            }
            Section("库存") {
                HStack {
                    TextField("当前数量（可选）", value: $viewModel.quantity, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("单位（可选）", text: $viewModel.unit)
                        .frame(width: 120)
                }
                HStack {
                    Text("最小库存")
                    Spacer()
                    TextField("", value: $viewModel.minimumStockThreshold, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text(viewModel.unit)
                        .foregroundColor(.secondary)
                }
            }
            
            // 条形码
            Section("条形码") {
                HStack {
                    TextField("条形码", text: Binding(
                        get: { viewModel.barcode ?? "" },
                        set: { viewModel.barcode = $0.isEmpty ? nil : $0 }
                    ))
                    
                    Button {
                        showingScanner = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                    }
                }
            }
            
            // 备注
            Section("备注") {
                TextEditor(text: Binding(
                    get: { viewModel.notes ?? "" },
                    set: { viewModel.notes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 100)
            }
            
            // 验证错误
            if !viewModel.validationErrors.isEmpty {
                Section {
                    ForEach(viewModel.validationErrors, id: \.self) { error in
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("取消") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    Task {
                        if await viewModel.save() {
                            dismiss()
                        }
                    }
                }
                .disabled(!viewModel.canSave || viewModel.isSaving)
            }
        }
        .sheet(isPresented: $showingScanner) {
            ScannerView(onScanComplete: { result in
                viewModel.barcode = result.code
                showingScanner = false
            })
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
        .overlay {
            if viewModel.isSaving {
                ProgressView("保存中...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
    }

    @ViewBuilder
    private func dynamicFieldInput(field: IngredientFieldDefinition) -> some View {
        switch field.key {
        case .thawTime:
            Stepper("\(field.alias)：\(viewModel.thawDurationMinutes) 分钟", value: $viewModel.thawDurationMinutes, in: 0...10080)
        case .preserveTime:
            Stepper("\(field.alias)：\(viewModel.preserveDurationMinutes) 分钟", value: $viewModel.preserveDurationMinutes, in: 0...43200)
        case .useTime:
            HStack {
                Text(field.alias)
                Spacer()
                Text(viewModel.calculatedUseTime.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(.secondary)
            }
        case .expTime:
            HStack {
                Text(field.alias)
                Spacer()
                Text(viewModel.calculatedExpTime.formatted(date: .abbreviated, time: .shortened))
                    .foregroundColor(.secondary)
            }
        case .name:
            HStack {
                Text(field.alias)
                Spacer()
                Text(viewModel.name)
                    .foregroundColor(.secondary)
            }
        case .stock:
            TextField(field.alias, value: $viewModel.quantity, format: .number)
                .keyboardType(.decimalPad)
        case .unit:
            TextField(field.alias, text: $viewModel.unit)
        case .operatorName, .storageCondition:
            TextField(
                field.alias,
                text: Binding(
                    get: { viewModel.dynamicFieldValues[field.key.rawValue] ?? "" },
                    set: { viewModel.updateDynamicFieldValue($0, for: field.key) }
                )
            )
        }
    }
}

#Preview {
    NavigationView {
        IngredientFormView(mode: .create)
    }
}
