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
                ContentUnavailableView(
                    "没有存储位置",
                    systemImage: "location",
                    description: Text("点击右上角 + 添加存储位置")
                )
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
                
                if let humidity = location.humidity {
                    Label("\(humidity, specifier: "%.0f")%", systemImage: "humidity")
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
    @State private var area = ""
    @State private var temperature: Double?
    @State private var humidity: Double?
    @State private var notes = ""
    @State private var hasTemperature = false
    @State private var hasHumidity = false
    @Environment(\.dismiss) private var dismiss
    
    init(mode: Mode) {
        self.mode = mode
        if case .edit(let location) = mode {
            _name = State(initialValue: location.name)
            _area = State(initialValue: location.area)
            _temperature = State(initialValue: location.temperature)
            _humidity = State(initialValue: location.humidity)
            _notes = State(initialValue: location.notes ?? "")
            _hasTemperature = State(initialValue: location.temperature != nil)
            _hasHumidity = State(initialValue: location.humidity != nil)
        }
    }
    
    var body: some View {
        Form {
            Section("基本信息") {
                TextField("位置名称", text: $name)
                TextField("区域", text: $area)
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
                
                Toggle("设置湿度", isOn: $hasHumidity)
                
                if hasHumidity {
                    HStack {
                        Text("湿度")
                        Spacer()
                        TextField("", value: Binding(
                            get: { humidity ?? 0 },
                            set: { humidity = $0 }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                }
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
                        let success = await viewModel.createLocation(
                            name: name,
                            area: area,
                            temperature: hasTemperature ? temperature : nil,
                            humidity: hasHumidity ? humidity : nil,
                            notes: notes.isEmpty ? nil : notes
                        )
                        if success {
                            dismiss()
                        }
                    }
                }
                .disabled(name.isEmpty || area.isEmpty || viewModel.isSaving)
            }
        }
    }
}

#Preview {
    NavigationView {
        StorageLocationListView()
    }
}
