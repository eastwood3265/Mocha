import SwiftData
import SwiftUI

struct InvestmentSnapshotPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Investment.name) private var investments: [Investment]
    @Query(sort: \StorageLocation.name) private var locations: [StorageLocation]
    let preview: InvestmentSnapshotImportPreview
    let onImport: ([InvestmentSnapshotImportDraft]) -> Void
    @State private var drafts: [InvestmentSnapshotImportDraft]
    @State private var didAssignLocationMatches = false

    init(
        preview: InvestmentSnapshotImportPreview,
        onImport: @escaping ([InvestmentSnapshotImportDraft]) -> Void
    ) {
        self.preview = preview
        self.onImport = onImport
        _drafts = State(initialValue: preview.defaultDrafts)
    }

    private var createCount: Int { drafts.filter { $0.action == .create }.count }
    private var updateCount: Int { drafts.filter { $0.action == .update }.count }
    private var duplicateTargetIDs: Set<PersistentIdentifier> {
        let ids = drafts.filter { $0.action == .update }.compactMap { $0.targetInvestment?.persistentModelID }
        return Set(ids.filter { id in ids.filter { $0 == id }.count > 1 })
    }
    private var hasInvalidDraft: Bool {
        drafts.contains { draft in
            switch draft.action {
            case .create:
                draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.holdingAmount < 0
            case .update:
                draft.targetInvestment == nil ||
                    (draft.targetInvestment.map { duplicateTargetIDs.contains($0.persistentModelID) } ?? false)
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("导入摘要") {
                    LabeledContent("新建", value: "\(createCount) 项")
                    LabeledContent("更新已有", value: "\(updateCount) 项")
                }

                Section {
                    ForEach($drafts) { $draft in
                        NavigationLink {
                            InvestmentSnapshotDraftEditor(
                                draft: $draft,
                                investments: investments.filter { $0.type != .cash },
                                locations: locations,
                                targetIsDuplicated: draft.targetInvestment.map {
                                    duplicateTargetIDs.contains($0.persistentModelID)
                                } ?? false
                            )
                        } label: {
                            draftRow(draft)
                        }
                    }
                } header: {
                    Text("逐项配置")
                } footer: {
                    Text("每条记录默认新建。点按记录可修改新基金配置，或选择一个已有基金并用导入数据覆盖。")
                }
            }
            .navigationTitle("确认持仓快照")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导入") { onImport(drafts) }
                        .disabled(drafts.isEmpty || hasInvalidDraft)
                }
            }
            .task { assignExactLocationMatches() }
        }
    }

    private func assignExactLocationMatches() {
        guard !didAssignLocationMatches else { return }
        didAssignLocationMatches = true
        for index in drafts.indices where drafts[index].action == .create && drafts[index].storageLocation == nil {
            let account = ImportedInvestmentSnapshot.normalize(drafts[index].snapshot.accountAlias)
            guard !account.isEmpty else { continue }
            let matches = locations.filter { location in
                [location.name, location.institution, location.accountAlias]
                    .map(ImportedInvestmentSnapshot.normalize)
                    .contains(account)
            }
            if matches.count == 1 {
                drafts[index].storageLocation = matches[0]
            }
        }
    }

    private func draftRow(_ draft: InvestmentSnapshotImportDraft) -> some View {
        HStack(spacing: 12) {
            Image(systemName: draft.action == .create ? "plus.circle.fill" : "arrow.triangle.2.circlepath.circle.fill")
                .foregroundStyle(MochaTheme.yellow)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(draft.snapshot.fundName)
                Text([draft.snapshot.fundCode, draft.snapshot.assetClass.rawValue]
                    .filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(MochaTheme.secondaryText)
                if !draft.snapshot.accountAlias.isEmpty {
                    Text("来源账户：\(draft.snapshot.accountAlias)")
                        .font(.caption)
                        .foregroundStyle(MochaTheme.secondaryText)
                }
                if draft.action == .update {
                    Text(draft.targetInvestment.map { "覆盖：\($0.name)" } ?? "请选择已有基金")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(draft.targetInvestment == nil ? .red : MochaTheme.secondaryText)
                } else if let location = draft.storageLocation {
                    Text("存放处：\(location.name)")
                        .font(.caption)
                        .foregroundStyle(MochaTheme.secondaryText)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatting.cny(draft.snapshot.marketValue)).monospacedDigit()
                Text(draft.action.rawValue).font(.caption).foregroundStyle(MochaTheme.secondaryText)
            }
        }
    }
}

