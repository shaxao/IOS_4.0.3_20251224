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
    @StateObject private var viewModel = PrinterViewModel.shared
    @State private var selectedConnectionType: ConnectionType = .bluetooth
    @State private var showingStatusView = false
    @State private var isRunningTestPrint = false
    
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

                    Button {
                        Task {
                            await runTestPrint()
                        }
                    } label: {
                        Label(isRunningTestPrint ? "测试打印中..." : "测试打印", systemImage: "printer.dotmatrix")
                    }
                    .disabled(isRunningTestPrint)
                    
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
        .task {
            if viewModel.connectedPrinter != nil {
                await viewModel.refreshStatus()
            }
        }
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
        .alert("连接异常", isPresented: $viewModel.showingReconnectAlert) {
            Button("重新配对") {
                viewModel.showingReconnectAlert = false
            }
            Button("取消", role: .cancel) {
                viewModel.showingReconnectAlert = false
            }
        } message: {
            Text("打印机状态同步失败，请重新配对。")
        }
    }

    private func runTestPrint() async {
        guard viewModel.connectedPrinter != nil else {
            viewModel.errorMessage = "请先连接打印机"
            return
        }
        isRunningTestPrint = true
        let template = LabelTemplate(
            name: "测试打印",
            width: 40,
            height: 30,
            elements: [
                LabelTemplate.LabelElement(type: .text, x: 2, y: 2, width: 36, height: 8, fontSize: 12, content: "title"),
                LabelTemplate.LabelElement(type: .text, x: 2, y: 12, width: 36, height: 6, fontSize: 9, content: "time"),
                LabelTemplate.LabelElement(type: .qrCode, x: 24, y: 18, width: 14, height: 10, content: "qrData")
            ]
        )
        let data = [
            "title": "Printer Test / 测试标签",
            "time": Date().formatted(date: .numeric, time: .shortened),
            "qrData": UUID().uuidString
        ]
        _ = await viewModel.printLabel(template: template, data: data)
        isRunningTestPrint = false
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
