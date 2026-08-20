import SwiftUI

struct SavingsBucketRow: View {
    let progress: SavingsBucketProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "banknote.fill")
                    .font(.headline)
                    .foregroundStyle(MochaTheme.themeForeground)
                    .frame(width: 36, height: 36)
                    .background(MochaTheme.yellow, in: RoundedRectangle(cornerRadius: 8))
                    .overlay { RoundedRectangle(cornerRadius: 8).stroke(MochaTheme.themeBorder, lineWidth: 1) }

                VStack(alignment: .leading, spacing: 3) {
                    Text(progress.bucket.name)
                        .font(.headline)
                        .foregroundStyle(MochaTheme.primaryText)
                    if let deadline = progress.bucket.deadline {
                        Text(deadline, format: .dateTime.year().month().day())
                            .font(.caption)
                            .foregroundStyle(progress.isDeadlineExpired() && !progress.isCompleted ? .red : .secondary)
                    } else {
                        Text("长期攒钱")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(CurrencyFormatting.cny(progress.balance))
                    .font(.headline)
                    .foregroundStyle(progress.isNegative ? .red : MochaTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            if let targetAmount = progress.targetAmount, let ratio = progress.ratio {
                ProgressView(value: ratio)
                    .tint(progress.isNegative ? .red : MochaTheme.yellow)
                HStack {
                    Text(progress.isCompleted ? "目标已完成" : "还差 \(CurrencyFormatting.cny(progress.remainingAmount ?? 0))")
                    Spacer()
                    Text("目标 \(CurrencyFormatting.cny(targetAmount))")
                }
                .font(.caption)
                .foregroundStyle(progress.isCompleted ? MochaTheme.secondaryText : .secondary)
            } else if progress.isNegative {
                Text("当前余额为负数")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(progress.isNegative ? Color.red.opacity(0.35) : MochaTheme.yellow.opacity(0.2), lineWidth: 1)
        }
    }
}
