//
//  PrinterConnectionView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  打印机连接视图
//

import SwiftUI

/// 打印机连接视图
struct PrinterConnectionView: View {
    @StateObject private var viewModel = PrinterViewModel()
    @State private var selectedConnectionType: ConnectionType = .bluetooth
    @State private var showingStatusView = false
    
    enum ConnectionType: String, CaseIterable {
        case bluetooth = "蓝牙"
        case wifi = "WiFi"
    }
    
    var body: some View {
        List {
            // 当前连接的打印机
            if let printer = viewModel.connectedPrinter {
                Section("当前连接") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(printer.name)
                                .font(.headline)
                            Text(printer.connectionType.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Circle()
                            .fill(viewModel.printerStatus.isConnected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                    }
                    
                    Button {
                        showingStatusView = true
                    } label: {
                        Label("查看状态", systemImage: "info.circle")
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await viewModel.disconnect()
                        }
                    } label: {
                        Label("断开连接", systemImage: "xmark.circle")
                    }
                }
            }
            
            // 连接类型选择
            Section {
                Picker("连接方式", selection: $selectedConnectionType) {
                    ForEach(ConnectionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // 可用打印机列表
            Section {
                if viewModel.isScanning {
                    HStack {
                        ProgressView()
                        Text("扫描中...")
                            .foregroundColor(.secondary)
                    }
                } else if viewModel.availablePrinters.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "printer.slash")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("未找到打印机")
                            .font(.headline)
                        Text("点击下方按钮扫描打印机")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 140)
                    .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.availablePrinters) { printer in
                        PrinterRow(printer: printer) {
                            Task {
                                await viewModel.connect(to: printer)
                            }
                        }
                    }
                }
            } header: {
                Text("可用打印机")
            } footer: {
                if !viewModel.availablePrinters.isEmpty {
                    Text("找到 \(viewModel.availablePrinters.count) 台打印机")
                }
            }
            
            // 扫描按钮
            Section {
                Button {
                    Task {
                        switch selectedConnectionType {
                        case .bluetooth:
                            await viewModel.scanBluetoothPrinters()
                        case .wifi:
                            await viewModel.discoverWiFiPrinters()
                        }
                    }
                } label: {
                    Label("扫描打印机", systemImage: "magnifyingglass")
                }
                .disabled(viewModel.isScanning)
            }
        }
        .navigationTitle("打印机")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingStatusView) {
            NavigationView {
                PrinterStatusView(viewModel: viewModel)
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
        .alert("成功", isPresented: .constant(viewModel.successMessage != nil)) {
            Button("确定") {
                viewModel.successMessage = nil
            }
        } message: {
            if let message = viewModel.successMessage {
                Text(message)
            }
        }
    }
}

// MARK: - Printer Row

struct PrinterRow: View {
    let printer: PrinterDevice
    let onConnect: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: printer.connectionType == .bluetooth ? "antenna.radiowaves.left.and.right" : "wifi")
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(printer.name)
                    .font(.headline)
                
                if printer.connectionType == .wifi, let ip = printer.ipAddress {
                    Text(ip)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("连接") {
                onConnect()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}

#Preview {
    NavigationView {
        PrinterConnectionView()
    }
}
