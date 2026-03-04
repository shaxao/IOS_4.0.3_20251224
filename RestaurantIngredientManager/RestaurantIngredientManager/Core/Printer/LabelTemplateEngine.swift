import Foundation

struct CanvasTemplateItem: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case text
        case image
    }

    var id: UUID
    var kind: Kind
    var key: String
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    var fontSize: Double
    var isBold: Bool
    var isItalic: Bool
    var colorHex: String
}

struct CanvasTemplatePayload: Codable, Equatable {
    var paper: String
    var items: [CanvasTemplateItem]
}

enum LabelTemplateEngine {
    static let canvasPrefix = "CANVAS::"

    static func render(_ template: String, with data: [String: String]) -> String {
        if let payload = decodeCanvasTemplate(template) {
            let sorted = payload.items.sorted { $0.y < $1.y }
            let lines = sorted.map { item -> String in
                if item.kind == .image {
                    return "[IMAGE]"
                }
                return data[item.key] ?? ""
            }
            return lines.joined(separator: "\n")
        }
        var rendered = template
        let pattern = #"\{\{([a-zA-Z0-9_]+)\}\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return rendered
        }
        let fullRange = NSRange(rendered.startIndex..., in: rendered)
        let matches = regex.matches(in: rendered, range: fullRange).reversed()
        for match in matches {
            guard match.numberOfRanges > 1,
                  let keyRange = Range(match.range(at: 1), in: rendered),
                  let wholeRange = Range(match.range(at: 0), in: rendered) else {
                continue
            }
            let key = String(rendered[keyRange])
            let value = data[key] ?? ""
            rendered.replaceSubrange(wholeRange, with: value)
        }
        return rendered
    }

    static func makeTemplateFromText(_ templateText: String, name: String = "分类模板", width: Double = 40, height: Double = 30) -> LabelTemplate {
        if let payload = decodeCanvasTemplate(templateText) {
            return makeTemplateFromCanvas(payload, name: name, width: width, height: height)
        }
        let lines = templateText
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { String($0) }

        var elements: [LabelTemplate.LabelElement] = []
        var y: Double = 2
        for line in lines {
            elements.append(
                LabelTemplate.LabelElement(
                    type: .text,
                    x: 2,
                    y: y,
                    width: 36,
                    height: 4.5,
                    fontSize: 9,
                    content: line
                )
            )
            y += 5
            if y > 26 {
                break
            }
        }
        return LabelTemplate(name: name, width: width, height: height, elements: elements)
    }

    static func encodeCanvasTemplate(_ payload: CanvasTemplatePayload) -> String {
        guard let data = try? JSONEncoder().encode(payload),
              let json = String(data: data, encoding: .utf8) else {
            return ""
        }
        return canvasPrefix + json
    }

    static func decodeCanvasTemplate(_ raw: String) -> CanvasTemplatePayload? {
        guard raw.hasPrefix(canvasPrefix) else {
            return nil
        }
        let json = String(raw.dropFirst(canvasPrefix.count))
        guard let data = json.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(CanvasTemplatePayload.self, from: data)
    }

    private static func makeTemplateFromCanvas(_ payload: CanvasTemplatePayload, name: String, width: Double, height: Double) -> LabelTemplate {
        let elements = payload.items.sorted(by: { $0.y < $1.y }).map { item in
            if item.kind == .image {
                return LabelTemplate.LabelElement(
                    type: .rectangle,
                    x: item.x,
                    y: item.y,
                    width: item.width,
                    height: item.height,
                    fontSize: nil,
                    content: nil
                )
            }
            return LabelTemplate.LabelElement(
                type: .text,
                x: item.x,
                y: item.y,
                width: item.width,
                height: item.height,
                fontSize: item.fontSize,
                content: "{{\(item.key)}}"
            )
        }
        return LabelTemplate(name: name, width: width, height: height, elements: elements)
    }
}
