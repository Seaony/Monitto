import AppKit
import SwiftUI

enum SettingsSection: String, CaseIterable, Identifiable {
    case general, menuBar, alerts, modules, about

    var id: String { rawValue }

    var title: String {
        let key: String = switch self {
        case .general: "General"
        case .menuBar: "Menu Bar"
        case .alerts: "Alerts"
        case .modules: "Modules"
        case .about: "About"
        }
        return MonittoLocalization.string(key)
    }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .menuBar: "menubar.rectangle"
        case .alerts: "bell"
        case .modules: "square.grid.2x2"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @State private var section: SettingsSection = .general
    @AppStorage(PreferenceKey.appLanguage) private var appLanguage = AppLanguage.english.rawValue

    var body: some View {
        TabView(selection: $section) {
            ForEach(SettingsSection.allCases) { item in
                MonittoSettingsScrollablePage {
                    Group {
                        switch item {
                        case .general: GeneralSettings()
                        case .menuBar: MenuBarSettings()
                        case .alerts: AlertSettings()
                        case .modules: ModuleSettings()
                        case .about: AboutSettings()
                        }
                    }
                }
                .tabItem { Label(item.title, systemImage: item.symbol) }
                .tag(item)
            }
        }
        .id(appLanguage)
        .frame(width: 560)
        .fixedSize(horizontal: false, vertical: true)
        .background(MonittoSettingsTheme.background)
        .buttonStyle(MonittoFlatButtonStyle())
        .toggleStyle(MonittoFormSwitchStyle())
        .controlSize(.small)
        .tint(MonittoSettingsTheme.accent)
        .foregroundStyle(MonittoSettingsTheme.primaryText)
        .environment(\.locale, (AppLanguage(rawValue: appLanguage) ?? .english).locale)
    }
}

// 短页随内容收缩，长页限高滚动，不让内容进入工具栏。
struct MonittoSettingsScrollablePage<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var contentHeight: CGFloat = 640

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: .infinity)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        }
        .frame(height: min(640, contentHeight))
        .clipped()
        .scrollBounceBehavior(.basedOnSize)
        .monittoSettingsPageTop()
        .background(MonittoSettingsTheme.background)
    }
}
