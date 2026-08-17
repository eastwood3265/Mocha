import SwiftData
import SwiftUI

struct InvestmentEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StorageLocation.name) private var locations: [StorageLocation]
    let investment: Investment?

    @State private var name: String
    @State private var code: String
    @State private var type: InvestmentType
    @State private var quantity: Decimal
    @State private var currentPrice: Decimal
    @State private var currentProfit: Decimal
    @State private var note: String
    @State private var selectedLocation: StorageLocation?

    init(investment: Investment? = nil) {
        self.investment = investment
        _name = State(initialValue: investment?.name ?? "")
        _code = State(initialValue: investment?.code ?? "")
        _type = State(initialValue: investment?.type ?? .bond)
        _quantity = State(initialValue: investment?.quantity ?? 0)
        _currentPrice = State(initialValue: investment?.currentPrice ?? 0)
        _currentProfit = State(initialValue: investment?.currentProfit ?? 0)
        _note = State(initialValue: investment?.note ?? "")
        _selectedLocation = State(initialValue: investment?.storageLocation)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("资产") {
                    Picker("类型", selection: $type) { ForEach(InvestmentType.allCases) { Label($0.rawValue, systemImage: $0.icon).tag($0) } }
                    LabeledContent("名称") {
                        TextField(type == .cash ? "例如：备用金" : "例如：沪深300ETF", text: $name).multilineTextAlignment(.trailing)
                    }
                    if type != .cash {
                        LabeledContent("代码") {
                            TextField("可选", text: $code).textInputAutocapitalization(.characters).multilineTextAlignment(.trailing)
                        }
                    }
                    DecimalField(type == .cash ? "持有量" : "当前持仓数量", value: $quantity)
                    if type != .cash {
                        DecimalField("当前单价", value: $currentPrice)
                        DecimalField("当前盈亏", value: $currentProfit)
                    }
                    LabeledContent("当前市值", value: CurrencyFormatting.cny(type == .cash ? quantity : quantity * currentPrice))
                }
                Section("存放处") {
                    Picker("关联账户", selection: $selectedLocation) {
                        Text("未指定").tag(nil as StorageLocation?)
                        ForEach(locations) { Text($0.name).tag(Optional($0)) }
                    }
                    if locations.isEmpty { Text("可在首页左上角先创建存放处").font(.caption).foregroundStyle(.secondary) }
                }
                Section("备注") {
                    LabeledNoteEditor(title: "备注", placeholder: "记录投资计划或补充说明", text: $note)
                }
            }
            .scrollContentBackground(.hidden)
            .background(MochaTheme.background)
            .navigationTitle(investment == nil ? "添加投资" : "编辑投资")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || quantity < 0 || (type != .cash && currentPrice < 0))
                }
            }
        }
    }

    private func save() {
        if let investment {
            investment.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            investment.code = type == .cash ? "" : code.trimmingCharacters(in: .whitespacesAndNewlines)
            investment.type = type; investment.quantity = quantity
            investment.currentPrice = type == .cash ? 1 : currentPrice
            investment.currentProfit = type == .cash ? 0 : currentProfit
            investment.note = note; investment.storageLocation = selectedLocation; investment.updatedAt = .now
        } else {
            modelContext.insert(Investment(name: name.trimmingCharacters(in: .whitespacesAndNewlines), code: type == .cash ? "" : code, type: type, quantity: quantity, currentPrice: type == .cash ? 1 : currentPrice, currentProfit: type == .cash ? 0 : currentProfit, note: note, storageLocation: selectedLocation))
        }
        dismiss()
    }
}

struct DecimalField: View {
    let title: String
    @Binding var value: Decimal
    init(_ title: String, value: Binding<Decimal>) { self.title = title; _value = value }
    var body: some View {
        LabeledContent(title) {
            TextField("请输入", value: $value, format: .number.precision(.fractionLength(0...4)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
}
