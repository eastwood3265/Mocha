import SwiftData
import SwiftUI

struct StorageLocationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StorageLocation.name) private var locations: [StorageLocation]
    @Query private var investments: [Investment]
    @State private var editingLocation: StorageLocation?
    @State private var showingEditor = false
    @State private var pendingDeletion: StorageLocation?

    var body: some View {
        NavigationStack {
            List {
                if locations.isEmpty {
                    ContentUnavailableView {
                        Label("暂无存放处", systemImage: "building.columns")
                    } description: {
                        Text("集中记录证券账户、基金平台和其他资产位置。")
                    } actions: {
                        Button("添加存放处", systemImage: "plus") {
                            editingLocation = nil
                            showingEditor = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ForEach(locations) { location in
                        Button {
                            editingLocation = location; showingEditor = true
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(location.name).font(.headline).foregroundStyle(.primary)
                                Text([location.type.rawValue, location.institution, location.accountAlias, location.accountSuffix.isEmpty ? "" : "尾号 \(location.accountSuffix)"].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            Button("删除", role: .destructive) { pendingDeletion = location }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(MochaTheme.background)
            .navigationTitle("存放处")
            .toolbar {
                ToolbarItem(placement: .primaryAction) { Button("添加", systemImage: "plus") { editingLocation = nil; showingEditor = true } }
            }
            .sheet(isPresented: $showingEditor) { StorageLocationEditorView(location: editingLocation) }
            .alert("删除存放处？", isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            )) {
                Button("取消", role: .cancel) { pendingDeletion = nil }
                Button("删除", role: .destructive) {
                    if let pendingDeletion { modelContext.delete(pendingDeletion) }
                    pendingDeletion = nil
                }
            } message: {
                let count = pendingDeletion.map(investmentCount) ?? 0
                Text(count == 0
                     ? "将删除「\(pendingDeletion?.name ?? "")」，此操作无法撤销。"
                     : "有 \(count) 个投资项关联到这里。删除后这些投资项会变为未指定存放处。")
            }
        }
    }

    private func investmentCount(for location: StorageLocation) -> Int {
        investments.filter { $0.storageLocation?.persistentModelID == location.persistentModelID }.count
    }
}

private struct StorageLocationEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let location: StorageLocation?
    @State private var name: String
    @State private var type: StorageLocationType
    @State private var institution: String
    @State private var accountAlias: String
    @State private var accountSuffix: String
    @State private var note: String

    init(location: StorageLocation?) {
        self.location = location
        _name = State(initialValue: location?.name ?? "")
        _type = State(initialValue: location?.type ?? .brokerage)
        _institution = State(initialValue: location?.institution ?? "")
        _accountAlias = State(initialValue: location?.accountAlias ?? "")
        _accountSuffix = State(initialValue: location?.accountSuffix ?? "")
        _note = State(initialValue: location?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    LabeledContent("名称") {
                        TextField("例如：长期账户", text: $name).multilineTextAlignment(.trailing)
                    }
                    Picker("类型", selection: $type) { ForEach(StorageLocationType.allCases) { Text($0.rawValue).tag($0) } }
                    LabeledContent("机构") {
                        TextField("例如：招商证券", text: $institution).multilineTextAlignment(.trailing)
                    }
                }
                Section("账户标识") {
                    LabeledContent("账户别名") {
                        TextField("可选", text: $accountAlias).multilineTextAlignment(.trailing)
                    }
                    LabeledContent("账号尾号") {
                        TextField("可选", text: $accountSuffix).keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }
                Section("备注") {
                    LabeledNoteEditor(title: "备注", placeholder: "记录账户用途或其他说明", text: $note)
                }
            }
            .scrollContentBackground(.hidden)
            .background(MochaTheme.background)
            .navigationTitle(location == nil ? "添加存放处" : "编辑存放处")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存", action: save).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) }
            }
        }
    }

    private func save() {
        let normalizedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedInstitution = institution.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAlias = accountAlias.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSuffix = accountSuffix.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        if let location {
            location.name = normalizedName; location.type = type; location.institution = normalizedInstitution
            location.accountAlias = normalizedAlias; location.accountSuffix = normalizedSuffix; location.note = normalizedNote
        } else {
            modelContext.insert(StorageLocation(name: normalizedName, type: type, institution: normalizedInstitution, accountAlias: normalizedAlias, accountSuffix: normalizedSuffix, note: normalizedNote))
        }
        dismiss()
    }
}
