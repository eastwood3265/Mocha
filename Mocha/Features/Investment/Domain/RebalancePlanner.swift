import Foundation
import SwiftData

enum RebalanceDirection: String, CaseIterable, Identifiable {
    case buy = "买入"
    case sell = "卖出"
    var id: Self { self }
}

struct RebalanceAllocation: Identifiable {
    let investment: Investment
    let amount: Decimal
    var id: PersistentIdentifier { investment.persistentModelID }

    func recurringDailyAmount(tradingDayCount: Int) -> Decimal? {
        guard investment.type != .cash else { return nil }
        return amount / Decimal(max(1, tradingDayCount))
    }
}

struct RebalancePlan {
    let direction: RebalanceDirection
    let requestedAmount: Decimal
    let allocatedAmount: Decimal
    let allocations: [RebalanceAllocation]
    let tradingDayCount: Int

    var unallocatedAmount: Decimal { requestedAmount - allocatedAmount }
}

enum RebalancePlanner {
    static func makePlan(
        investments: [Investment],
        selectedIDs: Set<PersistentIdentifier>,
        amount: Decimal,
        direction: RebalanceDirection,
        tradingDayCount: Int
    ) -> RebalancePlan {
        let selected = investments.filter { selectedIDs.contains($0.persistentModelID) }
        let portfolioValues = Dictionary(grouping: investments, by: \.type)
            .mapValues { $0.reduce(0) { $0 + $1.holdingAmount } }
        let selectedByType = Dictionary(grouping: selected, by: \.type)
        let eligibleTypes = Set(selectedByType.keys)
        let typeAmounts = allocateByType(
            portfolioValues: portfolioValues,
            eligibleTypes: eligibleTypes,
            amount: max(0, amount),
            direction: direction
        )

        var allocations: [RebalanceAllocation] = []
        for type in InvestmentType.allCases {
            guard let components = selectedByType[type], let typeAmount = typeAmounts[type], typeAmount > 0 else { continue }
            let componentAmounts = splitEqually(
                amount: typeAmount,
                components: components,
                direction: direction
            )
            for component in components {
                let componentAmount = componentAmounts[component.persistentModelID] ?? 0
                guard componentAmount > 0 else { continue }
                allocations.append(RebalanceAllocation(investment: component, amount: componentAmount))
            }
        }

        let allocated = allocations.reduce(0) { $0 + $1.amount }
        return RebalancePlan(
            direction: direction,
            requestedAmount: max(0, amount),
            allocatedAmount: allocated,
            allocations: allocations,
            tradingDayCount: max(1, tradingDayCount)
        )
    }

    private static func allocateByType(
        portfolioValues: [InvestmentType: Decimal],
        eligibleTypes: Set<InvestmentType>,
        amount: Decimal,
        direction: RebalanceDirection
    ) -> [InvestmentType: Decimal] {
        var result = Dictionary(uniqueKeysWithValues: eligibleTypes.map { ($0, Decimal.zero) })
        var remaining = amount
        guard !eligibleTypes.isEmpty else { return result }

        while remaining > 0 {
            let levels = eligibleTypes.map { type in
                let base = portfolioValues[type] ?? 0
                let delta = result[type] ?? 0
                return (type, direction == .buy ? base + delta : base - delta)
            }
            let boundary = direction == .buy
                ? levels.map(\.1).min()!
                : levels.map(\.1).max()!
            let boundaryTypes = levels.filter { $0.1 == boundary }.map(\.0)
            let nextLevel = direction == .buy
                ? levels.map(\.1).filter { $0 > boundary }.min()
                : levels.map(\.1).filter { $0 < boundary }.max()

            let capacityToNext: Decimal
            if let nextLevel {
                capacityToNext = abs(nextLevel - boundary) * Decimal(boundaryTypes.count)
            } else {
                capacityToNext = remaining
            }

            var step = min(remaining, capacityToNext)
            if direction == .sell {
                let available = boundaryTypes.reduce(Decimal.zero) { partial, type in
                    partial + max(0, (portfolioValues[type] ?? 0) - (result[type] ?? 0))
                }
                step = min(step, available)
            }
            guard step > 0 else { break }
            let share = step / Decimal(boundaryTypes.count)
            for type in boundaryTypes { result[type, default: 0] += share }
            remaining -= step
        }
        return result
    }

    private static func splitEqually(
        amount: Decimal,
        components: [Investment],
        direction: RebalanceDirection
    ) -> [PersistentIdentifier: Decimal] {
        var result = Dictionary(uniqueKeysWithValues: components.map { ($0.persistentModelID, Decimal.zero) })
        var active = components
        var remaining = amount

        while remaining > 0, !active.isEmpty {
            let share = remaining / Decimal(active.count)
            var distributed: Decimal = 0
            var nextActive: [Investment] = []
            for component in active {
                let capacity = direction == .sell
                    ? max(0, component.holdingAmount - (result[component.persistentModelID] ?? 0))
                    : share
                let value = min(share, capacity)
                result[component.persistentModelID, default: 0] += value
                distributed += value
                if direction == .buy || capacity > value { nextActive.append(component) }
            }
            guard distributed > 0 else { break }
            remaining -= distributed
            if direction == .buy { break }
            active = nextActive
        }
        return result
    }
}

enum TradingDayEstimator {
    static func remainingWeekdaysInCurrentMonth(
        from date: Date = .now,
        calendar: Calendar = .current,
        holidayDates: Set<String> = []
    ) -> Int {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else { return 1 }
        let start = calendar.startOfDay(for: date)
        var cursor = start
        var count = 0
        while cursor < monthInterval.end {
            let weekday = calendar.component(.weekday, from: cursor)
            let components = calendar.dateComponents([.year, .month, .day], from: cursor)
            let dateKey = String(
                format: "%04d-%02d-%02d",
                components.year ?? 0,
                components.month ?? 0,
                components.day ?? 0
            )
            if weekday != 1 && weekday != 7 && !holidayDates.contains(dateKey) { count += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
        }
        return max(1, count)
    }
}

actor HolidayCalendarService {
    static let shared = HolidayCalendarService()

    private struct Response: Decodable {
        let code: Int
        let holiday: [String: Entry]
    }

    private struct Entry: Decodable {
        let holiday: Bool
        let date: String
    }

    private let cacheLifetime: TimeInterval = 24 * 60 * 60

    func holidayDates(for year: Int) async throws -> Set<String> {
        let datesKey = "holiday-calendar-dates-\(year)"
        let timestampKey = "holiday-calendar-timestamp-\(year)"
        let defaults = UserDefaults.standard
        let timestamp = defaults.object(forKey: timestampKey) as? Date

        if let cachedDates = defaults.stringArray(forKey: datesKey),
           let timestamp,
           Date().timeIntervalSince(timestamp) < cacheLifetime {
            return Set(cachedDates)
        }

        guard let url = URL(string: "https://holiday.ailcc.com/api/holiday/year/\(year)") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadRevalidatingCacheData
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(Response.self, from: data)
        guard decoded.code == 0 else { throw URLError(.cannotParseResponse) }
        let dates = Set(decoded.holiday.values.filter(\.holiday).map(\.date))
        defaults.set(Array(dates), forKey: datesKey)
        defaults.set(Date(), forKey: timestampKey)
        return dates
    }
}
