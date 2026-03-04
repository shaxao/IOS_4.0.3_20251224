//
//  LabelPrintView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  标签打印视图
//

import SwiftUI

/// 标签打印视图
struct LabelPrintView: View {
    let ingredient: Ingredient
    @StateObject private var viewModel = PrinterViewModel.shared
    @StateObject private var profileStore = IngredientCategoryProfileStore.shared
    @State private var selectedTemplate: LabelTemplate?
    @State private var copies: Int = 1
    @State private var showingPrinterSettings = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            // 食材信息
            Section("食材信息") {
                HStack {
                    Text("名称")
                    Spacer()
                    Text(ingredient.name)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("类别")
                    Spacer()
                    Text(ingredient.category.rawValue)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("数量")
                    Spacer()
                    Text("\(ingredient.quantity.formatted()) \(ingredient.unit)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("保质期")
                    Spacer()
                    Text(ingredient.expirationDate, style: .date)
                        .foregroundColor(.secondary)
                }
            }
            
            // 打印机状态
            Section("打印机") {
                if let printer = viewModel.connectedPrinter {
                    HStack {
                        Text(printer.name)
                        Spacer()
                        Circle()
                            .fill(viewModel.printerStatus.isConnected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                    }
                } else {
                    Text("未连接打印机")
                        .foregroundColor(.secondary)
                    Button("前往打印设置") {
                        showingPrinterSettings = true
                    }
                }
            }
            
            // 标签模板选择
            Section("标签模板") {
                Picker("选择模板", selection: $selectedTemplate) {
                    Text("默认模板").tag(nil as LabelTemplate?)
                    // 这里可以添加更多模板选项
                }
            }
            
            // 打印份数
            Section("打印份数") {
                Stepper("\(copies) 份", value: $copies, in: 1...10)
            }
            
            // 打印按钮
            Section {
                Button {
                    Task {
                        await printLabel()
                    }
                } label: {
                    if viewModel.isPrinting {
                        HStack {
                            ProgressView()
                            Text("打印中...")
                        }
                    } else {
                        Label("开始打印", systemImage: "printer")
                    }
                }
                .disabled(viewModel.connectedPrinter == nil || viewModel.isPrinting || !viewModel.printerStatus.canPrint())
            }
        }
        .navigationTitle("打印标签")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.refreshStatus()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("取消") {
                    dismiss()
                }
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
        .sheet(isPresented: $showingPrinterSettings) {
            NavigationView {
                PrinterConnectionView()
            }
        }
        .alert("成功", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("确定") {
                viewModel.successMessage = nil
                dismiss()
            }
        } message: {
            if let message = viewModel.successMessage {
                Text(message)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func printLabel() async {
        let template = selectedTemplate ?? createCategoryTemplate()
        if viewModel.connectedPrinter == nil || !viewModel.printerStatus.isConnected {
            viewModel.errorMessage = "打印机未连接，请先在打印设置中连接"
            showingPrinterSettings = true
            return
        }
        
        if copies == 1 {
            _ = await viewModel.printIngredientLabel(ingredient, template: template)
        } else {
            let labels = Array(repeating: (template, createLabelData()), count: copies)
            _ = await viewModel.printBatch(labels: labels)
        }
    }
    
    private func createDefaultTemplate() -> LabelTemplate {
        LabelTemplate(
            name: "默认食材标签",
            width: 50,
            height: 30,
            elements: [
                LabelTemplate.LabelElement(
                    type: .text,
                    x: 2, y: 2,
                    width: 46, height: 8,
                    fontSize: 14,
                    content: "name"
                ),
                LabelTemplate.LabelElement(
                    type: .text,
                    x: 2, y: 10,
                    width: 30, height: 6,
                    fontSize: 10,
                    content: "quantity"
                ),
                LabelTemplate.LabelElement(
                    type: .text,
                    x: 2, y: 16,
                    width: 30, height: 6,
                    fontSize: 10,
                    content: "expiryDate"
                ),
                LabelTemplate.LabelElement(
                    type: .qrCode,
                    x: 34, y: 10,
                    width: 14, height: 14,
                    content: "qrData"
                )
            ]
        )
    }

    private func createCategoryTemplate() -> LabelTemplate {
        if let profileID = ingredient.dynamicMetadata?.categoryProfileID,
           let profile = profileStore.profile(by: profileID) {
            return LabelTemplateEngine.makeTemplateFromText(profile.activeTemplate.template, name: "\(profile.name)模板", width: 40, height: 30)
        }
        return createDefaultTemplate()
    }
    
    private func createLabelData() -> [String: String] {
        [
            "name": ingredient.name,
            "category": ingredient.category.rawValue,
            "quantity": "\(ingredient.quantity.formatted()) \(ingredient.unit)",
            "expiryDate": ingredient.expirationDate.formatted(date: .abbreviated, time: .omitted),
            "barcode": ingredient.barcode ?? ingredient.id.uuidString,
            "qrData": ingredient.id.uuidString
        ]
    }
}

#Preview {
    NavigationView {
        LabelPrintView(ingredient: Ingredient(
            name: "鸡胸肉",
            category: .meat,
            quantity: 5,
            unit: "kg",
            expirationDate: Date().addingTimeInterval(86400 * 7),
            storageLocation: StorageLocation(name: "冷藏区", type: .refrigerator),
            minimumStockThreshold: 2
        ))
    }
}
