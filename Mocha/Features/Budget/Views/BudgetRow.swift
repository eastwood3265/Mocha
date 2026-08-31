import SwiftUI

struct BudgetRow: View {
    let progress: BudgetProgress

    private var statusText: String {
        if progress.isOverspent {
            return "超支 \(CurrencyFormatting.cny(-progress.remaining))"
        }
        return "剩余 \(CurrencyFormatting.cny(progress.remaining))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: progress.budget.period.systemImage)
                    .font(.headline)
                    .foregroundStyle(MochaTheme.themeForeground)
                    .frame(width: 30, height: 30)
                    .background(MochaTheme.yellow, in: Circle())
                    .overlay { Circle().stroke(MochaTheme.themeBorder, lineWidth: 1) }

                VStack(alignment: .leading, spacing: 3) {
                    Text(progress.budget.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(MochaTheme.primaryText)
                        .lineLimit(2)
                    Text("\(progress.budget.period.title)预算")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(CurrencyFormatting.cny(progress.spent))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(MochaTheme.primaryText)
                    Text("/ \(CurrencyFormatting.cny(progress.amount))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: progress.ratio)
                .tint(progress.isOverspent ? .red : MochaTheme.yellow)

            Text(statusText)
                .font(.caption.weight(.medium))
                .foregroundStyle(progress.isOverspent ? .red : MochaTheme.secondaryText)
        }
        .padding()
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(MochaTheme.yellow.opacity(0.2), lineWidth: 1)
        }
    }
}
