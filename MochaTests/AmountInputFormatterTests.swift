import XCTest
@testable import Mocha

final class AmountInputFormatterTests: XCTestCase {
    func testNormalizePreservesEditingIntermediateStates() {
        XCTAssertEqual(AmountInputFormatter.normalize("", allowsNegative: true), "")
        XCTAssertEqual(AmountInputFormatter.normalize("-", allowsNegative: true), "-")
        XCTAssertEqual(AmountInputFormatter.normalize("0.", allowsNegative: true), "0.")
        XCTAssertEqual(AmountInputFormatter.normalize("-0.", allowsNegative: true), "-0.")
        XCTAssertEqual(AmountInputFormatter.normalize(".5", allowsNegative: true), "0.5")
        XCTAssertEqual(AmountInputFormatter.normalize("-.5", allowsNegative: true), "-0.5")
    }

    func testNormalizeAcceptsCurrencyAndGroupingWhenPasted() {
        XCTAssertEqual(
            AmountInputFormatter.normalize("￥ 1,234.50", allowsNegative: false),
            "1234.50"
        )
        XCTAssertEqual(
            AmountInputFormatter.normalize("-¥9,876.5432", allowsNegative: true),
            "-9876.5432"
        )
    }

    func testNormalizeRejectsNegativeForUnsignedFields() {
        XCTAssertNil(AmountInputFormatter.normalize("-1", allowsNegative: false))
        XCTAssertNil(AmountInputFormatter.normalize("−0.5", allowsNegative: false))
    }

    func testNormalizeRejectsInvalidSyntaxAndExcessPrecision() {
        XCTAssertNil(AmountInputFormatter.normalize("1.2.3", allowsNegative: true))
        XCTAssertNil(AmountInputFormatter.normalize("--1", allowsNegative: true))
        XCTAssertNil(AmountInputFormatter.normalize("12a", allowsNegative: true))
        XCTAssertNil(AmountInputFormatter.normalize("1.23456", allowsNegative: true))
    }

    func testDecimalParsingSupportsNegativeAndIntermediateStates() {
        XCTAssertEqual(AmountInputFormatter.decimal(from: "12.34"), Decimal(string: "12.34"))
        XCTAssertEqual(AmountInputFormatter.decimal(from: "-0.5"), Decimal(string: "-0.5"))
        XCTAssertNil(AmountInputFormatter.decimal(from: ""))
        XCTAssertNil(AmountInputFormatter.decimal(from: "-"))
        XCTAssertEqual(AmountInputFormatter.decimal(from: "-0."), 0)
    }

    func testDisplayTextUsesGroupingAndTwoMinimumFractionDigits() {
        XCTAssertEqual(AmountInputFormatter.displayText(for: 1_234), "1,234.00")
        XCTAssertEqual(AmountInputFormatter.displayText(for: Decimal(string: "-12.3456")!), "-12.3456")
    }
}
