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
        switch field.kind {
        case .duration:
            let duration = viewModel.durationValue(for: field.key)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(field.alias)
                    Spacer()
                    Text(DurationCalculator.formatAsChineseDuration(duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Stepper(
                        "\(duration.amount)",
                        value: Binding(
                            get: { viewModel.durationValue(for: field.key).amount },
                            set: { viewModel.updateDurationAmount($0, for: field.key) }
                        ),
                        in: 0...50000
                    )
                    Picker(
                        "",
                        selection: Binding(
                            get: { viewModel.durationValue(for: field.key).unit },
                            set: { viewModel.updateDurationUnit($0, for: field.key) }
                        )
                    ) {
                        ForEach(DurationUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                }
                if duration.unit == .custom {
                    TextField(
                        "自定义分钟",
                        value: Binding(
                            get: { viewModel.durationValue(for: field.key).customMinutes ?? 0 },
                            set: { viewModel.updateCustomMinutes($0, for: field.key) }
                        ),
                        format: .number
                    )
                    .keyboardType(.numberPad)
                }
            }
        case .computedTime:
            HStack {
                Text(field.alias)
                Spacer()
                Text(
                    field.key == .useTime
                    ? viewModel.calculatedUseTime.formatted(date: .abbreviated, time: .shortened)
                    : viewModel.calculatedExpTime.formatted(date: .abbreviated, time: .shortened)
                )
                    .foregroundColor(.secondary)
            }
        case .number:
            TextField(field.alias, value: $viewModel.quantity, format: .number)
                .keyboardType(.decimalPad)
        case .text:
            if field.key == .name {
                HStack {
                    Text(field.alias)
                    Spacer()
                    Text(viewModel.name)
                        .foregroundColor(.secondary)
                }
            } else if field.key == .unit {
                TextField(field.alias, text: $viewModel.unit)
            } else {
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
}

#Preview {
    NavigationView {
        IngredientFormView(mode: .create)
    }
}
