//
//  DataExportManager.swift
//  RestaurantIngredientManager
//
//  数据导入/导出管理器
//

import Foundation
import UniformTypeIdentifiers

/// 导出格式
enum ExportFormat {
    case csv
    case json
    case excel
    case pdf
}

/// 导入/导出管理器
class DataExportManager {
    
    // MARK: - Export Methods
    
    /// 导出食材数据
    func exportIngredients(_ ingredients: [Ingredient], format: ExportFormat) throws -> Data {
        switch format {
        case .csv:
            return try exportIngredientsToCSV(ingredients)
        case .json:
            return try exportIngredientsToJSON(ingredients)
        case .excel:
            return try exportIngredientsToExcel(ingredients)
        case .pdf:
            return try exportIngredientsToPDF(ingredients)
        }
    }
    
    /// 导出采购记录
    func exportPurchaseRecords(_ records: [PurchaseRecord], format: ExportFormat) throws -> Data {
        switch format {
        case .csv:
            return try exportPurchaseRecordsToCSV(records)
        case .json:
            return try exportPurchaseRecordsToJSON(records)
        case .excel:
            return try exportPurchaseRecordsToExcel(records)
        case .pdf:
            return try exportPurchaseRecordsToPDF(records)
        }
    }
    
    /// 导出供应商数据
    func exportSuppliers(_ suppliers: [Supplier], format: ExportFormat) throws -> Data {
        switch format {
        case .csv:
            return try exportSuppliersToCSV(suppliers)
        case .json:
            return try exportSuppliersToJSON(suppliers)
        case .excel:
            return try exportSuppliersToExcel(suppliers)
        case .pdf:
            return try exportSuppliersToPDF(suppliers)
        }
    }
    
    // MARK: - CSV Export
    
