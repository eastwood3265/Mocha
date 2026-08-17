import SwiftUI

struct LabeledNoteEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(MochaTheme.primaryText)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(MochaTheme.secondaryText.opacity(0.7))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .foregroundStyle(MochaTheme.primaryText)
                    .frame(minHeight: 96)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 1)
                    .accessibilityLabel(title)
            }
            .padding(8)
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(MochaTheme.yellow.opacity(0.32), lineWidth: 1)
            }
        }
        .padding(.vertical, 4)
    }
}
