import SwiftData
import SwiftUI

struct StorageLocationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StorageLocation.name) private var locations: [StorageLocation]
    @State private var editingLocation: StorageLocation?
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            List {
                if locations.isEmpty {
                    ContentUnavailableView("暂无存放处", systemImage: "building.columns", description: Text("例如证券账户、债券平台或黄金保管位置。"))
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
                        .swipeActions { Button("删除", role: .destructive) { modelContext.delete(location) } }
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
        }
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
        if let location {
            location.name = name; location.type = type; location.institution = institution
            location.accountAlias = accountAlias; location.accountSuffix = accountSuffix; location.note = note
        } else {
            modelContext.insert(StorageLocation(name: name, type: type, institution: institution, accountAlias: accountAlias, accountSuffix: accountSuffix, note: note))
        }
        dismiss()
    }
}
