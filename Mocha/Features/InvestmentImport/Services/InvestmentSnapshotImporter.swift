import Foundation

struct ParsedInvestmentSnapshot {
    let sourceIdentifier: String
    let parserVersion: Int
    let records: [ImportedInvestmentSnapshot]
}

protocol InvestmentSnapshotImporter {
    var parserVersion: Int { get }
    func canParse(rows: [[String]]) -> Bool
    func parse(rows: [[String]]) throws -> ParsedInvestmentSnapshot
}

struct InvestmentSnapshotParser {
    private let importers: [any InvestmentSnapshotImporter] = [
        FundEAccountSnapshotImporter(),
        NormalizedInvestmentSnapshotCSVImporter()
    ]

    func parse(data: Data, fileName: String = "snapshot.csv") throws -> ParsedInvestmentSnapshot {
        let rows: [[String]]
        if fileName.lowercased().hasSuffix(".xlsx") {
            do {
                rows = try XLSXTableReader().rows(from: data)
            } catch let error as InvestmentSnapshotImportError {
                throw error
            } catch {
                throw InvestmentSnapshotImportError.unsupportedFile
            }
        } else {
            rows = try CSVDocument(data: data).rows
        }
        guard let importer = importers.first(where: { $0.canParse(rows: rows) }) else {
            throw InvestmentSnapshotImportError.unsupportedStatement
        }
        return try importer.parse(rows: rows)
    }
}