    private func exportIngredientsToCSV(_ ingredients: [Ingredient]) throws -> Data {
        var csv = "名称,类别,数量,单位,保质期,存储位置,供应商,条码,最低库存,备注\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for ingredient in ingredients {
            let row = [
                escapeCSV(ingredient.name),
                escapeCSV(ingredient.category.rawValue),
                String(ingredient.quantity),
                escapeCSV(ingredient.unit),
                dateFormatter.string(from: ingredient.expirationDate),
                escapeCSV(ingredient.storageLocation.name),
                escapeCSV(ingredient.supplier?.name ?? ""),
                escapeCSV(ingredient.barcode ?? ""),
                String(ingredient.minimumStockThreshold),
                escapeCSV(ingredient.notes ?? "")
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    private func exportPurchaseRecordsToCSV(_ records: [PurchaseRecord]) throws -> Data {
        var csv = "日期,食材ID,供应商ID,数量,单价,总价,备注\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        for record in records {
            let row = [
                dateFormatter.string(from: record.purchaseDate),
                record.ingredientId.uuidString,
                record.supplierId.uuidString,
                String(record.quantity),
                String(format: "%.2f", record.unitCost),
                String(format: "%.2f", record.totalCost),
                escapeCSV(record.notes ?? "")
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    private func exportSuppliersToCSV(_ suppliers: [Supplier]) throws -> Data {
        var csv = "名称,联系人,电话,邮箱,地址,备注\n"
        
        for supplier in suppliers {
            let row = [
                escapeCSV(supplier.name),
                escapeCSV(supplier.contactPerson ?? ""),
                escapeCSV(supplier.phone ?? ""),
                escapeCSV(supplier.email ?? ""),
                escapeCSV(supplier.address ?? ""),
                escapeCSV(supplier.notes ?? "")
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    // MARK: - JSON Export
    
    private func exportIngredientsToJSON(_ ingredients: [Ingredient]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(ingredients)
    }
    
    private func exportPurchaseRecordsToJSON(_ records: [PurchaseRecord]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(records)
    }
    
    private func exportSuppliersToJSON(_ suppliers: [Supplier]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try encoder.encode(suppliers)
    }
    
    // MARK: - Excel Export (Placeholder)
    
    private func exportIngredientsToExcel(_ ingredients: [Ingredient]) throws -> Data {
        // 实际实现需要使用Excel库（如xlsxwriter）
        // 这里返回CSV格式作为占位符
        return try exportIngredientsToCSV(ingredients)
    }
    
    private func exportPurchaseRecordsToExcel(_ records: [PurchaseRecord]) throws -> Data {
        return try exportPurchaseRecordsToCSV(records)
    }
    
    private func exportSuppliersToExcel(_ suppliers: [Supplier]) throws -> Data {
        return try exportSuppliersToCSV(suppliers)
    }
    
    // MARK: - PDF Export (Placeholder)
    
    private func exportIngredientsToPDF(_ ingredients: [Ingredient]) throws -> Data {
        // 实际实现需要使用PDF生成库
        // 这里返回简单的文本数据作为占位符
        let text = "食材列表\n\n" + ingredients.map { $0.name }.joined(separator: "\n")
        guard let data = text.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        return data
    }
    
    private func exportPurchaseRecordsToPDF(_ records: [PurchaseRecord]) throws -> Data {
        let text = "采购记录\n\n共 \(records.count) 条记录"
        guard let data = text.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        return data
    }
    
    private func exportSuppliersToPDF(_ suppliers: [Supplier]) throws -> Data {
        let text = "供应商列表\n\n" + suppliers.map { $0.name }.joined(separator: "\n")
        guard let data = text.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        return data
    }
    
    // MARK: - Import Methods
    
    /// 从CSV导入食材
    func importIngredientsFromCSV(_ data: Data) throws -> [Ingredient] {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidFormat
        }
        
        let lines = csvString.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw ImportError.emptyFile
        }
        
        var ingredients: [Ingredient] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // 跳过标题行
        for line in lines.dropFirst() where !line.isEmpty {
            let fields = parseCSVLine(line)
            guard fields.count >= 10 else { continue }
            
            // 解析字段并创建Ingredient对象
            // 实际实现需要处理所有字段
            
            // 示例：
            // let ingredient = Ingredient(...)
            // ingredients.append(ingredient)
        }
        
        return ingredients
    }
    
    /// 从JSON导入食材
    func importIngredientsFromJSON(_ data: Data) throws -> [Ingredient] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([Ingredient].self, from: data)
    }
    
    // MARK: - Helper Methods
    
    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var currentField = ""
        var insideQuotes = false
        
        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                fields.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        
        fields.append(currentField)
        return fields
    }
    
    // MARK: - File Operations
    
    /// 保存导出的数据到文件
    func saveExportedData(_ data: Data, filename: String, format: ExportFormat) throws -> URL {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let fileExtension: String
        switch format {
        case .csv: fileExtension = "csv"
        case .json: fileExtension = "json"
        case .excel: fileExtension = "xlsx"
        case .pdf: fileExtension = "pdf"
        }
        
        let fileURL = documentsURL.appendingPathComponent("\(filename).\(fileExtension)")
        
        try data.write(to: fileURL)
        
        return fileURL
    }
    
    /// 读取导入文件
    func readImportFile(from url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }
}

// MARK: - Export Error

enum ExportError: LocalizedError {
    case encodingFailed
    case fileWriteFailed
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "数据编码失败"
        case .fileWriteFailed:
            return "文件写入失败"
        case .unsupportedFormat:
            return "不支持的导出格式"
        }
    }
}

// MARK: - Import Error

enum ImportError: LocalizedError {
    case invalidFormat
    case emptyFile
    case parsingFailed
    case missingRequiredFields
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "无效的文件格式"
        case .emptyFile:
            return "文件为空"
        case .parsingFailed:
            return "数据解析失败"
        case .missingRequiredFields:
            return "缺少必需字段"
        }
    }
}
