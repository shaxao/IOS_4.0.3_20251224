//
//  PrinterStatusView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  打印机状态视图
//

import SwiftUI

/// 打印机状态视图
struct PrinterStatusView: View {
    @ObservedObject var viewModel: PrinterViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            // 连接状态
            Section("连接状态") {
                StatusRow(
                    label: "连接",
                    value: viewModel.printerStatus.isConnected ? "已连接" : "未连接",
                    color: viewModel.printerStatus.isConnected ? .green : .red
                )
            }
            
            // 打印机状态
            Section("打印机状态") {
                StatusRow(
                    label: "盖子",
                    value: viewModel.printerStatus.coverStatus.rawValue,
                    color: viewModel.printerStatus.coverStatus == .closed ? .green : .orange
                )
                
                StatusRow(
                    label: "纸张",
                    value: viewModel.printerStatus.paperStatus.rawValue,
                    color: paperStatusColor
                )
                
                if let battery = viewModel.printerStatus.batteryLevel {
                    HStack {
                        Text("电量")
                        Spacer()
                        HStack(spacing: 4) {
                            Text("\(battery)%")
                            Image(systemName: batteryIcon(level: battery))
                                .foregroundColor(batteryColor(level: battery))
                        }
                    }
                }
            }
            
            // 警告信息
            let warnings = viewModel.printerStatus.getWarnings()
            if !warnings.isEmpty {
                Section("警告") {
                    ForEach(warnings, id: \.self) { warning in
                        Label(warning, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // 操作
            Section {
                Button {
                    Task {
                        await viewModel.refreshStatus()
                    }
                } label: {
                    Label("刷新状态", systemImage: "arrow.clockwise")
                }
            }
        }
        .navigationTitle("打印机状态")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
        .task {
            await viewModel.refreshStatus()
        }
    }
    
    // MARK: - Helper Properties
    
    private var paperStatusColor: Color {
        switch viewModel.printerStatus.paperStatus {
        case .normal: return .green
        case .low: return .orange
        case .out: return .red
        }
    }
    
    private func batteryIcon(level: Int) -> String {
        if level > 75 {
            return "battery.100"
        } else if level > 50 {
            return "battery.75"
        } else if level > 25 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }
    
    private func batteryColor(level: Int) -> Color {
        if level > 50 {
            return .green
        } else if level > 20 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Status Row

struct StatusRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(value)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationView {
        PrinterStatusView(viewModel: PrinterViewModel())
    }
}
