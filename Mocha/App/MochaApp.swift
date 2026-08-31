import SwiftData
import SwiftUI

@main
struct MochaApp: App {
    private let container: ModelContainer = {
        do {
            return try ModelContainer(
                for: Investment.self,
                StorageLocation.self,
                Budget.self,
                BudgetEntry.self,
                SavingsBucket.self,
                SavingsBucketEntry.self,
                ImportBatch.self,
                FinancialTransaction.self
            )
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
    @AppStorage(AppThemeColor.storageKey) private var selectedThemeRawValue = AppThemeColor.lemon.rawValue
    @State private var selection: Tab = .investments

    var body: some View {
        TabView(selection: $selection) {
            InvestmentDashboardView()
                .tabItem { Label("投资", systemImage: "chart.pie.fill") }
                .tag(Tab.investments)

            StorageLocationListView()
                .tabItem { Label("存放处", systemImage: "building.columns.fill") }
                .tag(Tab.storageLocations)

            BudgetDashboardView()
                .tabItem { Label("预算", systemImage: "calendar.badge.clock") }
                .tag(Tab.budgets)

            GoldenBucketDashboardView()
                .tabItem { Label("金桶", systemImage: "banknote.fill") }
                .tag(Tab.goldenBuckets)

            SettingsDashboardView()
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
                .tag(Tab.settings)
        }
        .tint(MochaTheme.primaryText)
        .id(selectedThemeRawValue)
    }

    private enum Tab: Hashable {
        case investments
        case storageLocations
        case budgets
        case goldenBuckets
        case settings
    }
}
