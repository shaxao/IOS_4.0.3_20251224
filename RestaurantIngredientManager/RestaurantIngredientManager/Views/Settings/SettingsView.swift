//
//  SettingsView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  设置视图
//

import SwiftUI

/// 设置视图
struct SettingsView: View {
    @AppStorage("selectedLanguage") private var selectedLanguage = "zh-Hans"
    @AppStorage("expiryWarningDays") private var expiryWarningDays = 3
    @State private var showingAbout = false
    
    var body: some View {
        List {
            // 语言设置
            Section("语言") {
                Picker("选择语言", selection: $selectedLanguage) {
                    Text("简体中文").tag("zh-Hans")
                    Text("English").tag("en")
                }
            }
            
            // 通知设置
            Section("通知") {
                Stepper("保质期警告: \(expiryWarningDays) 天", value: $expiryWarningDays, in: 1...7)
                
                Text("当食材在 \(expiryWarningDays) 天内过期时显示警告")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 数据管理
            Section("数据管理") {
                NavigationLink {
                    SupplierListView()
                } label: {
                    Label("供应商管理", systemImage: "building.2")
                }
                
                NavigationLink {
                    StorageLocationListView()
                } label: {
                    Label("存储位置管理", systemImage: "location")
                }
            }
            
            // 关于
            Section {
                Button {
                    showingAbout = true
                } label: {
                    Label("关于", systemImage: "info.circle")
                }
            }
            
            // 版本信息
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("餐厅食材管理系统")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("版本 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Divider()
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("功能特性")
                        .font(.headline)
                    
                    FeatureRow(icon: "list.bullet", text: "食材库存管理")
                    FeatureRow(icon: "qrcode.viewfinder", text: "条形码扫描")
                    FeatureRow(icon: "printer", text: "标签打印")
                    FeatureRow(icon: "cart", text: "采购记录")
                    FeatureRow(icon: "chart.bar", text: "成本分析")
                }
                .padding()
                
                Spacer()
            }
            .padding()
            .navigationTitle("关于")
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

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
