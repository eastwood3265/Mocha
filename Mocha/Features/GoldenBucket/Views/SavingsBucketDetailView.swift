import SwiftData
import SwiftUI

struct SavingsBucketDetailView: View {
    let bucket: SavingsBucket
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavingsBucketEntry.occurredAt, order: .reverse) private var entries: [SavingsBucketEntry]
    @AppStorage(GoldenBucketSettings.negativeBalanceWarningKey) private var warningEnabled = true
    @State private var showingBucketEditor = false
    @State private var showingEntryEditor = false
    @State private var editingEntry: SavingsBucketEntry?
    @State private var pendingDeletion: SavingsBucketEntry?
    @State private var showingNegativeDeleteConfirmation = false

    private var ownedEntries: [SavingsBucketEntry] {
        entries.filter { SavingsBucketProgressCalculator.belongs($0, to: bucket) }
    }

    private var progress: SavingsBucketProgress {
        SavingsBucketProgressCalculator.progress(for: bucket, entries: entries)
    }

    var body: some View {
        List {
            Section {
                progressContent
                    .padding(.vertical, 8)
            }

            if let deadline = bucket.deadline {
                Section("计划") {
                    LabeledContent("截止日期") {
                        Text(deadline, format: .dateTime.year().month().day())
                    }
                    if progress.isDeadlineExpired() && !progress.isCompleted {
                        LabeledContent("攒钱节奏", value: "目标已到期")
                            .foregroundStyle(.red)
                    } else if let dailySaving = progress.suggestedDailySaving() {
                        LabeledContent("建议每日存入", value: CurrencyFormatting.cny(dailySaving))
                    }
                }
            }

            if !bucket.note.isEmpty {
                Section("备注") {
                    Text(bucket.note)
                }
            }

            Section("流水") {
                if ownedEntries.isEmpty {
                    ContentUnavailableView(
                        "暂无流水",
                        systemImage: "list.bullet.rectangle",
                        description: Text(bucket.isArchived ? "这个金桶没有历史流水。" : "存入或取出后会显示在这里。")
                    )
                } else {
                    ForEach(ownedEntries) { entry in
                        Button {
                            editingEntry = entry
                        } label: {
                            SavingsBucketEntryRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button("删除", systemImage: "trash", role: .destructive) {
                                requestDelete(entry)
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(MochaTheme.background)
        .navigationTitle(bucket.name)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !bucket.isArchived {
                    Button("记流水", systemImage: "square.and.pencil") {
                        showingEntryEditor = true
                    }
                }
                Menu {
                    Button("编辑金桶", systemImage: "pencil") {
                        showingBucketEditor = true
                    }
                    if !bucket.isArchived {
                        Button("归档金桶", systemImage: "archivebox") {
                            bucket.isArchived = true
                            bucket.updatedAt = .now
                        }
                    }
                } label: {
                    Label("更多", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingBucketEditor) { SavingsBucketEditorView(bucket: bucket) }
        .sheet(isPresented: $showingEntryEditor) { SavingsBucketEntryEditorView(preselectedBucket: bucket) }
        .sheet(item: $editingEntry) { entry in
            SavingsBucketEntryEditorView(entry: entry)
        }
        .alert("余额将低于 0", isPresented: $showingNegativeDeleteConfirmation) {
            Button("取消", role: .cancel) { pendingDeletion = nil }
            Button("继续删除", role: .destructive) {
                if let pendingDeletion { delete(pendingDeletion) }
            }
        } message: {
            if let pendingDeletion {
                let projectedBalance = SavingsBucketProgressCalculator.balance(
                    for: bucket,
                    entries: entries,
                    excluding: pendingDeletion
                )
                Text("删除后「\(bucket.name)」余额将为 \(CurrencyFormatting.cny(projectedBalance))。")
            }
        }
    }

    @ViewBuilder
    private var progressContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                metric("当前余额", CurrencyFormatting.cny(progress.balance), isNegative: progress.isNegative)
                Spacer()
                if let targetAmount = progress.targetAmount {
                    metric("目标金额", CurrencyFormatting.cny(targetAmount), alignment: .trailing)
                } else {
                    metric("目标金额", "未设置", alignment: .trailing)
                }
            }

            if let ratio = progress.ratio {
                ProgressView(value: ratio)
                    .tint(progress.isNegative ? .red : MochaTheme.yellow)
                HStack {
                    Text(progress.isCompleted ? "目标已完成" : "还差 \(CurrencyFormatting.cny(progress.remainingAmount ?? 0))")
                    Spacer()
                    Text(ratio.formatted(.percent.precision(.fractionLength(0))))
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(progress.isNegative ? .red : .secondary)
            } else if progress.isNegative {
                Text("当前余额为负数")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
    }

    private func metric(
        _ title: String,
        _ value: String,
        alignment: HorizontalAlignment = .leading,
        isNegative: Bool = false
    ) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(isNegative ? .red : MochaTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }

    private func requestDelete(_ entry: SavingsBucketEntry) {
        let projectedBalance = SavingsBucketProgressCalculator.balance(
            for: bucket,
            entries: entries,
            excluding: entry
        )
        if warningEnabled && projectedBalance < 0 && projectedBalance < progress.balance {
            pendingDeletion = entry
            showingNegativeDeleteConfirmation = true
        } else {
            delete(entry)
        }
    }

    private func delete(_ entry: SavingsBucketEntry) {
        modelContext.delete(entry)
        bucket.updatedAt = .now
        pendingDeletion = nil
    }
}

private struct SavingsBucketEntryRow: View {
    let entry: SavingsBucketEntry

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.type.systemImage)
                .font(.title3)
                .foregroundStyle(entry.type == .deposit ? MochaTheme.yellow : .red)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.type.title)
                    .font(.subheadline.weight(.medium))
                Text(entry.occurredAt, format: .dateTime.year().month().day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !entry.note.isEmpty {
                    Text(entry.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text("\(entry.type == .deposit ? "+" : "-")\(CurrencyFormatting.cny(entry.amount))")
                .font(.headline)
                .foregroundStyle(entry.type == .deposit ? MochaTheme.primaryText : .red)
        }
        .padding(.vertical, 4)
    }
}
