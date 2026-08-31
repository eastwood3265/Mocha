import SwiftUI

struct SettingsDashboardView: View {
    @AppStorage(AppThemeColor.storageKey) private var selectedThemeRawValue = AppThemeColor.lemon.rawValue
    @AppStorage(ProfitColorStyle.storageKey) private var profitColorStyleRawValue = ProfitColorStyle.defaultStyle.rawValue
    @AppStorage(GoldenBucketSettings.negativeBalanceWarningKey) private var negativeBalanceWarningEnabled = true
    @AppStorage(WeeklyFundSyncReminder.enabledKey) private var weeklyFundSyncReminderEnabled = false
    @State private var reminderError: String?

    private var selectedTheme: AppThemeColor {
        AppThemeColor(rawValue: selectedThemeRawValue) ?? .lemon
    }

    var body: some View {
        NavigationStack {
            List {
                Section("数据") {
                    NavigationLink {
                        StatementImportDashboardView()
                    } label: {
                        Label("账单导入", systemImage: "doc.text.magnifyingglass")
                    }
                }

                Section {
                    Toggle("每周基金同步提醒", isOn: $weeklyFundSyncReminderEnabled)
                        .tint(MochaTheme.yellow)
                        .onChange(of: weeklyFundSyncReminderEnabled) { _, enabled in
                            Task {
                                do {
                                    try await WeeklyFundSyncReminder.setEnabled(enabled)
                                } catch {
                                    weeklyFundSyncReminderEnabled = false
                                    reminderError = error.localizedDescription
                                }
                            }
                        }
                } header: {
                    Text("基金同步")
                } footer: {
                    Text("每周日 20:00 提醒从基金 E 账户导出持仓。邮件收到 XLSX 后，可用快捷指令中的“导入基金持仓”交给 Mocha 预览。")
                }

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
                    Picker("收益颜色", selection: $profitColorStyleRawValue) {
                        ForEach(ProfitColorStyle.allCases) { style in
                            Text(style.title).tag(style.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("收益显示")
                } footer: {
                    Text("只影响投资收益的正负颜色，零收益保持中性。")
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
        .alert("无法开启提醒", isPresented: Binding(
            get: { reminderError != nil },
            set: { if !$0 { reminderError = nil } }
        )) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text(reminderError ?? "未知错误")
        }
    }
}

private struct ThemeColorSwatch: View {
    let theme: AppThemeColor

    var body: some View {
        Text("Aa")
            .font(.caption2.bold())
            .foregroundStyle(theme.foregroundColor)
            .frame(width: 34, height: 26)
            .background(theme.color, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            }
    }

    private var borderColor: Color {
        switch theme {
        case .white:
            MochaTheme.secondaryText.opacity(0.35)
        case .black:
            theme.foregroundColor.opacity(0.28)
        default:
            theme.foregroundColor.opacity(0.20)
        }
    }
}