private struct InvestmentSnapshotDraftEditor: View {
    @Binding var draft: InvestmentSnapshotImportDraft
    let investments: [Investment]
    let locations: [StorageLocation]
    let targetIsDuplicated: Bool

    var body: some View {
        Form {
            Section("导入方式") {
                Picker("处理方式", selection: $draft.action) {
                    ForEach(InvestmentSnapshotImportAction.allCases) { action in
                        Text(action.rawValue).tag(action)
                    }
                }
                .pickerStyle(.segmented)
            }

            if draft.action == .create {
                createForm
            } else {
                updateForm
            }

            Section("导入来源") {
                LabeledContent("基金名称", value: draft.snapshot.fundName)
                LabeledContent("基金代码", value: draft.snapshot.fundCode)
                LabeledContent("持仓金额", value: CurrencyFormatting.cny(draft.snapshot.marketValue))
                LabeledContent("快照日期") {
                    Text(draft.snapshot.snapshotAt, format: .dateTime.year().month().day())
                }
                if !draft.snapshot.accountAlias.isEmpty {
                    LabeledContent("销售渠道", value: draft.snapshot.accountAlias)
                }
            }
        }
        .navigationTitle("配置导入")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var createForm: some View {
        Section("新基金配置") {
            LabeledContent("名称") {
                TextField("基金名称", text: $draft.name).multilineTextAlignment(.trailing)
            }
            Picker("类型", selection: $draft.type) {
                ForEach(InvestmentType.allCases) { type in
                    Label(type.rawValue, systemImage: type.icon).tag(type)
                }
            }
            if draft.type != .cash {
                LabeledContent("代码") {
                    TextField("可选", text: $draft.code)
                        .textInputAutocapitalization(.characters)
                        .multilineTextAlignment(.trailing)
                }
            }
            Picker("存放处", selection: $draft.storageLocation) {
                Text("未指定").tag(nil as StorageLocation?)
                ForEach(locations) { location in
                    Text(location.name).tag(Optional(location))
                }
            }
            AmountField("持仓金额", value: $draft.holdingAmount)
            if draft.type != .cash {
                AmountField("总盈亏", value: $draft.totalProfit, allowsNegative: true)
            }
            LabeledNoteEditor(title: "备注", placeholder: "记录投资计划或补充说明", text: $draft.note)
        }
    }

    private var updateForm: some View {
        Section {
            Picker("已有基金", selection: $draft.targetInvestment) {
                Text("请选择").tag(nil as Investment?)
                ForEach(investments) { investment in
                    Text(investmentTitle(investment)).tag(Optional(investment))
                }
            }
            if investments.isEmpty {
                Text("当前没有可更新的已有基金。")
                    .font(.caption)
                    .foregroundStyle(MochaTheme.secondaryText)
            } else if targetIsDuplicated {
                Text("该基金已被另一条导入记录选择，请选择其他基金。")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        } header: {
            Text("更新目标")
        } footer: {
            Text("确认导入后，名称、代码、类型、持仓金额、可用盈亏和快照日期会被本条导入数据覆盖；已有存放处和备注保留。")
        }
    }

    private func investmentTitle(_ investment: Investment) -> String {
        [investment.name, investment.code].filter { !$0.isEmpty }.joined(separator: " · ")
    }
}
