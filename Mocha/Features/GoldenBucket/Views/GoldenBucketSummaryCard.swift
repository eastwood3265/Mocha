import SwiftUI

struct GoldenBucketSummaryCard: View {
    let summary: SavingsBucketSummary
    let bucketCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("金桶总余额")
                .font(.subheadline)
                .foregroundStyle(MochaTheme.themeForeground.opacity(0.62))
            Text(CurrencyFormatting.cny(summary.totalBalance))
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(summary.totalBalance < 0 ? .red : MochaTheme.themeForeground)
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Divider().overlay(MochaTheme.themeForeground.opacity(0.12))

            HStack(alignment: .top) {
                metric("进行中", "\(bucketCount) 个桶")
                Spacer()
                if summary.targetProgressRatio != nil {
                    metric("目标总额", CurrencyFormatting.cny(summary.totalTarget))
                } else {
                    metric("目标总额", "未设置")
                }
            }

            if summary.totalTarget > 0, let ratio = summary.targetProgressRatio {
                HStack {
                    Text("整体进度")
                    Spacer()
                    Text(ratio.formatted(.percent.precision(.fractionLength(0))))
                }
                .font(.caption.weight(.medium))
                ProgressView(value: ratio)
                    .tint(MochaTheme.themeForeground)
            }
        }
        .foregroundStyle(MochaTheme.themeForeground)
        .padding(20)
        .background(MochaTheme.yellow, in: RoundedRectangle(cornerRadius: 24))
        .overlay { RoundedRectangle(cornerRadius: 24).stroke(MochaTheme.themeBorder, lineWidth: 1) }
        .shadow(color: MochaTheme.yellow.opacity(0.22), radius: 14, y: 7)
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(MochaTheme.themeForeground.opacity(0.58))
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}
