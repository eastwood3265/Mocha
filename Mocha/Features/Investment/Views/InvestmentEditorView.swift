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
    @State private var holdingAmount: Decimal
    @State private var totalProfit: Decimal
    @State private var note: String
    @State private var selectedLocation: StorageLocation?

    init(investment: Investment? = nil) {
        self.investment = investment
        _name = State(initialValue: investment?.name ?? "")
        _code = State(initialValue: investment?.code ?? "")
        _type = State(initialValue: investment?.type ?? .bond)
        _holdingAmount = State(initialValue: investment?.holdingAmount ?? 0)
        _totalProfit = State(initialValue: investment?.totalProfit ?? 0)
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
                    DecimalField("持仓金额", value: $holdingAmount)
                    if type != .cash {
                        DecimalField("总盈亏", value: $totalProfit)
                    }
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
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || holdingAmount < 0)
                }
            }
        }
    }

    private func save() {
        if let investment {
            investment.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            investment.code = type == .cash ? "" : code.trimmingCharacters(in: .whitespacesAndNewlines)
            investment.type = type
            investment.holdingAmount = holdingAmount
            investment.totalProfit = type == .cash ? 0 : totalProfit
            investment.note = note
            investment.storageLocation = selectedLocation
            investment.updatedAt = .now
        } else {
            modelContext.insert(Investment(name: name.trimmingCharacters(in: .whitespacesAndNewlines), code: type == .cash ? "" : code, type: type, holdingAmount: holdingAmount, totalProfit: type == .cash ? 0 : totalProfit, note: note, storageLocation: selectedLocation))
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
