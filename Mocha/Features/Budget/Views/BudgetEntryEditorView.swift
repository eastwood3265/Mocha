import SwiftData
import SwiftUI

struct BudgetEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Budget.name) private var budgets: [Budget]
    let preselectedBudget: Budget?

    @State private var selectedBudget: Budget?
    @State private var amount: Decimal
    @State private var spentAt: Date
    @State private var note: String

    init(preselectedBudget: Budget? = nil) {
        self.preselectedBudget = preselectedBudget
        _selectedBudget = State(initialValue: preselectedBudget)
        _amount = State(initialValue: 0)
        _spentAt = State(initialValue: .now)
        _note = State(initialValue: "")
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
                    }
                    .disabled(preselectedBudget != nil)

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
            .navigationTitle("记一笔")
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
        modelContext.insert(BudgetEntry(
            budget: selectedBudget,
            amount: amount,
            spentAt: spentAt,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        dismiss()
    }
}
