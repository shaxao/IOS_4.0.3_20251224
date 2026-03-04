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
                
                Picker("类别", selection: $viewModel.category) {
                    ForEach(Category.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                
                HStack {
                    TextField("当前数量", value: $viewModel.currentQuantity, format: .number)
                        .keyboardType(.decimalPad)
                    TextField("单位", text: $viewModel.unit)
                        .frame(width: 80)
                }
                
                HStack {
                    Text("最小库存")
                    Spacer()
                    TextField("", value: $viewModel.minimumStock, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    Text(viewModel.unit)
                        .foregroundColor(.secondary)
                }
            }
            
            // 保质期
            Section("保质期") {
                DatePicker(
                    "到期日期",
                    selection: Binding(
                        get: { viewModel.expiryDate ?? Date() },
                        set: { viewModel.expiryDate = $0 }
                    ),
                    displayedComponents: .date
                )
                
                Toggle("设置保质期", isOn: Binding(
                    get: { viewModel.expiryDate != nil },
                    set: { if $0 { viewModel.expiryDate = Date() } else { viewModel.expiryDate = nil } }
                ))
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
}

#Preview {
    NavigationView {
        IngredientFormView(mode: .create)
    }
}
