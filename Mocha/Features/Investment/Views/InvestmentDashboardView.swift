import SwiftData
import SwiftUI

struct InvestmentDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Investment.updatedAt, order: .reverse) private var investments: [Investment]
    @State private var selectedType: InvestmentType?
    @State private var showingInvestmentEditor = false
    @State private var showingRebalance = false

    private var filtered: [Investment] {
        guard let selectedType else { return investments }
        return investments.filter { $0.type == selectedType }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14) {
                    PortfolioSummaryCard(summary: PortfolioSummary(investments: investments))
                    typeFilter

                    if filtered.isEmpty {
                        ContentUnavailableView("暂无持仓", systemImage: "tray", description: Text("添加投资项并记录当前持仓快照。"))
                            .padding(.top, 44)
                    } else {
                        ForEach(filtered) { investment in
                            NavigationLink(value: investment) {
                                InvestmentRow(investment: investment)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("删除投资项", systemImage: "trash", role: .destructive) {
                                    modelContext.delete(investment)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background(MochaTheme.background)
            .navigationTitle("投资项")
            .navigationDestination(for: Investment.self) { InvestmentDetailView(investment: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("再平衡", systemImage: "scale.3d") { showingRebalance = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("添加投资", systemImage: "plus") { showingInvestmentEditor = true }
                }
            }
            .sheet(isPresented: $showingInvestmentEditor) { InvestmentEditorView() }
            .sheet(isPresented: $showingRebalance) { RebalanceView(investments: investments) }
        }
        .tint(MochaTheme.primaryText)
    }

    private var typeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                FilterChip(title: "全部", icon: nil, selected: selectedType == nil) { selectedType = nil }
                ForEach(InvestmentType.allCases) { type in
                    FilterChip(title: type.rawValue, icon: type.icon, selected: selectedType == type) { selectedType = type }
                }
            }
        }
    }
}

private struct FilterChip: View {
    let title: String
    let icon: String?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon { Image(systemName: icon) }
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14).padding(.vertical, 8)
            .foregroundStyle(MochaTheme.primaryText)
            .background(selected ? MochaTheme.yellow : MochaTheme.softYellow.opacity(0.55), in: Capsule())
            .overlay {
                Capsule().stroke(selected ? Color.clear : MochaTheme.yellow.opacity(0.25), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
