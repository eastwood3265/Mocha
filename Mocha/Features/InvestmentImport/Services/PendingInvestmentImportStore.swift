import Foundation

extension Notification.Name {
    static let pendingInvestmentImportDidChange = Notification.Name("pendingInvestmentImportDidChange")
}

struct PendingInvestmentImport: Identifiable {
    let data: Data
    let fileName: String

    var id: String { fileName }
}

enum PendingInvestmentImportStore {
    private static let fileNameKey = "pendingInvestmentImportFileName"
    private static let storedFileName = "pending-investment-import"

    static func save(data: Data, fileName: String) throws {
        let directory = try applicationSupportDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: directory.appendingPathComponent(storedFileName), options: .atomic)
        UserDefaults.standard.set(fileName, forKey: fileNameKey)
        NotificationCenter.default.post(name: .pendingInvestmentImportDidChange, object: nil)
    }

    static func load() -> PendingInvestmentImport? {
        guard let fileName = UserDefaults.standard.string(forKey: fileNameKey),
              let data = try? Data(contentsOf: try applicationSupportDirectory().appendingPathComponent(storedFileName)) else {
            return nil
        }
        return PendingInvestmentImport(data: data, fileName: fileName)
    }

    /// 读取并立即移除待处理文件，保证一次快捷指令投递只触发一次界面展示。
    static func take() -> PendingInvestmentImport? {
        guard let pending = load() else {
            remove()
            return nil
        }
        remove()
        return pending
    }

    static func remove() {
        UserDefaults.standard.removeObject(forKey: fileNameKey)
        guard let directory = try? applicationSupportDirectory() else { return }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(storedFileName))
    }

    private static func applicationSupportDirectory() throws -> URL {
        try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("InvestmentImport", isDirectory: true)
    }
}
