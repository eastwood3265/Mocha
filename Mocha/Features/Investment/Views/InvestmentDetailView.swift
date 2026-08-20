import SwiftData
import SwiftUI

struct InvestmentDetailView: View {
    let investment: Investment
    @State private var showingEditor = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 14) {
                    if investment.type == .cash {
                        metric("持仓金额", CurrencyFormatting.cny(investment.holdingAmount))
                    } else {
                        HStack {
                            metric("持仓金额", CurrencyFormatting.cny(investment.holdingAmount))
                            Spacer()
                            metric("总盈亏", signed(investment.effectiveTotalProfit), alignment: .trailing)
                        }
                    }
                }
                .padding(.vertical, 8)
            }

            if let location = investment.storageLocation {
                Section("存放处") {
                    LabeledContent(location.name, value: [location.institution, location.accountAlias].filter { !$0.isEmpty }.joined(separator: " · "))
                }
            }

            if !investment.note.isEmpty {
                Section("备注") { Text(investment.note) }
            }
        }
        .scrollContentBackground(.hidden)
        .background(MochaTheme.background)
        .navigationTitle(investment.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { Button("编辑", systemImage: "pencil") { showingEditor = true } }
        }
        .sheet(isPresented: $showingEditor) { InvestmentEditorView(investment: investment) }
    }

    private func signed(_ value: Decimal) -> String { "\(value >= 0 ? "+" : "")\(CurrencyFormatting.cny(value))" }
    private func metric(_ title: String, _ value: String, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) { Text(title).font(.caption).foregroundStyle(.secondary); Text(value).font(.headline) }
    }
}
