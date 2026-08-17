import SwiftData
import SwiftUI

struct BudgetDetailView: View {
    let budget: Budget
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BudgetEntry.spentAt, order: .reverse) private var entries: [BudgetEntry]
    @State private var showingBudgetEditor = false
    @State private var showingEntryEditor = false
    @State private var entryScope: EntryScope = .currentPeriod

    private var progress: BudgetProgress {
        BudgetProgressCalculator.progress(for: budget, entries: entries)
    }

    private var scopedEntries: [BudgetEntry] {
        let owned = entries.filter { $0.budget?.persistentModelID == budget.persistentModelID }
        switch entryScope {
        case .currentPeriod:
            let interval = budget.period.interval()
            return owned.filter { interval.containsHalfOpen($0.spentAt) }
        case .all:
            return owned
        }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        metric("已用", CurrencyFormatting.cny(progress.spent))
                        Spacer()
                        metric("预算", CurrencyFormatting.cny(progress.amount), alignment: .trailing)
                    }
                    ProgressView(value: progress.ratio)
                        .tint(progress.isOverspent ? .red : MochaTheme.yellow)
                    metric(progress.isOverspent ? "超支" : "剩余", CurrencyFormatting.cny(abs(progress.remaining)))
                        .foregroundStyle(progress.isOverspent ? .red : MochaTheme.primaryText)
                }
                .padding(.vertical, 8)
            }

            Section {
                Picker("账目范围", selection: $entryScope) {
                    ForEach(EntryScope.allCases) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("支出明细") {
                if scopedEntries.isEmpty {
                    ContentUnavailableView("暂无支出", systemImage: "list.bullet.rectangle", description: Text("记录支出后会显示在这里。"))
                } else {
                    ForEach(scopedEntries) { entry in
                        BudgetEntryRow(entry: entry)
                            .swipeActions {
                                Button("删除", systemImage: "trash", role: .destructive) {
                                    modelContext.delete(entry)
                                }
                            }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(MochaTheme.background)
        .navigationTitle(budget.name)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !budget.isArchived {
                    Button("记账", systemImage: "square.and.pencil") { showingEntryEditor = true }
                }
                Button("编辑", systemImage: "pencil") { showingBudgetEditor = true }
            }
        }
        .sheet(isPresented: $showingBudgetEditor) { BudgetEditorView(budget: budget) }
        .sheet(isPresented: $showingEntryEditor) { BudgetEntryEditorView(preselectedBudget: budget) }
    }

    private func metric(_ title: String, _ value: String, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
    }
}

private enum EntryScope: String, CaseIterable, Identifiable {
    case currentPeriod
    case all

    var id: Self { self }

    var title: String {
        switch self {
        case .currentPeriod: "本周期"
        case .all: "全部"
        }
    }
}

private struct BudgetEntryRow: View {
    let entry: BudgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(entry.spentAt, format: .dateTime.year().month().day())
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(CurrencyFormatting.cny(entry.amount))
                    .font(.headline)
            }
            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}
