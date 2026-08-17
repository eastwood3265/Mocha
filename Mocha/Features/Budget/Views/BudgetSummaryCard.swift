import SwiftUI

struct BudgetSummaryCard: View {
    let title: String
    let spent: Decimal
    let amount: Decimal
    let systemImage: String

    private var ratio: Double {
        guard amount > 0 else { return spent > 0 ? 1 : 0 }
        let decimalRatio = spent / amount
        return max(0, min(1, NSDecimalNumber(decimal: decimalRatio).doubleValue))
    }

    private var remaining: Decimal { amount - spent }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(remaining < 0 ? "超支" : "剩余")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(CurrencyFormatting.cny(spent))
                    .font(.title3.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text("/ \(CurrencyFormatting.cny(amount))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: ratio)
                .tint(remaining < 0 ? .red : MochaTheme.yellow)

            Text(remaining < 0 ? "超支 \(CurrencyFormatting.cny(-remaining))" : "剩余 \(CurrencyFormatting.cny(remaining))")
                .font(.caption.weight(.medium))
                .foregroundStyle(remaining < 0 ? .red : MochaTheme.secondaryText)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MochaTheme.softYellow.opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(MochaTheme.yellow.opacity(0.22), lineWidth: 1)
        }
        .foregroundStyle(MochaTheme.primaryText)
    }
}
