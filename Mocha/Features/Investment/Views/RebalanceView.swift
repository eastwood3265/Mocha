import SwiftData
import SwiftUI

struct RebalanceView: View {
    @Environment(\.dismiss) private var dismiss
    let investments: [Investment]

    @State private var direction: RebalanceDirection = .buy
    @State private var amount: Decimal = 0
    @State private var selectedIDs: Set<PersistentIdentifier> = []
    @State private var isRecurring = false
    @State private var holidayDates: Set<String> = []
    @State private var holidayCalendarState: HolidayCalendarState = .loading

    private var tradingDayCount: Int {
        TradingDayEstimator.remainingWeekdaysInCurrentMonth(holidayDates: holidayDates)
    }
    private var plan: RebalancePlan {
        RebalancePlanner.makePlan(
            investments: investments,
            selectedIDs: selectedIDs,
            amount: amount,
            direction: direction,
            tradingDayCount: tradingDayCount
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("操作方向", selection: $direction) {
                        ForEach(RebalanceDirection.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    DecimalField("操作金额", value: $amount)
                    Toggle("按交易日定投", isOn: $isRecurring)
                        .tint(MochaTheme.yellow)
                } header: {
                    Text("操作设置")
                } footer: {
                    if isRecurring {
                        Text(tradingDayDescription)
                    }
                }

                Section {
                    ForEach(investments) { investment in
                        let selectable = investment.type == .cash || investment.currentPrice > 0
                        Button {
                            guard selectable else { return }
                            if selectedIDs.contains(investment.persistentModelID) {
                                selectedIDs.remove(investment.persistentModelID)
                            } else {
                                selectedIDs.insert(investment.persistentModelID)
                            }
                        } label: {
                            HStack {
                                Image(systemName: investment.type.icon)
                                    .foregroundStyle(.black)
                                    .frame(width: 30, height: 30)
                                    .background(MochaTheme.yellow, in: RoundedRectangle(cornerRadius: 8))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(investment.name).foregroundStyle(selectable ? .primary : .secondary)
                                    Text("\(investment.type.rawValue) · 市值 \(CurrencyFormatting.cny(investment.marketValue))")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if !selectable {
                                    Text("缺少单价").font(.caption).foregroundStyle(.orange)
                                } else {
                                    Image(systemName: selectedIDs.contains(investment.persistentModelID) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedIDs.contains(investment.persistentModelID) ? MochaTheme.yellow : .secondary)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HStack {
                        Text("选择成分")
                        Spacer()
                        Button(selectedIDs.count == selectableInvestments.count ? "取消全选" : "全选") {
                            if selectedIDs.count == selectableInvestments.count {
                                selectedIDs.removeAll()
                            } else {
                                selectedIDs = Set(selectableInvestments.map(\.persistentModelID))
                            }
                        }
                        .textCase(nil)
                    }
                } footer: {
                    Text("先按债券、股票、黄金、现金各 25% 的目标分配，再在同类所选投资项中平分；现金不拆分为每日定投金额。")
                }

                Section("分配结果") {
                    if amount <= 0 || selectedIDs.isEmpty {
                        ContentUnavailableView("等待计算", systemImage: "scale.3d", description: Text("输入金额并至少选择一个投资项。"))
                    } else if plan.allocations.isEmpty {
                        ContentUnavailableView("无法分配", systemImage: "exclamationmark.triangle", description: Text("卖出金额可能超过所选持仓，或所选成分缺少有效市值。"))
                    } else {
                        ForEach(plan.allocations) { allocation in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(allocation.investment.name).font(.headline)
                                    Spacer()
                                    Text(CurrencyFormatting.cny(allocation.amount)).font(.headline)
                                }
                                if isRecurring, let dailyAmount = allocation.recurringDailyAmount(tradingDayCount: plan.tradingDayCount) {
                                    LabeledContent("每个交易日", value: CurrencyFormatting.cny(dailyAmount))
                                        .font(.subheadline)
                                } else if isRecurring {
                                    LabeledContent("现金调整", value: "仅计入总体金额")
                                        .font(.subheadline)
                                } else {
                                    LabeledContent("操作数量", value: allocation.quantity.formatted(.number.precision(.fractionLength(0...4))))
                                        .font(.subheadline)
                                }
                                Text("\(allocation.investment.type.rawValue) · 当前市值 \(CurrencyFormatting.cny(allocation.investment.marketValue))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        LabeledContent("已分配", value: CurrencyFormatting.cny(plan.allocatedAmount))
                            .fontWeight(.semibold)
                        if plan.unallocatedAmount > 0.01 {
                            LabeledContent("无法分配", value: CurrencyFormatting.cny(plan.unallocatedAmount))
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MochaTheme.background)
            .navigationTitle("再平衡分配")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
            .onAppear {
                if selectedIDs.isEmpty { selectedIDs = Set(selectableInvestments.map(\.persistentModelID)) }
            }
            .task { await loadHolidayCalendar() }
        }
        .tint(MochaTheme.primaryText)
    }

    private var selectableInvestments: [Investment] {
        investments.filter { $0.type == .cash || $0.currentPrice > 0 }
    }

    private var tradingDayDescription: String {
        switch holidayCalendarState {
        case .loading:
            return "正在查询法定节假日；当前暂按工作日计算。"
        case .loaded:
            return "本月剩余 \(tradingDayCount) 个交易日，已扣除周末和法定节假日。"
        case .fallback:
            return "节假日查询失败，本月暂按剩余 \(tradingDayCount) 个工作日计算。"
        }
    }

    @MainActor
    private func loadHolidayCalendar() async {
        let year = Calendar.current.component(.year, from: .now)
        do {
            holidayDates = try await HolidayCalendarService.shared.holidayDates(for: year)
            holidayCalendarState = .loaded
        } catch {
            holidayDates = []
            holidayCalendarState = .fallback
        }
    }
}

private enum HolidayCalendarState {
    case loading
    case loaded
    case fallback
}
