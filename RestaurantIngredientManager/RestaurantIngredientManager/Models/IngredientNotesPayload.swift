import Foundation

struct IngredientNotesPayload: Codable, Equatable {
    var plainNotes: String?
    var metadata: IngredientDynamicMetadata?
}

enum IngredientNotesCodec {
    static let prefix = "RIM-NOTES::"

    static func decode(_ raw: String?) -> IngredientNotesPayload {
        guard let raw, !raw.isEmpty else {
            return IngredientNotesPayload(plainNotes: nil, metadata: nil)
        }
        guard raw.hasPrefix(prefix) else {
            return IngredientNotesPayload(plainNotes: raw, metadata: nil)
        }
        let encodedPart = String(raw.dropFirst(prefix.count))
        guard let data = encodedPart.data(using: .utf8),
              let payload = try? JSONDecoder().decode(IngredientNotesPayload.self, from: data) else {
            return IngredientNotesPayload(plainNotes: raw, metadata: nil)
        }
        return payload
    }

    static func encode(plainNotes: String?, metadata: IngredientDynamicMetadata?) -> String? {
        if (plainNotes?.isEmpty ?? true) && metadata == nil {
            return nil
        }
        let payload = IngredientNotesPayload(
            plainNotes: plainNotes?.isEmpty == true ? nil : plainNotes,
            metadata: metadata
        )
        guard let data = try? JSONEncoder().encode(payload),
              let json = String(data: data, encoding: .utf8) else {
            return plainNotes
        }
        return prefix + json
    }
}
