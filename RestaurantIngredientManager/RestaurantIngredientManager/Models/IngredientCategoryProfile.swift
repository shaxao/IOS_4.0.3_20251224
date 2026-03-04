import Foundation

enum IngredientFieldKey: String, Codable, CaseIterable, Identifiable {
    case name
    case thawTime
    case preserveTime
    case useTime
    case expTime
    case operatorName
    case storageCondition
    case stock
    case unit

    var id: String { rawValue }
}

struct IngredientFieldDefinition: Codable, Equatable, Identifiable {
    var key: IngredientFieldKey
    var alias: String
    var enabled: Bool
    var required: Bool

    var id: String { key.rawValue }
}

struct LabelTemplateVersion: Codable, Equatable, Identifiable {
    var id: UUID
    var version: Int
    var template: String
    var createdAt: Date

    init(id: UUID = UUID(), version: Int, template: String, createdAt: Date = Date()) {
        self.id = id
        self.version = version
        self.template = template
        self.createdAt = createdAt
    }
}

struct IngredientCategoryProfile: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var fields: [IngredientFieldDefinition]
    var templateVersions: [LabelTemplateVersion]
    var activeTemplateVersion: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        fields: [IngredientFieldDefinition] = IngredientCategoryProfile.defaultFields,
        templateVersions: [LabelTemplateVersion] = [LabelTemplateVersion(version: 1, template: "{{name}}\n{{useTime}}\n{{expTime}}")],
        activeTemplateVersion: Int = 1,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.fields = fields
        self.templateVersions = templateVersions
        self.activeTemplateVersion = activeTemplateVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static var defaultFields: [IngredientFieldDefinition] {
        [
            IngredientFieldDefinition(key: .name, alias: "名称", enabled: true, required: true),
            IngredientFieldDefinition(key: .thawTime, alias: "解冻时间", enabled: true, required: true),
            IngredientFieldDefinition(key: .preserveTime, alias: "保存时间", enabled: true, required: true),
            IngredientFieldDefinition(key: .useTime, alias: "使用时间", enabled: true, required: false),
            IngredientFieldDefinition(key: .expTime, alias: "到期时间", enabled: true, required: false),
            IngredientFieldDefinition(key: .operatorName, alias: "制作人员", enabled: true, required: false),
            IngredientFieldDefinition(key: .storageCondition, alias: "贮存条件", enabled: true, required: false),
            IngredientFieldDefinition(key: .stock, alias: "库存", enabled: true, required: false),
            IngredientFieldDefinition(key: .unit, alias: "单位", enabled: true, required: false)
        ]
    }

    var activeTemplate: LabelTemplateVersion {
        templateVersions.first(where: { $0.version == activeTemplateVersion }) ?? templateVersions.last ?? LabelTemplateVersion(version: 1, template: "{{name}}")
    }
}

struct IngredientDynamicMetadata: Codable, Equatable {
    var categoryProfileID: UUID?
    var categoryProfileName: String?
    var thawMinutes: Int?
    var preserveMinutes: Int?
    var thawTimestamp: Date?
    var useTimestamp: Date?
    var expTimestamp: Date?
    var fieldValues: [String: String]

    init(
        categoryProfileID: UUID? = nil,
        categoryProfileName: String? = nil,
        thawMinutes: Int? = nil,
        preserveMinutes: Int? = nil,
        thawTimestamp: Date? = nil,
        useTimestamp: Date? = nil,
        expTimestamp: Date? = nil,
        fieldValues: [String: String] = [:]
    ) {
        self.categoryProfileID = categoryProfileID
        self.categoryProfileName = categoryProfileName
        self.thawMinutes = thawMinutes
        self.preserveMinutes = preserveMinutes
        self.thawTimestamp = thawTimestamp
        self.useTimestamp = useTimestamp
        self.expTimestamp = expTimestamp
        self.fieldValues = fieldValues
    }
}
