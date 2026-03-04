//
//  ScannerView.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  扫描视图
//

import SwiftUI
import AVFoundation

/// 扫描视图
struct ScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var onScanComplete: ((ScanResult) -> Void)?
    
    var body: some View {
        ZStack {
            // 相机预览
            if viewModel.permissionStatus == .authorized {
                CameraPreviewView(previewLayer: viewModel.previewLayer)
                    .ignoresSafeArea()
                
                // 扫描框和提示
                VStack {
                    Spacer()
                    
                    // 扫描框
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 250, height: 250)
                        .overlay {
                            // 扫描线动画
                            if viewModel.isScanning {
                                ScanLineView()
                            }
                        }
                    
                    Spacer()
                    
                    // 提示文本
                    Text(viewModel.scanPrompt)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                        .padding()
                    
                    // 找到的食材信息
                    if let ingredient = viewModel.foundIngredient {
                        VStack(spacing: 8) {
                            Text(ingredient.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(ingredient.quantity.formatted()) \(ingredient.unit)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button("查看详情") {
                                // 导航到详情页
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("继续扫描") {
                                viewModel.reset()
                                Task {
                                    await viewModel.startScanning()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(radius: 10)
                        .padding()
                    }
                }
            } else {
                // 权限请求视图
                PermissionRequestView(viewModel: viewModel)
            }
        }
        .navigationTitle("扫描")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if onScanComplete != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await viewModel.requestPermission()
            if viewModel.permissionStatus == .authorized {
                await viewModel.startScanning()
            }
        }
        .onDisappear {
            viewModel.cleanup()
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
        .onChange(of: viewModel.lastScanResult) { _, newResult in
            if let result = newResult, let completion = onScanComplete {
                completion(result)
            }
        }
    }
}

// MARK: - Camera Preview View

struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black
        
        if let layer = previewLayer {
            layer.frame = view.bounds
            layer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(layer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = previewLayer {
            layer.frame = uiView.bounds
        }
    }
}

// MARK: - Scan Line View

struct ScanLineView: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(Color.green.opacity(0.5))
            .frame(height: 2)
            .offset(y: isAnimating ? 125 : -125)
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Permission Request View

struct PermissionRequestView: View {
    @ObservedObject var viewModel: ScannerViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("需要相机权限")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("扫描条形码和二维码需要访问相机")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if viewModel.permissionStatus == .denied {
                Button("前往设置") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("请求权限") {
                    Task {
                        await viewModel.requestPermission()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

#Preview {
    NavigationView {
        ScannerView()
    }
}
