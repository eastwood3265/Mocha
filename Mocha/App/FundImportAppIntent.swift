import AppIntents
import UniformTypeIdentifiers

struct ImportFundSnapshotIntent: AppIntent {
    static let title: LocalizedStringResource = "导入基金持仓文件"
    static let description = IntentDescription("接收基金 E 账户 XLSX 或 Mocha 持仓 CSV，并在 Mocha 中打开导入预览。")
    static let openAppWhenRun = true

    @Parameter(
        title: "持仓文件",
        supportedTypeIdentifiers: [
            "org.openxmlformats.spreadsheetml.sheet",
            "public.comma-separated-values",
            "public.plain-text"
        ]
    )
    var file: IntentFile

    func perform() async throws -> some IntentResult & ProvidesDialog {
        try PendingInvestmentImportStore.save(data: file.data, fileName: file.filename)
        return .result(dialog: "文件已交给 Mocha，请确认导入预览。")
    }
}

struct MochaAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ImportFundSnapshotIntent(),
            phrases: ["用 \(.applicationName) 导入基金持仓"],
            shortTitle: "导入基金持仓",
            systemImageName: "square.and.arrow.down"
        )
    }
}
