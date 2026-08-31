import SwiftData
import SwiftUI

struct BudgetEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Budget.name) private var budgets: [Budget]
    let preselectedBudget: Budget?
    let entry: BudgetEntry?

    @State private var selectedBudget: Budget?
    @State private var amount: Decimal
    @State private var spentAt: Date
    @State private var note: String

    init(preselectedBudget: Budget? = nil, entry: BudgetEntry? = nil) {
        self.preselectedBudget = preselectedBudget
        self.entry = entry
        _selectedBudget = State(initialValue: entry?.budget ?? preselectedBudget)
        _amount = State(initialValue: entry?.amount ?? 0)
        _spentAt = State(initialValue: entry?.spentAt ?? .now)
        _note = State(initialValue: entry?.note ?? "")
    }

    private var activeBudgets: [Budget] {
        budgets.filter { !$0.isArchived }
    }

    private var validationMessage: String? {
        if selectedBudget == nil { return "请选择预算" }
        if amount <= 0 { return "支出金额必须大于 0" }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("支出") {
                    Picker("预算", selection: $selectedBudget) {
                        Text("请选择").tag(nil as Budget?)
                        ForEach(activeBudgets) { budget in
                            Text("\(budget.name) · \(budget.period.title)").tag(Optional(budget))
                        }
                        if let selectedBudget, selectedBudget.isArchived {
                            Text("\(selectedBudget.name) · 已归档").tag(Optional(selectedBudget))
                        }
                    }
                    .disabled(preselectedBudget != nil || entry != nil)

                    AmountField("金额", value: $amount)
                    DatePicker("日期", selection: $spentAt, displayedComponents: .date)
                }

                Section("备注") {
                    LabeledNoteEditor(title: "备注", placeholder: "记录支出说明", text: $note)
                }

                if let validationMessage {
                    Section {
                        Text(validationMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MochaTheme.background)
            .navigationTitle(entry == nil ? "记一笔" : "编辑支出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(validationMessage != nil)
                }
            }
        }
    }

    private func save() {
        guard let selectedBudget else { return }
        let normalizedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let entry {
            entry.amount = amount
            entry.spentAt = spentAt
            entry.note = normalizedNote
            entry.updatedAt = .now
        } else {
            modelContext.insert(BudgetEntry(
                budget: selectedBudget,
                amount: amount,
                spentAt: spentAt,
                note: normalizedNote
            ))
        }
        selectedBudget.updatedAt = .now
        dismiss()
    }
}
