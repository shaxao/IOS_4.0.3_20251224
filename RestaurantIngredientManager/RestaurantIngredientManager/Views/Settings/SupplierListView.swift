//
//  SupplierListView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  供应商列表视图
//

import SwiftUI

/// 供应商列表视图
struct SupplierListView: View {
    @StateObject private var viewModel = SupplierViewModel()
    @State private var showingAddSheet = false
    @State private var selectedSupplier: Supplier?
    
    var body: some View {
        List {
            if viewModel.isLoading && viewModel.suppliers.isEmpty {
                ProgressView("加载中...")
            } else if viewModel.suppliers.isEmpty {
                ContentUnavailableView(
                    "没有供应商",
                    systemImage: "building.2",
                    description: Text("点击右上角 + 添加供应商")
                )
            } else {
                ForEach(viewModel.suppliers) { supplier in
                    SupplierRow(supplier: supplier, viewModel: viewModel)
                        .onTapGesture {
                            selectedSupplier = supplier
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteSupplier(supplier)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("供应商")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .refreshable {
            await viewModel.loadSuppliers()
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationView {
                SupplierFormView(mode: .create)
            }
        }
        .sheet(item: $selectedSupplier) { supplier in
            NavigationView {
                SupplierFormView(mode: .edit(supplier))
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
            await viewModel.loadSuppliers()
        }
    }
}

// MARK: - Supplier Row

struct SupplierRow: View {
    let supplier: Supplier
    @ObservedObject var viewModel: SupplierViewModel
    @State private var ingredientCount = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(supplier.name)
                .font(.headline)
            
            if let contact = supplier.contactPerson {
                Text(contact)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                if let phone = supplier.phone {
                    Label(phone, systemImage: "phone")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if ingredientCount > 0 {
                    Label("\(ingredientCount) 个食材", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .task {
            ingredientCount = await viewModel.getIngredientCount(for: supplier)
        }
    }
}

// MARK: - Supplier Form View

struct SupplierFormView: View {
    enum Mode {
        case create
        case edit(Supplier)
        
        var title: String {
            switch self {
            case .create: return "添加供应商"
            case .edit: return "编辑供应商"
            }
        }
    }
    
    let mode: Mode
    @StateObject private var viewModel = SupplierViewModel()
    @State private var name = ""
    @State private var contactPerson = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var address = ""
    @State private var notes = ""
    @Environment(\.dismiss) private var dismiss
    
    init(mode: Mode) {
        self.mode = mode
        if case .edit(let supplier) = mode {
            _name = State(initialValue: supplier.name)
            _contactPerson = State(initialValue: supplier.contactPerson ?? "")
            _phone = State(initialValue: supplier.phone ?? "")
            _email = State(initialValue: supplier.email ?? "")
            _address = State(initialValue: supplier.address ?? "")
            _notes = State(initialValue: supplier.notes ?? "")
        }
    }
    
    var body: some View {
        Form {
            Section("基本信息") {
                TextField("供应商名称", text: $name)
                TextField("联系人", text: $contactPerson)
            }
            
            Section("联系方式") {
                TextField("电话", text: $phone)
                    .keyboardType(.phonePad)
                TextField("邮箱", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
            
            Section("地址") {
                TextEditor(text: $address)
                    .frame(minHeight: 60)
            }
            
            Section("备注") {
                TextEditor(text: $notes)
                    .frame(minHeight: 100)
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
                        let success = await viewModel.createSupplier(
                            name: name,
                            contactPerson: contactPerson.isEmpty ? nil : contactPerson,
                            phone: phone.isEmpty ? nil : phone,
                            email: email.isEmpty ? nil : email,
                            address: address.isEmpty ? nil : address,
                            notes: notes.isEmpty ? nil : notes
                        )
                        if success {
                            dismiss()
                        }
                    }
                }
                .disabled(name.isEmpty || viewModel.isSaving)
            }
        }
    }
}

#Preview {
    NavigationView {
        SupplierListView()
    }
}
