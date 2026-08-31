import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct StatementImportDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ImportBatch.importedAt, order: .reverse) private var batches: [ImportBatch]
    @State private var isSelectingFile = false
    @State private var preview: StatementImportPreview?
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private var paymentBatches: [ImportBatch] {
        batches.filter { $0.domain == .payment }
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    StatementExportGuideView()
                } label: {
                    Label("查看账单导出指引", systemImage: "questionmark.circle")
                }
            }

            Section {
                Button {
                    isSelectingFile = true
                } label: {
                    Label("选择账单文件", systemImage: "square.and.arrow.down")
                }
            } footer: {
                Text("支持支付宝和微信支付导出的 CSV 个人对账账单。文件只在本机解析。")
            }

            if paymentBatches.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("尚未导入账单", systemImage: "doc.text.magnifyingglass")
                    } description: {
                        Text("从支付宝或微信导出个人对账账单后，在这里选择 CSV 文件。")
                    } actions: {
                        Button("选择账单文件", systemImage: "square.and.arrow.down") {
                            isSelectingFile = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                Section("导入历史") {
                    ForEach(paymentBatches) { batch in
                        ImportBatchRow(batch: batch)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(MochaTheme.background)
        .navigationTitle("账单导入")
        .fileImporter(
            isPresented: $isSelectingFile,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                loadPreview(from: url)
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .sheet(item: $preview) { preview in
            StatementImportPreviewView(preview: preview) {
                commit(preview)
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
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private var successAlertBinding: Binding<Bool> {
        Binding(
            get: { successMessage != nil },
            set: { if !$0 { successMessage = nil } }
        )
    }

    private func loadPreview(from url: URL) {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { url.stopAccessingSecurityScopedResource() }
        }
        do {
            let data = try Data(contentsOf: url)
            preview = try StatementImportService().preview(
                data: data,
                fileName: url.lastPathComponent,
                context: modelContext
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func commit(_ preview: StatementImportPreview) {
        do {
            try StatementImportService().commit(preview, context: modelContext)
            self.preview = nil
            successMessage = "新增 \(preview.newRecords.count) 笔，跳过 \(preview.duplicateRecordCount) 笔重复交易。"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ImportBatchRow: View {
    let batch: ImportBatch

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: batch.paymentSource == .alipay ? "a.circle.fill" : "message.fill")
                .font(.title3)
                .foregroundStyle(MochaTheme.primaryText)
            VStack(alignment: .leading, spacing: 4) {
                Text(batch.paymentSource?.title ?? batch.sourceIdentifier)
                    .font(.headline)
                Text(batch.fileName)
                    .font(.caption)
                    .foregroundStyle(MochaTheme.secondaryText)
                    .lineLimit(1)
                Text(batch.importedAt, format: .dateTime.year().month().day().hour().minute())
                    .font(.caption2)
                    .foregroundStyle(MochaTheme.secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text("新增 \(batch.insertedRecordCount)")
                if batch.duplicateRecordCount > 0 {
                    Text("重复 \(batch.duplicateRecordCount)")
                        .foregroundStyle(MochaTheme.secondaryText)
                }
            }
            .font(.caption)
        }
    }
}

extension StatementImportPreview: Identifiable {
    var id: String { fileFingerprint }
}
