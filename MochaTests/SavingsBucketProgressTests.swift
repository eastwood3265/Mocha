import XCTest
@testable import Mocha

final class SavingsBucketProgressTests: XCTestCase {
    func testEmptyBucketStartsAtZero() {
        let bucket = SavingsBucket(name: "旅行基金")

        XCTAssertEqual(SavingsBucketProgressCalculator.balance(for: bucket, entries: []), 0)
    }

    func testBalanceAggregatesDepositsAndWithdrawals() {
        let bucket = SavingsBucket(name: "旅行基金")
        let entries = [
            SavingsBucketEntry(bucket: bucket, type: .deposit, amount: 1_000),
            SavingsBucketEntry(bucket: bucket, type: .deposit, amount: 600),
            SavingsBucketEntry(bucket: bucket, type: .withdrawal, amount: 250)
        ]

        XCTAssertEqual(SavingsBucketProgressCalculator.balance(for: bucket, entries: entries), 1_350)
    }

    func testEntriesFromOtherBucketsAreIgnored() {
        let travel = SavingsBucket(name: "旅行基金")
        let emergency = SavingsBucket(name: "应急金")
        let entries = [
            SavingsBucketEntry(bucket: travel, type: .deposit, amount: 1_000),
            SavingsBucketEntry(bucket: emergency, type: .deposit, amount: 9_000)
        ]

        XCTAssertEqual(SavingsBucketProgressCalculator.balance(for: travel, entries: entries), 1_000)
    }

    func testWithdrawalCanProduceNegativeBalance() {
        let bucket = SavingsBucket(name: "新电脑")
        let entry = SavingsBucketEntry(bucket: bucket, type: .withdrawal, amount: 500)

        let progress = SavingsBucketProgressCalculator.progress(for: bucket, entries: [entry])

        XCTAssertEqual(progress.balance, -500)
        XCTAssertTrue(progress.isNegative)
    }

    func testExcludingEntrySupportsEditAndDeleteProjection() {
        let bucket = SavingsBucket(name: "旅行基金")
        let deposit = SavingsBucketEntry(bucket: bucket, type: .deposit, amount: 1_000)
        let withdrawal = SavingsBucketEntry(bucket: bucket, type: .withdrawal, amount: 200)

        XCTAssertEqual(
            SavingsBucketProgressCalculator.balance(
                for: bucket,
                entries: [deposit, withdrawal],
                excluding: withdrawal
            ),
            1_000
        )
    }

    func testTargetProgressIsClampedAndNegativeBalanceShowsZeroProgress() {
        let bucket = SavingsBucket(name: "旅行基金", targetAmount: 1_000)
        let overfunded = SavingsBucketProgress(bucket: bucket, balance: 1_500)
        let negative = SavingsBucketProgress(bucket: bucket, balance: -100)

        XCTAssertEqual(overfunded.ratio, 1)
        XCTAssertTrue(overfunded.isCompleted)
        XCTAssertEqual(overfunded.remainingAmount, 0)
        XCTAssertEqual(negative.ratio, 0)
        XCTAssertFalse(negative.isCompleted)
        XCTAssertEqual(negative.remainingAmount, 1_100)
    }

    func testBucketWithoutTargetHasNoProgress() {
        let bucket = SavingsBucket(name: "长期储蓄")
        let progress = SavingsBucketProgress(bucket: bucket, balance: 500)

        XCTAssertNil(progress.ratio)
        XCTAssertNil(progress.remainingAmount)
        XCTAssertFalse(progress.isCompleted)
    }

    func testSuggestedDailySavingIncludesTodayAndDeadline() throws {
        let calendar = makeCalendar()
        let referenceDate = try date(2026, 8, 20, calendar: calendar)
        let deadline = try date(2026, 8, 24, calendar: calendar)
        let bucket = SavingsBucket(name: "旅行基金", targetAmount: 1_000, deadline: deadline)
        let progress = SavingsBucketProgress(bucket: bucket, balance: 500)

        XCTAssertEqual(progress.remainingDayCount(from: referenceDate, calendar: calendar), 5)
        XCTAssertEqual(progress.suggestedDailySaving(from: referenceDate, calendar: calendar), 100)
    }

    func testExpiredDeadlineHasNoSuggestedDailySaving() throws {
        let calendar = makeCalendar()
        let referenceDate = try date(2026, 8, 20, calendar: calendar)
        let deadline = try date(2026, 8, 19, calendar: calendar)
        let bucket = SavingsBucket(name: "旅行基金", targetAmount: 1_000, deadline: deadline)
        let progress = SavingsBucketProgress(bucket: bucket, balance: 500)

        XCTAssertTrue(progress.isDeadlineExpired(at: referenceDate, calendar: calendar))
        XCTAssertNil(progress.suggestedDailySaving(from: referenceDate, calendar: calendar))
    }

    func testSummaryAggregatesOnlyProvidedBuckets() {
        let active = SavingsBucket(name: "旅行基金", targetAmount: 1_000)
        let archived = SavingsBucket(name: "旧目标", targetAmount: 2_000, isArchived: true)
        let entries = [
            SavingsBucketEntry(bucket: active, type: .deposit, amount: 400),
            SavingsBucketEntry(bucket: archived, type: .deposit, amount: 2_000)
        ]

        let summary = SavingsBucketProgressCalculator.summary(for: [active], entries: entries)

        XCTAssertEqual(summary.totalBalance, 400)
        XCTAssertEqual(summary.totalTarget, 1_000)
        XCTAssertEqual(summary.targetProgressRatio, 0.4)
    }

    func testSummaryDoesNotUseOneBucketsSurplusToCompleteAnother() {
        let completed = SavingsBucket(name: "旅行基金", targetAmount: 1_000)
        let empty = SavingsBucket(name: "应急金", targetAmount: 1_000)
        let entries = [
            SavingsBucketEntry(bucket: completed, type: .deposit, amount: 2_000)
        ]

        let summary = SavingsBucketProgressCalculator.summary(
            for: [completed, empty],
            entries: entries
        )

        XCTAssertEqual(summary.targetProgressRatio, 0.5)
    }

    private func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 8 * 60 * 60)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, calendar: Calendar) throws -> Date {
        try XCTUnwrap(calendar.date(from: DateComponents(year: year, month: month, day: day)))
    }
}
