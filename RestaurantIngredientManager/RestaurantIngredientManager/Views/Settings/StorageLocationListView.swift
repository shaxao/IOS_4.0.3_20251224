//
//  StorageLocationListView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  存储位置列表视图
//

import SwiftUI

/// 存储位置列表视图
struct StorageLocationListView: View {
    @StateObject private var viewModel = StorageLocationViewModel()
    @State private var showingAddSheet = false
    @State private var selectedLocation: StorageLocation?
    
    var body: some View {
        List {
            if viewModel.isLoading && viewModel.locations.isEmpty {
                ProgressView("加载中...")
            } else if viewModel.locations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "location")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("没有存储位置")
                        .font(.headline)
                    Text("点击右上角 + 添加存储位置")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 140)
                .padding(.vertical, 8)
            } else {
                ForEach(viewModel.getAllAreas(), id: \.self) { area in
                    Section(area) {
                        ForEach(viewModel.getLocations(in: area)) { location in
                            StorageLocationRow(location: location, viewModel: viewModel)
                                .onTapGesture {
                                    selectedLocation = location
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteLocation(location)
                                        }
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
        }
        .navigationTitle("存储位置")
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
            await viewModel.loadLocations()
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationView {
                StorageLocationFormView(mode: .create)
            }
        }
        .sheet(item: $selectedLocation) { location in
            NavigationView {
                StorageLocationFormView(mode: .edit(location))
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
            await viewModel.loadLocations()
        }
    }
}

// MARK: - Storage Location Row

struct StorageLocationRow: View {
    let location: StorageLocation
    @ObservedObject var viewModel: StorageLocationViewModel
    @State private var ingredientCount = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(location.name)
                .font(.headline)
            
            HStack(spacing: 12) {
                if let temp = location.temperature {
                    Label("\(temp, specifier: "%.1f")°C", systemImage: "thermometer")
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
            ingredientCount = await viewModel.getIngredientCount(for: location)
        }
    }
}

// MARK: - Storage Location Form View

struct StorageLocationFormView: View {
    enum Mode {
        case create
        case edit(StorageLocation)
        
        var title: String {
            switch self {
            case .create: return "添加存储位置"
            case .edit: return "编辑存储位置"
            }
        }
    }
    
    let mode: Mode
    @StateObject private var viewModel = StorageLocationViewModel()
    @State private var name = ""
    @State private var type: StorageLocation.LocationType = .refrigerator
    @State private var temperature: Double?
    @State private var hasTemperature = false
    @Environment(\.dismiss) private var dismiss
    
    init(mode: Mode) {
        self.mode = mode
        if case .edit(let location) = mode {
            _name = State(initialValue: location.name)
            _type = State(initialValue: location.type)
            _temperature = State(initialValue: location.temperature)
            _hasTemperature = State(initialValue: location.temperature != nil)
        }
    }
    
    var body: some View {
        Form {
            Section("基本信息") {
                TextField("位置名称", text: $name)
                Picker("类型", selection: $type) {
                    ForEach(StorageLocation.LocationType.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
            }
            
            Section("环境参数") {
                Toggle("设置温度", isOn: $hasTemperature)
                
                if hasTemperature {
                    HStack {
                        Text("温度")
                        Spacer()
                        TextField("", value: Binding(
                            get: { temperature ?? 0 },
                            set: { temperature = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        Text("°C")
                            .foregroundColor(.secondary)
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
                        let success = await viewModel.createLocation(
                            name: name,
                            type: type,
                            temperature: hasTemperature ? temperature : nil
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
        StorageLocationListView()
    }
}
