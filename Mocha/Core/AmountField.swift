import Foundation
import SwiftUI

enum AmountInputFormatter {
    static let maximumFractionDigits = 4
    private static let parsingLocale = Locale(identifier: "en_US_POSIX")

    static func normalize(
        _ candidate: String,
        allowsNegative: Bool,
        maximumFractionDigits: Int = maximumFractionDigits
    ) -> String? {
        var text = candidate
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "¥", with: "")
            .replacingOccurrences(of: "￥", with: "")
            .replacingOccurrences(of: "CNY", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "－", with: "-")
            .replacingOccurrences(of: "，", with: ",")
            .replacingOccurrences(of: "。", with: ".")

        text.removeAll { $0 == "," || $0.isWhitespace }
        if text.hasPrefix("+") { text.removeFirst() }

        let isNegative = text.hasPrefix("-")
        if isNegative {
            guard allowsNegative else { return nil }
            text.removeFirst()
        }
        guard !text.contains("-"), !text.contains("+") else { return nil }

        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2 else { return nil }
        guard parts.allSatisfy({ part in part.allSatisfy(\.isNumber) }) else { return nil }
        if parts.count == 2, parts[1].count > maximumFractionDigits { return nil }

        if text.hasPrefix(".") { text = "0" + text }
        let prefix = isNegative ? "-" : ""
        return prefix + text
    }

    static func decimal(from text: String) -> Decimal? {
        guard !text.isEmpty, text != "-", text != ".", text != "-." else { return nil }
        return Decimal(string: text, locale: parsingLocale)
    }

    static func editingText(for value: Decimal) -> String {
        value == 0 ? "" : NSDecimalNumber(decimal: value).stringValue
    }

    static func displayText(for value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? NSDecimalNumber(decimal: value).stringValue
    }
}

struct AmountField: View {
    let title: String
    let allowsNegative: Bool
    @Binding private var value: Decimal
    @State private var text: String
    @FocusState private var isFocused: Bool

    init(
        _ title: String,
        value: Binding<Decimal>,
        allowsNegative: Bool = false
    ) {
        self.title = title
        self.allowsNegative = allowsNegative
        _value = value
        _text = State(initialValue: AmountInputFormatter.displayText(for: value.wrappedValue))
    }

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                Text("¥")
                    .foregroundStyle(.secondary)

                TextField("0.00", text: inputBinding)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)

                if allowsNegative {
                    Button(action: toggleSign) {
                        Image(systemName: "plus.forwardslash.minus")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(MochaTheme.secondaryText)
                    .accessibilityLabel("切换正负")
                }

                if isFocused, !text.isEmpty {
                    Button(action: clear) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel("清空金额")
                }
            }
        }
        .onChange(of: isFocused) { _, focused in
            if focused {
                if text == AmountInputFormatter.displayText(for: value) {
                    text = AmountInputFormatter.editingText(for: value)
                }
            } else {
                commitAndFormat()
            }
        }
        .onChange(of: value) { _, newValue in
            if !isFocused {
                text = AmountInputFormatter.displayText(for: newValue)
            }
        }
        .toolbar {
            if isFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { isFocused = false }
                }
            }
        }
    }

    private var inputBinding: Binding<String> {
        Binding(
            get: { text },
            set: { candidate in
                guard let normalized = AmountInputFormatter.normalize(
                    candidate,
                    allowsNegative: allowsNegative
                ) else { return }
                text = normalized
                if normalized.isEmpty {
                    value = 0
                } else if let parsed = AmountInputFormatter.decimal(from: normalized) {
                    value = parsed
                }
            }
        )
    }

    private func toggleSign() {
        guard allowsNegative else { return }
        if !isFocused {
            text = AmountInputFormatter.editingText(for: value)
        }

        if text.hasPrefix("-") {
            text.removeFirst()
        } else {
            text = "-" + text
        }
        value = AmountInputFormatter.decimal(from: text) ?? 0
        isFocused = true
    }

    private func clear() {
        text = ""
        value = 0
    }

    private func commitAndFormat() {
        value = AmountInputFormatter.decimal(from: text) ?? 0
        text = AmountInputFormatter.displayText(for: value)
    }
}
