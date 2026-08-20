import SwiftData
import SwiftUI

struct SavingsBucketEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavingsBucket.name) private var buckets: [SavingsBucket]
    let bucket: SavingsBucket?

    @State private var name: String
    @State private var initialDeposit: Decimal
    @State private var hasTarget: Bool
    @State private var targetAmount: Decimal
    @State private var hasDeadline: Bool
    @State private var deadline: Date
    @State private var note: String

    init(bucket: SavingsBucket? = nil) {
        self.bucket = bucket
        _name = State(initialValue: bucket?.name ?? "")
        _initialDeposit = State(initialValue: 0)
        _hasTarget = State(initialValue: bucket?.targetAmount != nil)
        _targetAmount = State(initialValue: bucket?.targetAmount ?? 0)
        _hasDeadline = State(initialValue: bucket?.deadline != nil)
        _deadline = State(initialValue: bucket?.deadline ?? .now)
        _note = State(initialValue: bucket?.note ?? "")
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasDuplicateName: Bool {
        let normalizedName = trimmedName.lowercased()
        return buckets.contains { candidate in
            candidate.persistentModelID != bucket?.persistentModelID &&
                !candidate.isArchived &&
                candidate.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedName
        }
    }

    private var validationMessage: String? {
        if trimmedName.isEmpty { return "名称不能为空" }
        if initialDeposit < 0 { return "初始存入不能小于 0" }
        if hasTarget && targetAmount <= 0 { return "目标金额必须大于 0" }
        if hasDuplicateName { return "未归档金桶中已存在同名目标" }
        return nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("金桶") {
                    LabeledContent("名称") {
                        TextField("例如：旅行基金", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                    if bucket == nil {
                        DecimalField("初始存入", value: $initialDeposit)
                    }
                }

                Section("攒钱目标") {
                    Toggle("设置目标金额", isOn: $hasTarget)
                        .tint(MochaTheme.yellow)
                    if hasTarget {
                        DecimalField("目标金额", value: $targetAmount)
                        Toggle("设置截止日期", isOn: $hasDeadline)
                            .tint(MochaTheme.yellow)
                        if hasDeadline {
                            DatePicker("截止日期", selection: $deadline, displayedComponents: .date)
                        }
                    }
                }

                Section("备注") {
                    LabeledNoteEditor(title: "备注", placeholder: "记录攒钱用途或计划", text: $note)
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
            .navigationTitle(bucket == nil ? "添加金桶" : "编辑金桶")
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
        let normalizedTarget = hasTarget ? targetAmount : nil
        let normalizedDeadline = hasTarget && hasDeadline ? deadline : nil
        let normalizedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let bucket {
            bucket.name = trimmedName
            bucket.targetAmount = normalizedTarget
            bucket.deadline = normalizedDeadline
            bucket.note = normalizedNote
            bucket.updatedAt = .now
        } else {
            let newBucket = SavingsBucket(
                name: trimmedName,
                targetAmount: normalizedTarget,
                deadline: normalizedDeadline,
                note: normalizedNote
            )
            modelContext.insert(newBucket)
            if initialDeposit > 0 {
                modelContext.insert(SavingsBucketEntry(
                    bucket: newBucket,
                    type: .deposit,
                    amount: initialDeposit,
                    note: "初始存入"
                ))
            }
        }
        dismiss()
    }
}
