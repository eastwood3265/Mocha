import Foundation

enum BudgetPeriod: String, Codable, CaseIterable, Identifiable {
    case monthly = "月"
    case yearly = "年"

    var id: Self { self }

    var title: String { rawValue }

    var systemImage: String {
        switch self {
        case .monthly: "calendar"
        case .yearly: "calendar.badge.clock"
        }
    }

    func interval(containing date: Date = .now, calendar: Calendar = .current) -> DateInterval {
        switch self {
        case .monthly:
            guard let interval = calendar.dateInterval(of: .month, for: date) else {
                return fallbackInterval(containing: date, component: .month, calendar: calendar)
            }
            return interval
        case .yearly:
            guard let interval = calendar.dateInterval(of: .year, for: date) else {
                return fallbackInterval(containing: date, component: .year, calendar: calendar)
            }
            return interval
        }
    }

    private func fallbackInterval(containing date: Date, component: Calendar.Component, calendar: Calendar) -> DateInterval {
        let components: Set<Calendar.Component> = component == .month ? [.year, .month] : [.year]
        let startComponents = calendar.dateComponents(components, from: date)
        let start = calendar.date(from: startComponents) ?? date
        let end = calendar.date(byAdding: component, value: 1, to: start) ?? date
        return DateInterval(start: start, end: end)
    }
}
