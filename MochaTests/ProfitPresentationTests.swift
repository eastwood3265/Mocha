import XCTest
@testable import Mocha

final class ProfitPresentationTests: XCTestCase {
    func testEveryThemeMeetsNormalTextContrastRequirement() {
        for theme in AppThemeColor.allCases {
            XCTAssertGreaterThanOrEqual(
                theme.foregroundContrastRatio,
                4.5,
                "\(theme.title) 的主文字对比度不足"
            )
        }
    }

    func testDefaultStyleIsRedForProfit() {
        XCTAssertEqual(ProfitColorStyle.defaultStyle, .redForProfit)
    }

    func testRedForProfitMapsPositiveRedAndNegativeGreen() {
        XCTAssertEqual(ProfitColorStyle.redForProfit.colorRole(for: 100), .red)
        XCTAssertEqual(ProfitColorStyle.redForProfit.colorRole(for: -100), .green)
        XCTAssertEqual(ProfitColorStyle.redForProfit.colorRole(for: 0), .neutral)
    }

    func testGreenForProfitMapsPositiveGreenAndNegativeRed() {
        XCTAssertEqual(ProfitColorStyle.greenForProfit.colorRole(for: 100), .green)
        XCTAssertEqual(ProfitColorStyle.greenForProfit.colorRole(for: -100), .red)
        XCTAssertEqual(ProfitColorStyle.greenForProfit.colorRole(for: 0), .neutral)
    }

    func testProfitTextUsesSignOnlyForPositiveValues() {
        XCTAssertTrue(ProfitPresentation.text(for: 100).hasPrefix("+"))
        XCTAssertTrue(ProfitPresentation.text(for: -100).hasPrefix("-"))
        XCTAssertFalse(ProfitPresentation.text(for: 0).hasPrefix("+"))
    }

    func testInvalidStoredStyleFallsBackToDefault() {
        XCTAssertNil(ProfitColorStyle(rawValue: "invalid"))
        XCTAssertEqual(ProfitColorStyle(rawValue: "invalid") ?? .defaultStyle, .redForProfit)
    }
}
