import Foundation
import SwiftData

struct SavingsBucketProgress {
    let bucket: SavingsBucket
    let balance: Decimal

    var targetAmount: Decimal? { bucket.targetAmount }
    var isNegative: Bool { balance < 0 }

    var remainingAmount: Decimal? {
        targetAmount.map { max(0, $0 - balance) }
    }

    var isCompleted: Bool {
        guard let targetAmount, targetAmount > 0 else { return false }
        return balance >= targetAmount
    }

    var ratio: Double? {
        guard let targetAmount, targetAmount > 0 else { return nil }
        let rawRatio = NSDecimalNumber(decimal: balance / targetAmount).doubleValue
        return max(0, min(1, rawRatio))
    }

    func remainingDayCount(
        from referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Int? {
        guard let deadline else { return nil }
        let start = calendar.startOfDay(for: referenceDate)
        let end = calendar.startOfDay(for: deadline)
        guard end >= start else { return nil }
        let difference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return difference + 1
    }

    func suggestedDailySaving(
        from referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Decimal? {
        guard let remainingAmount, remainingAmount > 0,
              let dayCount = remainingDayCount(from: referenceDate, calendar: calendar) else {
            return nil
        }
        return remainingAmount / Decimal(dayCount)
    }

    func isDeadlineExpired(
        at referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        guard let deadline else { return false }
        return calendar.startOfDay(for: deadline) < calendar.startOfDay(for: referenceDate)
    }

    private var deadline: Date? { bucket.deadline }
}

struct SavingsBucketSummary {
    let totalBalance: Decimal
    let totalTarget: Decimal
    let targetProgressRatio: Double?
}

enum SavingsBucketProgressCalculator {
    static func balance(
        for bucket: SavingsBucket,
        entries: [SavingsBucketEntry],
        excluding excludedEntry: SavingsBucketEntry? = nil
    ) -> Decimal {
        entries
            .filter { entry in
                isSameBucket(entry.bucket, bucket) &&
                    entry.persistentModelID != excludedEntry?.persistentModelID
            }
            .reduce(Decimal.zero) { $0 + $1.signedAmount }
    }

    static func progress(
        for bucket: SavingsBucket,
        entries: [SavingsBucketEntry]
    ) -> SavingsBucketProgress {
        SavingsBucketProgress(
            bucket: bucket,
            balance: balance(for: bucket, entries: entries)
        )
    }

    static func summary(
        for buckets: [SavingsBucket],
        entries: [SavingsBucketEntry]
    ) -> SavingsBucketSummary {
        let progressValues = buckets.map { progress(for: $0, entries: entries) }
        let totalBalance = progressValues.reduce(Decimal.zero) { $0 + $1.balance }
        let targeted = progressValues.filter { ($0.targetAmount ?? 0) > 0 }
        let totalTarget = targeted.reduce(Decimal.zero) { $0 + ($1.targetAmount ?? 0) }

        let ratio: Double?
        if totalTarget > 0 {
            let targetedBalance = targeted.reduce(Decimal.zero) { partial, progress in
                partial + min(max(0, progress.balance), progress.targetAmount ?? 0)
            }
            let rawRatio = NSDecimalNumber(decimal: targetedBalance / totalTarget).doubleValue
            ratio = max(0, min(1, rawRatio))
        } else {
            ratio = nil
        }

        return SavingsBucketSummary(
            totalBalance: totalBalance,
            totalTarget: totalTarget,
            targetProgressRatio: ratio
        )
    }

    static func belongs(_ entry: SavingsBucketEntry, to bucket: SavingsBucket) -> Bool {
        isSameBucket(entry.bucket, bucket)
    }

    private static func isSameBucket(_ lhs: SavingsBucket?, _ rhs: SavingsBucket) -> Bool {
        lhs?.persistentModelID == rhs.persistentModelID
    }
}
