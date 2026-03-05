import Foundation

@MainActor
final class IngredientCategoryProfileStore: ObservableObject {
    static let shared = IngredientCategoryProfileStore()

    @Published private(set) var profiles: [IngredientCategoryProfile] = []

    private let defaults: UserDefaults
    private let profilesKey = "ingredient.category.profiles.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func load() {
        if let data = defaults.data(forKey: profilesKey),
           let decoded = try? JSONDecoder().decode([IngredientCategoryProfile].self, from: data),
           !decoded.isEmpty {
            profiles = decoded.map(normalize)
            persist()
            return
        }

        profiles = [
            IngredientCategoryProfile(name: "蔬菜"),
            IngredientCategoryProfile(name: "肉类"),
            IngredientCategoryProfile(name: "海鲜")
        ]
        persist()
    }

    func upsert(_ profile: IngredientCategoryProfile) {
        let normalizedProfile = normalize(profile)
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = normalizedProfile
        } else {
            profiles.append(normalizedProfile)
        }
        persist()
    }

    func delete(profileID: UUID) {
        profiles.removeAll(where: { $0.id == profileID })
        persist()
    }

    func profile(by id: UUID?) -> IngredientCategoryProfile? {
        guard let id else { return nil }
        return profiles.first(where: { $0.id == id })
    }

    func rollbackTemplate(profileID: UUID, to version: Int) {
        guard var profile = profiles.first(where: { $0.id == profileID }) else { return }
        guard profile.templateVersions.contains(where: { $0.version == version }) else { return }
        profile.activeTemplateVersion = version
        profile.updatedAt = Date()
        upsert(profile)
    }

    func saveTemplate(profileID: UUID, template: String) {
        guard var profile = profiles.first(where: { $0.id == profileID }) else { return }
        let maxVersion = profile.templateVersions.map(\.version).max() ?? 0
        let nextVersion = maxVersion + 1
        profile.templateVersions.append(LabelTemplateVersion(version: nextVersion, template: template))
        profile.activeTemplateVersion = nextVersion
        profile.updatedAt = Date()
        upsert(profile)
    }

    private func persist() {
        if let encoded = try? JSONEncoder().encode(profiles) {
            defaults.set(encoded, forKey: profilesKey)
        }
    }

    private func normalize(_ profile: IngredientCategoryProfile) -> IngredientCategoryProfile {
        var normalized = profile
        let existingByKey = Dictionary(uniqueKeysWithValues: normalized.fields.map { ($0.key, $0) })
        let merged = IngredientCategoryProfile.defaultFields.map { defaultField -> IngredientFieldDefinition in
            if var existing = existingByKey[defaultField.key] {
                existing.kind = IngredientFieldDefinition.defaultKind(for: existing.key)
                return existing
            }
            return defaultField
        }
        normalized.fields = merged

        let useEnabled = merged.first(where: { $0.key == .useTime })?.enabled ?? false
        let expEnabled = merged.first(where: { $0.key == .expTime })?.enabled ?? false
        if useEnabled || expEnabled {
            if let thawIndex = normalized.fields.firstIndex(where: { $0.key == .thawTime }) {
                normalized.fields[thawIndex].enabled = true
            }
            if let preserveIndex = normalized.fields.firstIndex(where: { $0.key == .preserveTime }) {
                normalized.fields[preserveIndex].enabled = true
            }
        }
        return normalized
    }
}
