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

enum IngredientFieldKind: String, Codable {
    case text
    case duration
    case computedTime
    case number
}

enum DurationUnit: String, Codable, CaseIterable, Identifiable {
    case minute
    case hour
    case day
    case month
    case year
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minute: return "分钟"
        case .hour: return "小时"
        case .day: return "天"
        case .month: return "月"
        case .year: return "年"
        case .custom: return "自定义"
        }
    }
}

struct DurationValue: Codable, Equatable {
    var amount: Int
    var unit: DurationUnit
    var customMinutes: Int?

    init(amount: Int = 0, unit: DurationUnit = .minute, customMinutes: Int? = nil) {
        self.amount = amount
        self.unit = unit
        self.customMinutes = customMinutes
    }
}

struct IngredientFieldDefinition: Codable, Equatable, Identifiable {
    var key: IngredientFieldKey
    var alias: String
    var enabled: Bool
    var required: Bool
    var kind: IngredientFieldKind

    var id: String { key.rawValue }

    init(key: IngredientFieldKey, alias: String, enabled: Bool, required: Bool, kind: IngredientFieldKind) {
        self.key = key
        self.alias = alias
        self.enabled = enabled
        self.required = required
        self.kind = kind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(IngredientFieldKey.self, forKey: .key)
        alias = try container.decode(String.self, forKey: .alias)
        enabled = try container.decode(Bool.self, forKey: .enabled)
        required = try container.decode(Bool.self, forKey: .required)
        kind = try container.decodeIfPresent(IngredientFieldKind.self, forKey: .kind) ?? IngredientFieldDefinition.defaultKind(for: key)
    }

    static func defaultKind(for key: IngredientFieldKey) -> IngredientFieldKind {
        switch key {
        case .thawTime, .preserveTime:
            return .duration
        case .useTime, .expTime:
            return .computedTime
        case .stock:
            return .number
        default:
            return .text
        }
    }
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
            IngredientFieldDefinition(key: .name, alias: "名称", enabled: true, required: true, kind: .text),
            IngredientFieldDefinition(key: .thawTime, alias: "解冻时间", enabled: true, required: true, kind: .duration),
            IngredientFieldDefinition(key: .preserveTime, alias: "保存时间", enabled: true, required: true, kind: .duration),
            IngredientFieldDefinition(key: .useTime, alias: "使用时间", enabled: true, required: false, kind: .computedTime),
            IngredientFieldDefinition(key: .expTime, alias: "到期时间", enabled: true, required: false, kind: .computedTime),
            IngredientFieldDefinition(key: .operatorName, alias: "制作人员", enabled: true, required: false, kind: .text),
            IngredientFieldDefinition(key: .storageCondition, alias: "贮存条件", enabled: true, required: false, kind: .text),
            IngredientFieldDefinition(key: .stock, alias: "库存", enabled: true, required: false, kind: .number),
            IngredientFieldDefinition(key: .unit, alias: "单位", enabled: true, required: false, kind: .text)
        ]
    }

    var activeTemplate: LabelTemplateVersion {
        templateVersions.first(where: { $0.version == activeTemplateVersion }) ?? templateVersions.last ?? LabelTemplateVersion(version: 1, template: "{{name}}")
    }
}

struct IngredientDynamicMetadata: Codable, Equatable {
    var categoryProfileID: UUID?
    var categoryProfileName: String?
    var thawDuration: DurationValue?
    var preserveDuration: DurationValue?
    var thawTimestamp: Date?
    var useTimestamp: Date?
    var expTimestamp: Date?
    var fieldValues: [String: String]

    init(
        categoryProfileID: UUID? = nil,
        categoryProfileName: String? = nil,
        thawDuration: DurationValue? = nil,
        preserveDuration: DurationValue? = nil,
        thawTimestamp: Date? = nil,
        useTimestamp: Date? = nil,
        expTimestamp: Date? = nil,
        fieldValues: [String: String] = [:]
    ) {
        self.categoryProfileID = categoryProfileID
        self.categoryProfileName = categoryProfileName
        self.thawDuration = thawDuration
        self.preserveDuration = preserveDuration
        self.thawTimestamp = thawTimestamp
        self.useTimestamp = useTimestamp
        self.expTimestamp = expTimestamp
        self.fieldValues = fieldValues
    }
}
