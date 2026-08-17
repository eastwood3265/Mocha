import SwiftData
import SwiftUI

@main
struct MochaApp: App {
    private let container: ModelContainer = {
        do {
            return try ModelContainer(for: Investment.self, StorageLocation.self, Budget.self, BudgetEntry.self)
        } catch {
            fatalError("无法创建本地数据库：\(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MochaRootView()
                .preferredColorScheme(.light)
                .foregroundStyle(MochaTheme.primaryText)
        }
        .modelContainer(container)
    }
}

private struct MochaRootView: View {
    @State private var selection: Tab = .investments

    var body: some View {
        TabView(selection: $selection) {
            InvestmentDashboardView()
                .tabItem { Label("投资项", systemImage: "chart.pie.fill") }
                .tag(Tab.investments)

            StorageLocationListView()
                .tabItem { Label("存放处", systemImage: "building.columns.fill") }
                .tag(Tab.storageLocations)

            BudgetDashboardView()
                .tabItem { Label("预算", systemImage: "calendar.badge.clock") }
                .tag(Tab.budgets)
        }
        .tint(MochaTheme.primaryText)
    }

    private enum Tab: Hashable {
        case investments
        case storageLocations
        case budgets
    }
}
