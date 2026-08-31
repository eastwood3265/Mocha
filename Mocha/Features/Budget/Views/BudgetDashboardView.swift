import SwiftData
import SwiftUI

struct BudgetDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Budget.updatedAt, order: .reverse) private var budgets: [Budget]
    @Query(sort: \BudgetEntry.spentAt, order: .reverse) private var entries: [BudgetEntry]
    @State private var showingBudgetEditor = false
    @State private var showingEntryEditor = false
    @State private var showingArchivedBudgets = false
    @State private var displayMode: BudgetDisplayMode = .period
    @State private var selectedDate = Date.now

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
                    Picker("展示方式", selection: $displayMode) {
                        ForEach(BudgetDisplayMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.systemImage).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if displayMode == .period {
                        summaryGrid
                    } else {
                        dailyHeader
                    }

                    if activeBudgets.isEmpty {
                        ContentUnavailableView {
                            Label("暂无预算", systemImage: "calendar.badge.plus")
                        } description: {
                            Text("先创建预算，再记录日常支出。")
                        } actions: {
                            Button("创建预算", systemImage: "plus") { showingBudgetEditor = true }
                                .buttonStyle(.borderedProminent)
                        }
                            .padding(.top, 44)
                    } else {
                        ForEach(activeBudgets) { budget in
                            NavigationLink(value: budget) {
                                if displayMode == .period {
                                    BudgetRow(progress: BudgetProgressCalculator.progress(for: budget, entries: entries))
                                } else {
                                    DailyBudgetRow(
                                        budget: budget,
                                        spent: BudgetProgressCalculator.spent(
                                            for: budget,
                                            on: selectedDate,
                                            entries: entries
                                        ),
                                        entryCount: dailyEntryCount(for: budget)
                                    )
                                }
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

    private var dailyHeader: some View {
        VStack(spacing: 12) {
            DatePicker("查看日期", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.compact)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Calendar.current.isDateInToday(selectedDate) ? "今日支出" : "当日支出")
                        .font(.subheadline)
                        .foregroundStyle(MochaTheme.secondaryText)
                    Text(CurrencyFormatting.cny(dailySpent))
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(MochaTheme.primaryText)
                }
                Spacer()
                Image(systemName: "calendar.day.timeline.left")
                    .font(.title2)
                    .foregroundStyle(MochaTheme.themeForeground)
                    .frame(width: 44, height: 44)
                    .background(MochaTheme.yellow, in: Circle())
            }
        }
        .padding()
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var dailySpent: Decimal {
        activeBudgets.reduce(.zero) {
            $0 + BudgetProgressCalculator.spent(for: $1, on: selectedDate, entries: entries)
        }
    }

    private func dailyEntryCount(for budget: Budget) -> Int {
        guard let interval = Calendar.current.dateInterval(of: .day, for: selectedDate) else { return 0 }
        return entries.filter {
            $0.budget?.persistentModelID == budget.persistentModelID && interval.containsHalfOpen($0.spentAt)
        }.count
    }

    private func archive(_ budget: Budget) {
        budget.isArchived = true
        budget.updatedAt = .now
    }
}

private enum BudgetDisplayMode: String, CaseIterable, Identifiable {
    case period
    case day

    var id: Self { self }
    var title: String { self == .period ? "周期" : "日" }
    var systemImage: String { self == .period ? "chart.bar" : "calendar.day.timeline.left" }
}

private struct DailyBudgetRow: View {
    let budget: Budget
    let spent: Decimal
    let entryCount: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: budget.period.systemImage)
                .font(.headline)
                .foregroundStyle(MochaTheme.themeForeground)
                .frame(width: 38, height: 38)
                .background(MochaTheme.yellow, in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(budget.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(MochaTheme.primaryText)
                    .lineLimit(2)
                Text("\(budget.period.title)预算 · \(entryCount) 笔")
                    .font(.caption)
                    .foregroundStyle(MochaTheme.secondaryText)
            }

            Spacer()

            Text(CurrencyFormatting.cny(spent))
                .font(.headline.weight(.semibold))
                .foregroundStyle(MochaTheme.primaryText)
        }
        .padding()
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(MochaTheme.yellow.opacity(0.2), lineWidth: 1)
        }
    }
}
