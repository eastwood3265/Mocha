import CryptoKit
import Foundation

struct ImportedTransaction: Identifiable, Equatable {
    let source: TransactionSource
    let externalID: String
    let occurredAt: Date
    let direction: TransactionDirection
    let amount: Decimal
    let counterparty: String
    let description: String
    let paymentMethod: String
    let status: String
    let merchantOrderID: String
    let note: String

    var id: String { fingerprint }

    var fingerprint: String {
        let identity = externalID.isEmpty
            ? [
                source.rawValue,
                Self.timestampFormatter.string(from: occurredAt),
                direction.rawValue,
                NSDecimalNumber(decimal: amount).stringValue,
                Self.normalize(counterparty),
                Self.normalize(description)
            ].joined(separator: "|")
            : "\(source.rawValue)|\(externalID)"
        return SHA256.hash(data: Data(identity.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }
}
