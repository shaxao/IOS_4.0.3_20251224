import Foundation

enum LabelTemplateEngine {
    static func render(_ template: String, with data: [String: String]) -> String {
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
}
