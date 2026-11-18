import SwiftUI

struct MenuBarSettings: View {
    @EnvironmentObject private var monitor: SystemMonitor
    @Environment(\.locale) private var locale
    @AppStorage(PreferenceKey.compactMenuBar) private var compactMenuBar = false
    @AppStorage(PreferenceKey.menuBarMetric) private var metric = MenuBarMetric.cpu.rawValue
    @AppStorage(PreferenceKey.menuBarItems) private var itemValue = "cpu,memory"
    @AppStorage(PreferenceKey.menuBarItemStyles) private var styleValue = ""

    var playsCharacters = true

    var body: some View {
        let selected = MenuBarMetric.selectedItems(itemValue, fallback: metric)
        let visible = compactMenuBar ? Array(selected.prefix(1)) : selected
        let styles = MenuBarItemStyles(styleValue)
        let displayStyleTitle = localized("Display style")
        let characterTitle = localized("Character")

        MonittoSettingsForm {
            MonittoFormSection(title: localized("Preview")) {
                ScrollView(.horizontal) {
                    HStack(spacing: 14) {
                        MenuBarStrip(
                            items: visible.map { MenuBarStrip.Item($0, setting: styles[$0], monitor: monitor, language: language) },
                            playsCharacters: playsCharacters
                        )
                        Text(Date.now.formatted(.dateTime.weekday(.abbreviated).hour().minute().locale(locale)))
                            .font(.system(size: 12))
                            .foregroundStyle(MonittoSettingsTheme.secondaryText)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: 492, alignment: .trailing)
                    .padding(.vertical, 7)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            MonittoFormSection(title: localized("Items in menu bar")) {
                ForEach(MenuBarMetric.allCases) { item in
                    let title = item.title(language: language)
                    let setting = styles[item]
                    let isSelected = selected.contains(item)
                    VStack(alignment: .leading, spacing: MonittoSettingsSpace.xs) {
                        Toggle(title, isOn: Binding(
                            get: { isSelected },
                            set: { enabled in
                                guard enabled != isSelected else { return }
                                toggle(item, selected: selected)
                            }
                        ))
                        .frame(minHeight: 28)
                        .disabled(selected.count == 1 && isSelected)

                        if isSelected {
                            VStack(alignment: .leading, spacing: MonittoSettingsSpace.xs) {
                                HStack(spacing: MonittoSettingsSpace.md) {
                                    Text(displayStyleTitle)
                                    Spacer(minLength: 0)
                                    MonittoMenuPicker(
                                        title: "\(title) · \(displayStyleTitle)",
                                        selection: style(for: item),
                                        options: MenuBarDisplayStyle.allCases
                                            .filter { !$0.showsRunner || item.defaultRunner != nil }
                                            .map { ($0, $0.title(language: language)) }
                                    )
                                }

                                if setting.style.showsRunner, let runner = setting.runner {
                                    HStack(alignment: .top, spacing: MonittoSettingsSpace.md) {
                                        Text(characterTitle)
                                            .padding(.top, MonittoSettingsSpace.sm)
                                        Spacer(minLength: 0)
                                        MenuBarCharacterPicker(
                                            selection: self.runner(for: item, default: runner),
                                            language: language
                                        )
                                        .accessibilityElement(children: .contain)
                                        .accessibilityLabel("\(title) · \(characterTitle)")
                                    }
                                    .transition(MonittoMotion.disclosureTransition)
                                }
                            }
                            .font(.system(size: 12))
                            .foregroundStyle(MonittoSettingsTheme.secondaryText)
                            .padding(.leading, MonittoSettingsSpace.lg)
                            .padding(.bottom, MonittoSettingsSpace.xs)
                            .transition(MonittoMotion.disclosureTransition)
                        }
                    }
                }
            } footer: {
                Text(localized("Keep at least one menu bar item selected."))
            }
            .monittoAnimation(MonittoMotion.disclosure, value: selected)
            .monittoAnimation(MonittoMotion.disclosure, value: selected.filter { styles[$0].style.showsRunner })
        }
    }

    private var language: AppLanguage { AppLanguage(rawValue: locale.identifier) ?? .english }

    private func localized(_ key: String) -> String {
        MonittoLocalization.string(key, language: language)
    }

    private func style(for item: MenuBarMetric) -> Binding<MenuBarDisplayStyle> {
        Binding {
            MenuBarItemStyles(styleValue)[item].style
        } set: { value in
            var preferences = MenuBarItemStyles(styleValue)
            preferences[item].style = value
            styleValue = preferences.rawValue
        }
    }

    private func runner(for item: MenuBarMetric, default runner: MenuBarRunner) -> Binding<MenuBarRunner> {
        Binding {
            MenuBarItemStyles(styleValue)[item].runner ?? runner
        } set: { value in
            var preferences = MenuBarItemStyles(styleValue)
            preferences[item].runner = value
            styleValue = preferences.rawValue
        }
    }

    private func toggle(_ item: MenuBarMetric, selected: [MenuBarMetric]) {
        var values = selected
        if let index = values.firstIndex(of: item) {
            guard values.count > 1 else { return }
            values.remove(at: index)
        } else {
            values.append(item)
        }
        itemValue = MenuBarMetric.allCases.filter(values.contains).map(\.rawValue).joined(separator: ",")
        metric = values.first?.rawValue ?? MenuBarMetric.cpu.rawValue
    }
}

private struct MenuBarCharacterPicker: View {
    @Binding var selection: MenuBarRunner
    let language: AppLanguage

    var body: some View {
        HStack(spacing: MonittoSettingsSpace.sm) {
            ForEach(MenuBarRunner.allCases, id: \.self) { runner in
                let title = runner.title(language: language)
                let isSelected = runner == selection
                Button {
                    selection = runner
                } label: {
                    VStack(spacing: MonittoSettingsSpace.xs) {
                        Image(nsImage: MenuBarRunnerFrames.images[runner]![0])
                            .renderingMode(.template)
                            .accessibilityHidden(true)
                        Text(title)
                            .font(.system(size: 11))
                            .lineLimit(1)
                    }
                    .padding(MonittoSettingsSpace.sm)
                    .frame(minWidth: MonittoSettingsSpace.section * 2)
                    .foregroundStyle(MonittoSettingsTheme.primaryText)
                }
                .buttonStyle(MenuBarCharacterButtonStyle(isSelected: isSelected))
                .accessibilityLabel(title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

private struct MenuBarCharacterButtonStyle: ButtonStyle {
    let isSelected: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: MonittoSettingsSpace.sm, style: .continuous)
        let highlight = isEnabled && (isHovering || configuration.isPressed)
        let fill = isSelected
            ? MonittoSettingsTheme.accent.opacity(highlight ? 0.20 : 0.12)
            : MonittoSettingsTheme.primaryText.opacity(highlight ? 0.07 : 0)

        configuration.label
            .background(fill, in: shape)
            .overlay {
                shape.strokeBorder(
                    isSelected || isFocused ? MonittoSettingsTheme.accent : MonittoSettingsTheme.border,
                    lineWidth: isFocused ? 2 : 1
                )
            }
            .contentShape(shape)
            .pointerStyle(isEnabled ? .link : nil)
            .onHover { isHovering = $0 }
            .monittoAnimation(MonittoMotion.press, value: isHovering)
            .monittoAnimation(MonittoMotion.press, value: configuration.isPressed)
    }
}
