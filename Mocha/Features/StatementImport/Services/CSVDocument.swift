import CoreFoundation
import Foundation

struct CSVDocument {
    let rows: [[String]]

    init(data: Data) throws {
        guard let content = Self.decode(data) else {
            throw StatementImportError.unsupportedEncoding
        }
        rows = Self.parse(content)
    }

    private static func decode(_ data: Data) -> String? {
        if let string = String(data: data, encoding: .utf8) { return string }
        if let string = String(data: data, encoding: .utf16) { return string }
        let gb18030 = String.Encoding(
            rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(0x0632)
            )
        )
        return String(data: data, encoding: gb18030)
    }

    private static func parse(_ content: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var isQuoted = false
        let characters = Array(content)
        var index = 0

        func finishField() {
            row.append(field.trimmingCharacters(in: .whitespacesAndNewlines))
            field = ""
        }

        func finishRow() {
            finishField()
            if row.contains(where: { !$0.isEmpty }) { rows.append(row) }
            row = []
        }

        while index < characters.count {
            let character = characters[index]
            if character == "\"" {
                if isQuoted, index + 1 < characters.count, characters[index + 1] == "\"" {
                    field.append("\"")
                    index += 1
                } else {
                    isQuoted.toggle()
                }
            } else if character == ",", !isQuoted {
                finishField()
            } else if (character == "\n" || character == "\r"), !isQuoted {
                if character == "\r", index + 1 < characters.count, characters[index + 1] == "\n" {
                    index += 1
                }
                finishRow()
            } else {
                field.append(character)
            }
            index += 1
        }

        if !field.isEmpty || !row.isEmpty { finishRow() }
        return rows
    }
}
