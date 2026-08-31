import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct InvestmentSnapshotImportView: View {
    let pendingImport: PendingInvestmentImport?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImportBatch.importedAt, order: .reverse) private var allBatches: [ImportBatch]
    @State private var isSelectingFile = false
    @State private var preview: InvestmentSnapshotImportPreview?
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var didLoadPendingImport = false

    init(pendingImport: PendingInvestmentImport? = nil) {
        self.pendingImport = pendingImport
    }

    private var investmentBatches: [ImportBatch] {
        allBatches.filter { $0.domain == .investment }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        isSelectingFile = true
                    } label: {
                        Label("选择持仓文件", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("导入")
                } footer: {
                    Text("选择文件后逐条决定新建或更新；新建基金时可按需选择存放处。")
                }

                Section("基金 E 账户导出") {
                    Text("基金 E 账户 → 公募基金查询 → 所有基金 → 导出 → 发送到邮箱，然后直接选择邮件中的 XLSX 文件。")
                        .font(.callout)
                    Text("债券、货币和黄金基金按名称分类，其余基金暂归入股票；导入后可在投资项中调整分类。")
                        .font(.caption)
                        .foregroundStyle(MochaTheme.secondaryText)
                }

                Section("CSV 示例") {
                    Text("快照日期,平台,账户,基金代码,基金名称,资产类别,持仓金额,总盈亏,收益口径,产品ID")
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                    Text("2026-08-25,腾讯理财通,长期账户,110022,易方达消费行业,股票,12500.00,850.00,持有收益,")
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }

                if !investmentBatches.isEmpty {
                    Section("最近导入") {
                        ForEach(investmentBatches.prefix(10)) { batch in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sourceTitle(batch.sourceIdentifier))
                                    .font(.headline)
                                Text("新增 \(batch.insertedRecordCount) · 更新 \(batch.updatedRecordCount) · 未变更 \(batch.duplicateRecordCount)")
                                    .font(.caption)
                                    .foregroundStyle(MochaTheme.secondaryText)
                                Text(batch.importedAt, format: .dateTime.year().month().day().hour().minute())
                                    .font(.caption2)
                                    .foregroundStyle(MochaTheme.secondaryText)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MochaTheme.background)
            .navigationTitle("导入持仓快照")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .fileImporter(
            isPresented: $isSelectingFile,
            allowedContentTypes: [.commaSeparatedText, .plainText, .spreadsheet],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { loadPreview(from: url) }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .sheet(item: $preview) { preview in
            InvestmentSnapshotPreviewView(preview: preview) { drafts in
                commit(preview, drafts: drafts)
            }
        }
        .alert("无法导入", isPresented: errorAlertBinding) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "未知错误")
        }
        .alert("导入完成", isPresented: successAlertBinding) {
            Button("完成", role: .cancel) {}
        } message: {
            Text(successMessage ?? "")
        }
        .task {
            loadPendingImportIfNeeded()
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private var successAlertBinding: Binding<Bool> {
        Binding(get: { successMessage != nil }, set: { if !$0 { successMessage = nil } })
    }

    private func loadPreview(from url: URL) {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
        do {
            let fileName = url.lastPathComponent
            try loadPreview(data: Data(contentsOf: url), fileName: fileName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadPendingImportIfNeeded() {
        guard !didLoadPendingImport, let pendingImport else { return }
        didLoadPendingImport = true
        do {
            try loadPreview(data: pendingImport.data, fileName: pendingImport.fileName)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadPreview(data: Data, fileName: String) throws {
        preview = try InvestmentSnapshotImportService().preview(
            data: data,
            fileName: fileName
        )
    }

    private func commit(
        _ preview: InvestmentSnapshotImportPreview,
        drafts: [InvestmentSnapshotImportDraft]
    ) {
        do {
            let batch = try InvestmentSnapshotImportService().commit(preview, drafts: drafts, context: modelContext)
            self.preview = nil
            successMessage = "新增 \(batch.insertedRecordCount) 项，更新 \(batch.updatedRecordCount) 项。"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sourceTitle(_ identifier: String) -> String {
        switch identifier {
        case "investment.tencent-licaitong": "腾讯理财通"
        case "investment.ant-wealth": "蚂蚁财富"
        case "investment.efunds": "易方达"
        case "investment.fund-e-account": "基金 E 账户"
        case "investment.mixed": "多个平台"
        default: identifier
        }
    }
}
