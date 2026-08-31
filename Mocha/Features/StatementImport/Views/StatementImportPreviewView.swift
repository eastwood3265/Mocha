import SwiftUI

struct StatementImportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let preview: StatementImportPreview
    let onImport: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section("导入摘要") {
                    LabeledContent("来源", value: preview.source.title)
                    LabeledContent("账单记录", value: "\(preview.totalRecordCount) 笔")
                    LabeledContent("将新增", value: "\(preview.newRecords.count) 笔")
                    LabeledContent("已存在", value: "\(preview.duplicateRecordCount) 笔")
                }

                Section("新增交易预览") {
                    if preview.newRecords.isEmpty {
                        ContentUnavailableView(
                            "没有新增交易",
                            systemImage: "checkmark.circle",
                            description: Text("文件中的交易均已导入。")
                        )
                    } else {
                        ForEach(preview.newRecords.prefix(50)) { transaction in
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(transaction.counterparty.isEmpty ? transaction.description : transaction.counterparty)
                                        .lineLimit(1)
                                    Text(transaction.occurredAt, format: .dateTime.year().month().day().hour().minute())
                                        .font(.caption)
                                        .foregroundStyle(MochaTheme.secondaryText)
                                }
                                Spacer()
                                Text(signedAmountText(for: transaction))
                                    .monospacedDigit()
                            }
                        }
                        if preview.newRecords.count > 50 {
                            Text("另有 \(preview.newRecords.count - 50) 笔未展示")
                                .font(.caption)
                                .foregroundStyle(MochaTheme.secondaryText)
                        }
                    }
                }
            }
            .navigationTitle("确认导入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("导入", action: onImport)
                        .disabled(preview.newRecords.isEmpty)
                }
            }
        }
    }

    private func signedAmountText(for transaction: ImportedTransaction) -> String {
        let prefix: String
        switch transaction.direction {
        case .income: prefix = "+"
        case .expense: prefix = "−"
        case .neutral: prefix = ""
        }
        return prefix + CurrencyFormatting.cny(transaction.amount)
    }
}
