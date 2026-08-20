import SwiftUI

struct SettingsDashboardView: View {
    @AppStorage(AppThemeColor.storageKey) private var selectedThemeRawValue = AppThemeColor.lemon.rawValue
    @AppStorage(GoldenBucketSettings.negativeBalanceWarningKey) private var negativeBalanceWarningEnabled = true

    private var selectedTheme: AppThemeColor {
        AppThemeColor(rawValue: selectedThemeRawValue) ?? .lemon
    }

    var body: some View {
        NavigationStack {
            List {
                Section("主题色") {
                    ForEach(AppThemeColor.allCases) { theme in
                        Button {
                            selectedThemeRawValue = theme.rawValue
                        } label: {
                            HStack(spacing: 12) {
                                ThemeColorSwatch(theme: theme)
                                Text(theme.title)
                                Spacer()
                                if theme == selectedTheme {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(MochaTheme.primaryText)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Toggle("负余额提示", isOn: $negativeBalanceWarningEnabled)
                        .tint(MochaTheme.yellow)
                } header: {
                    Text("金桶")
                } footer: {
                    Text("开启后，操作使余额降至 0 以下或进一步降低负余额时会再次确认。")
                }
            }
            .scrollContentBackground(.hidden)
            .background(MochaTheme.background)
            .navigationTitle("设置")
        }
        .tint(MochaTheme.primaryText)
    }
}

private struct ThemeColorSwatch: View {
    let theme: AppThemeColor

    var body: some View {
        Circle()
            .fill(theme.color)
            .frame(width: 24, height: 24)
            .overlay {
                Circle().stroke(borderColor, lineWidth: 1)
            }
    }

    private var borderColor: Color {
        switch theme {
        case .white:
            MochaTheme.secondaryText.opacity(0.35)
        case .black:
            MochaTheme.secondaryText.opacity(0.22)
        default:
            theme.color.opacity(0.55)
        }
    }
}
