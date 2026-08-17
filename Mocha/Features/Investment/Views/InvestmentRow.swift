import SwiftUI

struct InvestmentRow: View {
    let investment: Investment
    private var subtitle: String {
        let values = [investment.code, investment.storageLocation?.name ?? ""].filter { !$0.isEmpty }
        return values.isEmpty ? investment.type.rawValue : values.joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: investment.type.icon)
                .font(.title3).foregroundStyle(investment.type.color)
                .frame(width: 44, height: 44)
                .foregroundStyle(.black)
                .background(MochaTheme.yellow, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 5) {
                Text(investment.name).font(.headline).lineLimit(1)
                Text(subtitle)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text(CurrencyFormatting.cny(investment.marketValue)).font(.headline)
                Text("\(investment.profit >= 0 ? "+" : "")\(CurrencyFormatting.cny(investment.profit))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(investment.profit >= 0 ? .red : .green)
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(MochaTheme.yellow.opacity(0.18), lineWidth: 1) }
        .shadow(color: MochaTheme.yellow.opacity(0.08), radius: 8, y: 3)
    }
}
