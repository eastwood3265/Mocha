import SwiftUI

struct StatementExportGuideView: View {
    var body: some View {
        List {
            Section {
                Text("请优先导出“用于个人对账”的结构化账单。不同版本的入口名称可能略有差异，但不要选择仅用于证明的 PDF，除非指引中明确支持。")
                    .font(.subheadline)
                    .foregroundStyle(MochaTheme.secondaryText)
            }

            ForEach(StatementExportGuide.allCases) { guide in
                Section {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(Array(guide.steps.enumerated()), id: \.offset) { index, step in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("\(index + 1)")
                                        .font(.caption.weight(.semibold))
                                        .frame(width: 22, height: 22)
                                        .background(MochaTheme.softYellow, in: Circle())
                                    Text(step)
                                        .font(.subheadline)
                                }
                            }

                            Divider()

                            LabeledContent("导出文件", value: guide.exportedFile)
                                .font(.subheadline)

                            Text(guide.notice)
                                .font(.caption)
                                .foregroundStyle(MochaTheme.secondaryText)
                        }
                        .padding(.vertical, 8)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: guide.systemImage)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(guide.title)
                                Text(guide.supportText)
                                    .font(.caption)
                                    .foregroundStyle(guide.isImportSupported ? .green : MochaTheme.secondaryText)
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(MochaTheme.background)
        .navigationTitle("账单导出指引")
    }
}

private enum StatementExportGuide: String, CaseIterable, Identifiable {
    case alipay
    case wechat
    case cmbDebit
    case cmbCredit

    var id: Self { self }

    var title: String {
        switch self {
        case .alipay: "支付宝"
        case .wechat: "微信支付"
        case .cmbDebit: "招商银行储蓄卡"
        case .cmbCredit: "招商银行信用卡"
        }
    }

    var systemImage: String {
        switch self {
        case .alipay: "a.circle.fill"
        case .wechat: "message.fill"
        case .cmbDebit, .cmbCredit: "building.columns.fill"
        }
    }

    var isImportSupported: Bool {
        switch self {
        case .alipay, .wechat: true
        case .cmbDebit, .cmbCredit: false
        }
    }

    var supportText: String {
        isImportSupported ? "当前支持 CSV 导入" : "暂未支持导入"
    }

    var exportedFile: String {
        switch self {
        case .alipay: "加密压缩包内的 CSV"
        case .wechat: "CSV 或 XLSX；当前仅支持 CSV"
        case .cmbDebit: "通常为带电子章的 PDF"
        case .cmbCredit: "电子账单或 PDF"
        }
    }

    var steps: [String] {
        switch self {
        case .alipay:
            [
                "打开支付宝，进入“我的 → 账单”。",
                "点击右上角更多按钮，选择“开具交易流水证明”。",
                "选择“用于个人对账”，不要选择仅用于证明材料的版本。",
                "选择时间范围并填写接收邮箱，然后按提示验证身份。",
                "从邮件下载压缩包，在支付宝申请记录中查看密码；解压后将 CSV 导入 Mocha。"
            ]
        case .wechat:
            [
                "打开微信，进入“我 → 服务 → 钱包 → 账单”。",
                "点击右上角“常见问题”或更多按钮，选择“下载账单”。",
                "选择“用于个人对账”。",
                "选择时间范围和接收方式，然后按提示验证身份。",
                "下载账单并解压；如果得到 CSV，可直接导入 Mocha。"
            ]
        case .cmbDebit:
            [
                "打开招商银行 App，在首页搜索“交易流水打印”。",
                "选择需要导出的储蓄账户和流水时间范围。",
                "填写接收邮箱并按提示完成身份验证。",
                "从邮件下载交易流水文件并妥善保存。"
            ]
        case .cmbCredit:
            [
                "打开招商银行 App 或掌上生活，进入信用卡账单页面。",
                "选择需要查看的月份，查找“电子账单”或发送至邮箱入口。",
                "按提示验证身份，并从邮箱下载账单文件。",
                "如果当前版本没有导出入口，可先开启信用卡电子账单服务。"
            ]
        }
    }

    var notice: String {
        switch self {
        case .alipay:
            "CSV 包含交易时间、交易对方、金额、收支方向和交易订单号，适合去重和记账。"
        case .wechat:
            "微信不同版本可能导出 CSV 或 XLSX。若得到 XLSX，请暂时另存为 CSV 后再导入。"
        case .cmbDebit:
            "Mocha 当前尚未解析招行 PDF；现在导出可用于备份，后续加入 PDF 解析后再导入。"
        case .cmbCredit:
            "电子账单格式可能随渠道变化。Mocha 当前尚未支持招行信用卡账单导入。"
        }
    }
}
