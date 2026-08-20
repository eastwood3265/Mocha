import SwiftData
import SwiftUI

struct SavingsBucketEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavingsBucket.name) private var buckets: [SavingsBucket]
    @Query private var entries: [SavingsBucketEntry]
    @AppStorage(GoldenBucketSettings.negativeBalanceWarningKey) private var warningEnabled = true

    let preselectedBucket: SavingsBucket?
    let entry: SavingsBucketEntry?

    @State private var selectedBucket: SavingsBucket?
    @State private var type: SavingsBucketEntryType
    @State private var amount: Decimal
    @State private var occurredAt: Date
    @State private var note: String
    @State private var showingNegativeBalanceConfirmation = false

    init(preselectedBucket: SavingsBucket? = nil, entry: SavingsBucketEntry? = nil) {
        self.preselectedBucket = preselectedBucket
        self.entry = entry
        let initialBucket = entry?.bucket ?? preselectedBucket
        _selectedBucket = State(initialValue: initialBucket)
        _type = State(initialValue: entry?.type ?? .deposit)
        _amount = State(initialValue: entry?.amount ?? 0)
        _occurredAt = State(initialValue: entry?.occurredAt ?? .now)
        _note = State(initialValue: entry?.note ?? "")
    }

    private var availableBuckets: [SavingsBucket] {
        buckets.filter { !$0.isArchived }
    }

    private var isBucketSelectionLocked: Bool {
        preselectedBucket != nil || entry != nil
    }

    private var validationMessage: String? {
        if selectedBucket == nil { return "请选择金桶" }
        if amount <= 0 { return "流水金额必须大于 0" }
        return nil
    }

    private var projectedBalance: Decimal? {
        guard let selectedBucket else { return nil }
        let baseBalance = SavingsBucketProgressCalculator.balance(
            for: selectedBucket,
            entries: entries,
            excluding: entry
        )
        return baseBalance + type.signedAmount(amount)
    }

    private var currentBalance: Decimal? {
        guard let selectedBucket else { return nil }
        return SavingsBucketProgressCalculator.balance(for: selectedBucket, entries: entries)
    }

    private var shouldConfirmNegativeBalance: Bool {
        guard warningEnabled, let projectedBalance, let currentBalance else { return false }
        return projectedBalance < 0 && projectedBalance < currentBalance
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("流水") {
                    Picker("金桶", selection: $selectedBucket) {
                        Text("请选择").tag(nil as SavingsBucket?)
                        ForEach(availableBuckets) { bucket in
                            Text(bucket.name).tag(Optional(bucket))
                        }
                        if let selectedBucket, selectedBucket.isArchived {
                            Text("\(selectedBucket.name) · 已归档").tag(Optional(selectedBucket))
                        }
                    }
                    .disabled(isBucketSelectionLocked)

                    Picker("类型", selection: $type) {
                        ForEach(SavingsBucketEntryType.allCases) { entryType in
                            Label(entryType.title, systemImage: entryType.systemImage).tag(entryType)
                        }
                    }
                    .pickerStyle(.segmented)

                    DecimalField("金额", value: $amount)
                    DatePicker("日期", selection: $occurredAt, displayedComponents: .date)
                }

                Section("备注") {
                    LabeledNoteEditor(title: "备注", placeholder: "记录这笔存取说明", text: $note)
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
            .navigationTitle(entry == nil ? "记一笔" : "编辑流水")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: requestSave)
                        .disabled(validationMessage != nil)
                }
            }
            .alert("余额将低于 0", isPresented: $showingNegativeBalanceConfirmation) {
                Button("取消", role: .cancel) {}
                Button("继续保存", role: .destructive, action: save)
            } message: {
                if let selectedBucket, let projectedBalance {
                    Text("保存后「\(selectedBucket.name)」余额将为 \(CurrencyFormatting.cny(projectedBalance))。")
                }
            }
        }
    }

    private func requestSave() {
        if shouldConfirmNegativeBalance {
            showingNegativeBalanceConfirmation = true
        } else {
            save()
        }
    }

    private func save() {
        guard let selectedBucket else { return }
        let normalizedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let entry {
            entry.type = type
            entry.amount = amount
            entry.occurredAt = occurredAt
            entry.note = normalizedNote
            entry.updatedAt = .now
        } else {
            modelContext.insert(SavingsBucketEntry(
                bucket: selectedBucket,
                type: type,
                amount: amount,
                occurredAt: occurredAt,
                note: normalizedNote
            ))
        }
        selectedBucket.updatedAt = .now
        dismiss()
    }
}
