import CoreXLSX
import Foundation

struct XLSXTableReader {
    func rows(from data: Data) throws -> [[String]] {
        let file = try XLSXFile(data: data)
        let sharedStrings = try file.parseSharedStrings()
        guard let workbook = try file.parseWorkbooks().first,
              let path = try file.parseWorksheetPathsAndNames(workbook: workbook).first?.path else {
            throw InvestmentSnapshotImportError.noSnapshots
        }
        let worksheet = try file.parseWorksheet(at: path)

        return (worksheet.data?.rows ?? []).map { row in
            var values = Array(repeating: "", count: 15)
            for cell in row.cells {
                guard let index = Self.columnIndex(cell.reference.column.value), index < values.count else { continue }
                if let sharedStrings {
                    values[index] = cell.stringValue(sharedStrings) ?? cell.inlineString?.text ?? cell.value ?? ""
                } else {
                    values[index] = cell.inlineString?.text ?? cell.value ?? ""
                }
                if [9, 11].contains(index), let date = cell.dateValue, cell.type != .sharedString {
                    values[index] = Self.dateFormatter.string(from: date)
                }
            }
            return values
        }
    }

    private static func columnIndex(_ value: String) -> Int? {
        let scalars = value.uppercased().unicodeScalars
        guard !scalars.isEmpty else { return nil }
        return scalars.reduce(0) { $0 * 26 + Int($1.value - 64) } - 1
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
