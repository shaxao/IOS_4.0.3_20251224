import XCTest
@testable import RestaurantIngredientManager

final class CategoryTemplateEngineTests: XCTestCase {
    func testTimeCalculationPath() {
        let thaw = 30
        let preserve = 180
        let thawTime = Date(timeIntervalSince1970: 1_700_000_000)
        let useTime = Calendar.current.date(byAdding: .minute, value: thaw, to: thawTime)!
        let expTime = Calendar.current.date(byAdding: .minute, value: preserve, to: useTime)!

        XCTAssertEqual(Int(useTime.timeIntervalSince(thawTime) / 60), thaw)
        XCTAssertEqual(Int(expTime.timeIntervalSince(useTime) / 60), preserve)
    }

    func testFieldTogglePath() {
        var profile = IngredientCategoryProfile(name: "测试分类")
        if let index = profile.fields.firstIndex(where: { $0.key == .stock }) {
            profile.fields[index].enabled = false
        }
        let enabled = profile.fields.filter(\.enabled).map(\.key)
        XCTAssertFalse(enabled.contains(.stock))
        XCTAssertTrue(enabled.contains(.name))
    }

    func testTemplateRenderPath() {
        let output = LabelTemplateEngine.render("{{name}}|{{useTime}}|{{expTime}}", with: [
            "name": "鸡胸肉",
            "useTime": "2026/03/04 10:00",
            "expTime": "2026/03/05 10:00"
        ])
        XCTAssertEqual(output, "鸡胸肉|2026/03/04 10:00|2026/03/05 10:00")
    }
}
