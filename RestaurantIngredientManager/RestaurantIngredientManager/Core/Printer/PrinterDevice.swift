//
//  PrinterDevice.swift
//  RestaurantIngredientManager
//
//  Created on 2024
//  打印机设备模型
//

import Foundation

/// 打印机设备模型
struct PrinterDevice: Identifiable, Equatable {
    /// 设备唯一标识符
    let id: String
    
    /// 设备名称
    let name: String
    
    /// 连接类型
    let connectionType: ConnectionType
    
    /// 信号强度（仅蓝牙，0-100）
    let signalStrength: Int?
    
    /// IP地址（仅WiFi）
    let ipAddress: String?
    
    /// 端口号（仅WiFi）
    let port: UInt16?
    
    /// 连接类型枚举
    enum ConnectionType: String, Codable {
        case bluetooth = "蓝牙"
        case wifi = "WiFi"
    }
    
    /// 初始化蓝牙打印机设备
    /// - Parameters:
    ///   - name: 设备名称
    ///   - signalStrength: 信号强度（可选）
    init(bluetoothName name: String, signalStrength: Int? = nil) {
        self.id = name
        self.name = name
        self.connectionType = .bluetooth
        self.signalStrength = signalStrength
        self.ipAddress = nil
        self.port = nil
    }
    
    /// 初始化WiFi打印机设备
    /// - Parameters:
    ///   - name: 设备名称
    ///   - ipAddress: IP地址
    ///   - port: 端口号（可选，默认9100）
    init(wifiName name: String, ipAddress: String, port: UInt16? = 9100) {
        self.id = ipAddress
        self.name = name
        self.connectionType = .wifi
        self.signalStrength = nil
        self.ipAddress = ipAddress
        self.port = port
    }
}

// MARK: - Codable
extension PrinterDevice: Codable {
    enum CodingKeys: String, CodingKey {
        case id, name, connectionType, signalStrength, ipAddress, port
    }
}
