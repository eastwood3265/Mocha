import SwiftData
import SwiftUI

struct ArchivedBudgetListView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Budget.updatedAt, order: .reverse) private var budgets: [Budget]
    @Query(sort: \BudgetEntry.spentAt, order: .reverse) private var entries: [BudgetEntry]

    private var archivedBudgets: [Budget] {
        budgets.filter(\.isArchived)
    }

    var body: some View {
        NavigationStack {
            List {
                if archivedBudgets.isEmpty {
                    ContentUnavailableView("暂无归档预算", systemImage: "archivebox", description: Text("归档后的预算会显示在这里。"))
                } else {
                    ForEach(archivedBudgets) { budget in
                        NavigationLink(value: budget) {
                            BudgetRow(progress: BudgetProgressCalculator.progress(for: budget, entries: entries))
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                        .swipeActions {
                            Button("恢复", systemImage: "arrow.uturn.backward") {
                                budget.isArchived = false
                                budget.updatedAt = .now
                            }
                            .tint(MochaTheme.yellow)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(MochaTheme.background)
            .navigationTitle("归档预算")
            .navigationDestination(for: Budget.self) { BudgetDetailView(budget: $0) }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .tint(MochaTheme.primaryText)
    }
}
