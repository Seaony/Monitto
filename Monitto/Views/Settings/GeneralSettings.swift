import AppKit
import ServiceManagement
import SwiftUI

struct GeneralSettings: View {
    @AppStorage(PreferenceKey.appLanguage) private var appLanguage = AppLanguage.english.rawValue
    @AppStorage(PreferenceKey.appearance) private var appearance = AppAppearance.system.rawValue
    @AppStorage(PreferenceKey.samplingInterval) private var samplingInterval = 0.7
    @AppStorage(PreferenceKey.windowZoom) private var windowZoom = 1.0
    @AppStorage(PreferenceKey.showDockIcon) private var showDockIcon = false
    @AppStorage(PreferenceKey.compactMenuBar) private var compactMenuBar = false
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginItemError: String?
    @State private var pendingWindowZoom: Double?

    var body: some View {
        MonittoSettingsForm {
            MonittoFormSection(title: MonittoLocalization.string("Appearance and language")) {
                MonittoSideRow(MonittoLocalization.string("Appearance")) {
                    MonittoChoiceButtons(
                        options: AppAppearance.allCases,
                        selection: Binding(
                            get: { AppAppearance(rawValue: appearance) ?? .system },
                            set: { appearance = $0.rawValue }
                        ),
                        title: appearanceTitle,
                        symbol: appearanceSymbol,
                        iconOnly: true
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(MonittoLocalization.string("Appearance"))
                }
                MonittoSideRow(MonittoLocalization.string("Language")) {
                    MonittoMenuPicker(
                        title: MonittoLocalization.string("Language"),
                        selection: Binding(
                            get: { AppLanguage(rawValue: appLanguage) ?? .english },
                            set: {
                                appLanguage = $0.rawValue
                                MonittoLocalization.setLanguage($0)
                            }
                        ),
                        options: [(.english, "English"), (.simplifiedChinese, "简体中文")]
                    )
                }
            }

            MonittoFormSection(title: MonittoLocalization.string("Sampling and display")) {
                MonittoSideRow(MonittoLocalization.string("Sampling interval")) {
                    MonittoMenuPicker(
                        title: MonittoLocalization.string("Sampling interval"),
                        selection: $samplingInterval,
                        options: [0.3, 0.7, 1.0, 2.0, 5.0].map { interval in
                            let value = interval.rounded() == interval
                                ? String(Int(interval)) : String(format: "%.1f", interval)
                            return (interval, MonittoLocalization.format("%@ s", value))
                        }
                    )
                }
                MonittoSideRow(MonittoLocalization.string("Window zoom")) {
                    HStack(spacing: 8) {
                        Text("0.5×")
                            .font(.system(size: 12))
                            .foregroundStyle(MonittoSettingsTheme.secondaryText)
                        Slider(
                            value: Binding(
                                get: { pendingWindowZoom ?? windowZoom },
                                set: { pendingWindowZoom = $0 }
                            ),
                            in: 0.5...1.5,
                            step: 0.1,
                            onEditingChanged: { isEditing in
                                guard !isEditing, let pendingWindowZoom else { return }
                                windowZoom = pendingWindowZoom
                                self.pendingWindowZoom = nil
                            }
                        )
                        .accessibilityLabel(MonittoLocalization.string("Window zoom"))
                        .frame(width: 110)
                        Text(String(format: "%.1f×", pendingWindowZoom ?? windowZoom))
                            .font(.system(size: 13))
                            .monospacedDigit()
                            .frame(width: 34, alignment: .trailing)
                        Button(MonittoLocalization.string("Reset")) {
                            pendingWindowZoom = nil
                            windowZoom = 1.0
                        }
                        .buttonStyle(MonittoFlatButtonStyle())
                        .fixedSize()
                        .disabled((pendingWindowZoom ?? windowZoom) == 1.0)
                    }
                    .fixedSize()
                }
            } footer: {
                Text(MonittoLocalization.string("Shorter intervals give smoother graphs and use slightly more CPU."))
                Text(MonittoLocalization.string("Zoom applies to the menu bar panel."))
            }

            MonittoFormSection(title: MonittoLocalization.string("Behavior")) {
                Toggle(
                    MonittoLocalization.string("Launch at login"),
                    isOn: Binding(get: { launchAtLogin }, set: updateLoginItem)
                )
                Toggle(MonittoLocalization.string("Show Dock icon"), isOn: $showDockIcon)
                Toggle(isOn: $compactMenuBar) {
                    MonittoSettingsRowLabel(
                        title: MonittoLocalization.string("Compact menu bar"),
                        detail: MonittoLocalization.string("Show only the first selected item")
                    )
                }
            } footer: {
                if let loginItemError {
                    Text(loginItemError).foregroundStyle(MonittoSettingsTheme.error)
                }
            }
        }
    }

    private func appearanceTitle(_ appearance: AppAppearance) -> String {
        MonittoLocalization.string(appearance == .system ? "Follow system" : appearance.rawValue.capitalized)
    }

    private func appearanceSymbol(_ appearance: AppAppearance) -> String? {
        switch appearance {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }

    private func updateLoginItem(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = isEnabled
            loginItemError = nil
        } catch {
            launchAtLogin = SMAppService.mainApp.status == .enabled
            loginItemError = error.localizedDescription
        }
    }

}
