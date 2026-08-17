import SwiftData
import SwiftUI

struct BudgetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Budget.name) private var budgets: [Budget]
    let budget: Budget?

    @State private var name: String
    @State private var amount: Decimal
    @State private var period: BudgetPeriod

    init(budget: Budget? = nil) {
        self.budget = budget
        _name = State(initialValue: budget?.name ?? "")
        _amount = State(initialValue: budget?.amount ?? 0)
        _period = State(initialValue: budget?.period ?? .monthly)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedName: String {
        trimmedName.lowercased()
    }

    private var shouldEnforceUniqueName: Bool {
        budget?.isArchived != true
    }

    private var hasDuplicateName: Bool {
        guard shouldEnforceUniqueName else { return false }
        return budgets.contains { candidate in
            candidate !== budget &&
                !candidate.isArchived &&
                candidate.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedName
        }
    }

    private var validationMessage: String? {
        if trimmedName.isEmpty { return "分类名称不能为空" }
        if amount < 0 { return "预算金额不能小于 0" }
        if hasDuplicateName { return "未归档预算中已存在同名分类" }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("预算") {
                    LabeledContent("分类名称") {
                        TextField("例如：餐饮", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                    Picker("周期", selection: $period) {
                        ForEach(BudgetPeriod.allCases) { period in
                            Label(period.title, systemImage: period.systemImage).tag(period)
                        }
                    }
                    DecimalField("金额", value: $amount)
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
            .navigationTitle(budget == nil ? "添加预算" : "编辑预算")
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
        if let budget {
            budget.name = trimmedName
            budget.amount = amount
            budget.period = period
            budget.updatedAt = .now
        } else {
            modelContext.insert(Budget(name: trimmedName, amount: amount, period: period))
        }
        dismiss()
    }
}
