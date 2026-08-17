import Foundation
import SwiftData

struct BudgetProgress {
    let budget: Budget
    let spent: Decimal

    var amount: Decimal { budget.amount }
    var remaining: Decimal { amount - spent }
    var isOverspent: Bool { remaining < 0 }

    var ratio: Double {
        guard amount > 0 else { return spent > 0 ? 1 : 0 }
        let decimalRatio = spent / amount
        return max(0, min(1, NSDecimalNumber(decimal: decimalRatio).doubleValue))
    }
}

enum BudgetProgressCalculator {
    static func progress(
        for budget: Budget,
        entries: [BudgetEntry],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> BudgetProgress {
        let interval = budget.period.interval(containing: referenceDate, calendar: calendar)
        return progress(for: budget, entries: entries, interval: interval)
    }

    static func progress(
        for budget: Budget,
        entries: [BudgetEntry],
        interval: DateInterval
    ) -> BudgetProgress {
        let spent = entries
            .filter { isSameBudget($0.budget, budget) && interval.containsHalfOpen($0.spentAt) }
            .reduce(Decimal.zero) { $0 + $1.amount }
        return BudgetProgress(budget: budget, spent: spent)
    }

    static func totalSpent(
        for period: BudgetPeriod,
        budgets: [Budget],
        entries: [BudgetEntry],
        referenceDate: Date = .now,
        calendar: Calendar = .current
    ) -> Decimal {
        let interval = period.interval(containing: referenceDate, calendar: calendar)
        return entries
            .filter { entry in
                guard let budget = entry.budget else { return false }
                return budget.period == period &&
                    budgets.contains(where: { isSameBudget($0, budget) }) &&
                    interval.containsHalfOpen(entry.spentAt)
            }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    private static func isSameBudget(_ lhs: Budget?, _ rhs: Budget) -> Bool {
        lhs?.persistentModelID == rhs.persistentModelID
    }
}

extension DateInterval {
    func containsHalfOpen(_ date: Date) -> Bool {
        date >= start && date < end
    }
}
