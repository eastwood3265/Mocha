import SwiftData
import SwiftUI

struct InvestmentDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Investment.updatedAt, order: .reverse) private var investments: [Investment]
    @State private var selectedType: InvestmentType?
    @State private var showingInvestmentEditor = false
    @State private var showingRebalance = false
    @State private var showingSnapshotImport = false
    @State private var pendingSnapshotImport: PendingInvestmentImport?
    @State private var pendingDeletion: Investment?

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
                        ContentUnavailableView {
                            Label(selectedType == nil ? "暂无持仓" : "暂无\(selectedType!.rawValue)持仓", systemImage: "tray")
                        } description: {
                            Text(selectedType == nil ? "手动添加投资，或导入基金持仓文件。" : "当前筛选类型下没有投资项。")
                        } actions: {
                            if selectedType == nil {
                                Button("添加投资", systemImage: "plus") { showingInvestmentEditor = true }
                                    .buttonStyle(.borderedProminent)
                            } else {
                                Button("查看全部") { selectedType = nil }
                                    .buttonStyle(.bordered)
                            }
                        }
                            .padding(.top, 44)
                    } else {
                        ForEach(filtered) { investment in
                            NavigationLink(value: investment) {
                                InvestmentRow(investment: investment)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("删除投资项", systemImage: "trash", role: .destructive) {
                                    pendingDeletion = investment
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
                    Button("导入持仓", systemImage: "square.and.arrow.down") {
                        pendingSnapshotImport = nil
                        showingSnapshotImport = true
                    }
                    Button("添加投资", systemImage: "plus") { showingInvestmentEditor = true }
                }
            }
            .sheet(isPresented: $showingInvestmentEditor) { InvestmentEditorView() }
            .sheet(isPresented: $showingRebalance) { RebalanceView(investments: investments) }
            .sheet(isPresented: $showingSnapshotImport, onDismiss: { pendingSnapshotImport = nil }) {
                InvestmentSnapshotImportView(pendingImport: pendingSnapshotImport)
            }
            .alert("删除投资项？", isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            )) {
                Button("取消", role: .cancel) { pendingDeletion = nil }
                Button("删除", role: .destructive) {
                    if let pendingDeletion { modelContext.delete(pendingDeletion) }
                    pendingDeletion = nil
                }
            } message: {
                Text("将删除「\(pendingDeletion?.name ?? "")」及其当前持仓数据，此操作无法撤销。")
            }
            .onAppear {
                presentPendingImportIfNeeded()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { presentPendingImportIfNeeded() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .pendingInvestmentImportDidChange)) { _ in
                presentPendingImportIfNeeded()
            }
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

    private func presentPendingImportIfNeeded() {
        guard !showingSnapshotImport,
              pendingSnapshotImport == nil,
              let pending = PendingInvestmentImportStore.take() else { return }
        pendingSnapshotImport = pending
        showingSnapshotImport = true
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
