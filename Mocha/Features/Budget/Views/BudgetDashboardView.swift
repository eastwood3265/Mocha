import SwiftData
import SwiftUI

struct BudgetDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Budget.updatedAt, order: .reverse) private var budgets: [Budget]
    @Query(sort: \BudgetEntry.spentAt, order: .reverse) private var entries: [BudgetEntry]
    @State private var showingBudgetEditor = false
    @State private var showingEntryEditor = false
    @State private var showingArchivedBudgets = false

    private var activeBudgets: [Budget] {
        budgets.filter { !$0.isArchived }
    }

    private var monthlyBudgets: [Budget] {
        activeBudgets.filter { $0.period == .monthly }
    }

    private var yearlyBudgets: [Budget] {
        activeBudgets.filter { $0.period == .yearly }
    }

    private var monthlyAmount: Decimal {
        monthlyBudgets.reduce(.zero) { $0 + $1.amount }
    }

    private var yearlyAmount: Decimal {
        yearlyBudgets.reduce(.zero) { $0 + $1.amount }
    }

    private var monthlySpent: Decimal {
        BudgetProgressCalculator.totalSpent(for: .monthly, budgets: monthlyBudgets, entries: entries)
    }

    private var yearlySpent: Decimal {
        BudgetProgressCalculator.totalSpent(for: .yearly, budgets: yearlyBudgets, entries: entries)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    summaryGrid

                    if activeBudgets.isEmpty {
                        ContentUnavailableView("暂无预算", systemImage: "calendar.badge.plus", description: Text("创建预算后即可开始记录支出。"))
                            .padding(.top, 44)
                    } else {
                        ForEach(activeBudgets) { budget in
                            NavigationLink(value: budget) {
                                BudgetRow(progress: BudgetProgressCalculator.progress(for: budget, entries: entries))
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("归档预算", systemImage: "archivebox") {
                                    archive(budget)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(MochaTheme.background)
            .navigationTitle("预算")
            .navigationDestination(for: Budget.self) { BudgetDetailView(budget: $0) }
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("归档", systemImage: "archivebox") { showingArchivedBudgets = true }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("记账", systemImage: "square.and.pencil") { showingEntryEditor = true }
                        .disabled(activeBudgets.isEmpty)
                    Button("添加预算", systemImage: "plus") { showingBudgetEditor = true }
                }
            }
            .sheet(isPresented: $showingBudgetEditor) { BudgetEditorView() }
            .sheet(isPresented: $showingEntryEditor) { BudgetEntryEditorView() }
            .sheet(isPresented: $showingArchivedBudgets) { ArchivedBudgetListView() }
        }
        .tint(MochaTheme.primaryText)
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            BudgetSummaryCard(title: "本月预算", spent: monthlySpent, amount: monthlyAmount, systemImage: BudgetPeriod.monthly.systemImage)
            BudgetSummaryCard(title: "本年预算", spent: yearlySpent, amount: yearlyAmount, systemImage: BudgetPeriod.yearly.systemImage)
        }
    }

    private func archive(_ budget: Budget) {
        budget.isArchived = true
        budget.updatedAt = .now
    }
}
