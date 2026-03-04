//
//  IngredientListView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  食材列表视图
//

import SwiftUI

/// 食材列表视图
struct IngredientListView: View {
    @StateObject private var viewModel = IngredientListViewModel()
    @State private var showingAddSheet = false
    @State private var showingFilterSheet = false
    @State private var selectedIngredient: Ingredient?
    
    var body: some View {
        ZStack {
            if viewModel.isLoading && viewModel.ingredients.isEmpty {
                ProgressView("加载中...")
            } else {
                ingredientList
            }
        }
        .navigationTitle("食材管理")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                filterButton
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                addButton
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "搜索食材名称或条形码")
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationView {
                IngredientFormView(mode: .create)
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedIngredient) { ingredient in
            NavigationView {
                IngredientDetailView(ingredient: ingredient)
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
            await viewModel.loadIngredients()
        }
    }
    
    // MARK: - Subviews
    
    private var ingredientList: some View {
        List {
            // 统计信息
            if viewModel.expiringCount > 0 || viewModel.lowStockCount > 0 {
                Section {
                    if viewModel.expiringCount > 0 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("即将过期")
                            Spacer()
                            Text("\(viewModel.expiringCount)")
                                .foregroundColor(.secondary)
                        }
                        .onTapGesture {
                            viewModel.showExpiringOnly = true
                        }
                    }
                    
                    if viewModel.lowStockCount > 0 {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.red)
                            Text("库存不足")
                            Spacer()
                            Text("\(viewModel.lowStockCount)")
                                .foregroundColor(.secondary)
                        }
                        .onTapGesture {
                            viewModel.showLowStockOnly = true
                        }
                    }
                }
            }
            
            // 食材列表
            Section {
                if viewModel.filteredIngredients.isEmpty {
                    EmptyStateView(
                        title: "没有食材",
                        systemImage: "tray",
                        message: "点击右上角 + 添加食材"
                    )
                } else {
                    ForEach(viewModel.filteredIngredients) { ingredient in
                        IngredientRow(ingredient: ingredient)
                            .onTapGesture {
                                selectedIngredient = ingredient
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteIngredient(ingredient)
                                    }
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var addButton: some View {
        Button {
            showingAddSheet = true
        } label: {
            Image(systemName: "plus")
        }
    }
    
    private var filterButton: some View {
        Button {
            showingFilterSheet = true
        } label: {
            Image(systemName: viewModel.selectedCategory != nil || 
                  viewModel.selectedSupplierID != nil ||
                  viewModel.selectedLocationID != nil ||
                  viewModel.showExpiringOnly ||
                  viewModel.showLowStockOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }
}

// MARK: - Ingredient Row

struct IngredientRow: View {
    let ingredient: Ingredient
    
    var body: some View {
        HStack(spacing: 12) {
            // 类别图标
            Image(systemName: ingredient.category.icon)
                .font(.title2)
                .foregroundColor(ingredient.category.color)
                .frame(width: 40, height: 40)
                .background(ingredient.category.color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    Text("\(ingredient.quantity.formatted()) \(ingredient.unit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(ingredient.expirationDate, style: .date)
                        .font(.caption)
                        .foregroundColor(ingredient.isExpiringSoon(within: 3) ? .orange : .secondary)
                }
            }
            
            Spacer()
            
            // 状态徽章
            VStack(alignment: .trailing, spacing: 4) {
                if ingredient.isExpiringSoon(within: 3) {
                    Label("即将过期", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if ingredient.isLowStock {
                    Label("库存低", systemImage: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @ObservedObject var viewModel: IngredientListViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("类别") {
                    Picker("选择类别", selection: $viewModel.selectedCategory) {
                        Text("全部").tag(nil as Category?)
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category as Category?)
                        }
                    }
                }
                
                Section("状态") {
                    Toggle("只显示即将过期", isOn: $viewModel.showExpiringOnly)
                    Toggle("只显示库存不足", isOn: $viewModel.showLowStockOnly)
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
}

// MARK: - Category Extension

extension Category {
    var icon: String {
        switch self {
        case .vegetables: return "leaf.fill"
        case .meat: return "fork.knife"
        case .seafood: return "fish.fill"
        case .dairy: return "drop.fill"
        case .dryGoods: return "circle.grid.2x2.fill"
        case .condiments: return "drop.triangle.fill"
        case .beverages: return "cup.and.saucer.fill"
        case .frozen: return "snowflake"
        case .other: return "square.grid.2x2.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .vegetables: return .green
        case .meat: return .red
        case .seafood: return .blue
        case .dairy: return .cyan
        case .dryGoods: return .brown
        case .condiments: return .yellow
        case .beverages: return .purple
        case .frozen: return .indigo
        case .other: return .gray
        }
    }
}

private struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padding(.vertical, 16)
    }
}

#Preview {
    NavigationView {
        IngredientListView()
    }
}
