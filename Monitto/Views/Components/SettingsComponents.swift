import AppKit
import SwiftUI

enum MonittoSettingsTheme {
    static let background = adaptive(light: 0xF4F4F3, dark: 0x1F1F21, lightHighContrast: 0xFFFFFF, darkHighContrast: 0x121214)
    static let surface = adaptive(light: 0xEDEDEB, dark: 0x272729, lightHighContrast: 0xEAEAE8, darkHighContrast: 0x222224)
    static let border = adaptive(light: 0xDADAD8, dark: 0x37373A, lightHighContrast: 0x6A6A6E, darkHighContrast: 0xA8A8AC)
    static let controlFill = adaptive(light: 0xE0E0DD, dark: 0x3A3A3E, lightHighContrast: 0xD8D8D5, darkHighContrast: 0x3A3A3E)
    static let primaryText = adaptive(light: 0x1D1D1F, dark: 0xF2F2F4, lightHighContrast: 0x000000, darkHighContrast: 0xFFFFFF)
    static let secondaryText = adaptive(light: 0x616166, dark: 0xA8A8AD, lightHighContrast: 0x3E3E42, darkHighContrast: 0xD4D4D8)
    static let actionText = adaptive(light: 0xFFFFFF, dark: 0xFFFFFF, lightHighContrast: 0xFFFFFF, darkHighContrast: 0x000000)
    static let actionHover = adaptive(light: 0x2466D4, dark: 0x2466D4, lightHighContrast: 0x184FAE, darkHighContrast: 0x8AB8FF)
    static let actionPressed = adaptive(light: 0x1F5BC0, dark: 0x1F5BC0, lightHighContrast: 0x14449A, darkHighContrast: 0xA6C8FF)
    static let disabledText = adaptive(light: 0x505055, dark: 0xB4B4B9, lightHighContrast: 0x2E2E32, darkHighContrast: 0xDCDCE0)
    static let disabledSurface = adaptive(light: 0xE6E6E4, dark: 0x2F2F32, lightHighContrast: 0xE0E0DE, darkHighContrast: 0x2C2C2F)
    static let error = adaptive(light: 0xB4232A, dark: 0xFF7B72, lightHighContrast: 0x7A141A, darkHighContrast: 0xFFA39C)
    static let accent = MonittoPalette.blue
    static let focus = MonittoPalette.blue

    private static func adaptive(
        light: UInt32, dark: UInt32, lightHighContrast: UInt32, darkHighContrast: UInt32
    ) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let match = appearance.bestMatch(from: [
                .aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua
            ])
            let hex: UInt32 = switch match {
            case .darkAqua: dark
            case .accessibilityHighContrastAqua: lightHighContrast
            case .accessibilityHighContrastDarkAqua: darkHighContrast
            default: light
            }
            return NSColor(
                srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        })
    }
}

enum MonittoSettingsSpace {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let section: CGFloat = 32
}

struct MonittoFormSection<Content: View, Footer: View>: View {
    var title: String?
    let content: Content
    let footer: Footer

    init(
        title: String? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        VStack(alignment: .leading, spacing: MonittoSettingsSpace.sm) {
            if let title {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MonittoSettingsTheme.secondaryText)
                    .padding(.horizontal, MonittoSettingsSpace.xs)
            }
            Group(subviews: content) { rows in
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        row.frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, MonittoSettingsSpace.sm)
                        if index < rows.count - 1 {
                            MonittoSeparator().padding(.horizontal, 14)
                        }
                    }
                }
            }
            .background(MonittoSettingsTheme.surface, in: shape)
            .overlay { shape.strokeBorder(MonittoSettingsTheme.border, lineWidth: 0.5) }
            footer.font(.system(size: 12))
                .foregroundStyle(MonittoSettingsTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, MonittoSettingsSpace.xs)
        }
    }
}

extension MonittoFormSection where Footer == EmptyView {
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, content: content, footer: { EmptyView() })
    }
}

struct MonittoSideRow<Label: View, Control: View>: View {
    let label: Label
    let control: Control

    init(@ViewBuilder control: () -> Control, @ViewBuilder label: () -> Label) {
        self.label = label()
        self.control = control()
    }

    var body: some View {
        HStack(spacing: MonittoSettingsSpace.md) {
            label.font(.system(size: 13))
                .foregroundStyle(MonittoSettingsTheme.primaryText)
            Spacer(minLength: 0)
            control
        }
    }
}

extension MonittoSideRow where Label == Text {
    init(_ title: String, @ViewBuilder control: () -> Control) {
        self.init(control: control) { Text(title) }
    }
}

struct MonittoSettingsRowLabel: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(MonittoSettingsTheme.secondaryText.opacity(0.97))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct MonittoFormSwitchStyle: ToggleStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: MonittoSettingsSpace.lg) {
            configuration.label.font(.system(size: 13))
                .foregroundStyle(MonittoSettingsTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
                .pointerStyle(isEnabled ? .link : nil)
        }
    }
}

struct MonittoMenuPicker<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value
    let options: [(value: Value, title: String)]
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let currentTitle = options.first { $0.value == selection }?.title ?? ""
        Menu {
            Picker(title, selection: $selection) {
                ForEach(options, id: \.value) { option in
                    Text(option.title).tag(option.value)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
            // 菜单选项用系统样式，否则表单开关样式会让选项失去动作。
            .toggleStyle(.automatic)
        } label: {
            Text(currentTitle)
        }
        .menuStyle(.button)
        .buttonStyle(MonittoMenuPickerButtonStyle())
        .menuIndicator(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        .pointerStyle(isEnabled ? .link : nil)
        .accessibilityLabel(title)
        .accessibilityValue(currentTitle)
    }
}

private struct MonittoMenuPickerButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        HStack(spacing: MonittoSettingsSpace.xs) {
            configuration.label
                .font(.system(size: 13))
                .foregroundStyle(isEnabled ? MonittoSettingsTheme.primaryText : MonittoSettingsTheme.disabledText)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(MonittoSettingsTheme.secondaryText.opacity(0.75))
                .accessibilityHidden(true)
        }
        .frame(minHeight: 22)
        .background {
            if isEnabled && (hovering || configuration.isPressed) {
                shape.fill(MonittoSettingsTheme.primaryText.opacity(configuration.isPressed ? 0.12 : 0.06))
                    .padding(.horizontal, -4)
            }
        }
        .overlay {
            if isFocused {
                shape.strokeBorder(MonittoSettingsTheme.focus, lineWidth: 2)
                    .padding(.horizontal, -4)
            }
        }
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}

struct MonittoSeparator: View {
    var body: some View {
        Rectangle().fill(MonittoSettingsTheme.border)
            .frame(height: 0.5)
            .accessibilityHidden(true)
    }
}

struct MonittoChoiceButtons<Value: Hashable>: View {
    let options: [Value]
    @Binding var selection: Value
    let title: (Value) -> String
    let symbol: (Value) -> String?
    /// 只显示图标时，文字改作悬停提示和读屏名称。
    var iconOnly = false
    @Namespace private var selectionSpace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                MonittoChoiceSegment(
                    title: title(option), symbol: symbol(option), iconOnly: iconOnly,
                    selected: option == selection, space: selectionSpace
                ) {
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.22)) {
                        selection = option
                    }
                }
            }
        }
        .padding(3)
        .background(
            MonittoSettingsTheme.controlFill,
            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
        )
    }
}

private struct MonittoChoiceSegment: View {
    let title: String
    let symbol: String?
    let iconOnly: Bool
    let selected: Bool
    let space: Namespace.ID
    let action: () -> Void
    @State private var hovering = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol).accessibilityHidden(true)
                }
                if !iconOnly { Text(title) }
            }
            .font(.system(size: 12.5, weight: .medium))
            .foregroundStyle(
                !isEnabled ? MonittoSettingsTheme.disabledText
                    : selected ? MonittoSettingsTheme.actionText : MonittoSettingsTheme.primaryText
            )
            .padding(.horizontal, iconOnly ? MonittoSettingsSpace.sm : 14)
            .frame(height: iconOnly ? 22 : 28)
            .background {
                if selected {
                    shape.fill(isEnabled ? MonittoSettingsTheme.accent : MonittoSettingsTheme.disabledSurface)
                        .matchedGeometryEffect(id: "selected", in: space)
                } else if hovering && isEnabled {
                    shape.fill(MonittoSettingsTheme.primaryText.opacity(0.06))
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(MonittoChoicePressStyle())
        .pointerStyle(isEnabled ? .link : nil)
        .onHover { hovering = $0 }
        .help(iconOnly ? title : "")
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct MonittoChoicePressStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 7, style: .continuous)
        configuration.label
            .overlay {
                shape.fill(MonittoSettingsTheme.primaryText.opacity(configuration.isPressed && isEnabled ? 0.12 : 0))
            }
            .overlay {
                shape.strokeBorder(isFocused ? MonittoSettingsTheme.focus : .clear, lineWidth: 2)
            }
            .offset(y: configuration.isPressed && isEnabled && !reduceMotion ? 1 : 0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct MonittoFlatButtonStyle: ButtonStyle {
    var prominent = false
    var compact = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hovering = false

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: compact ? 6 : 7, style: .continuous)
        return configuration.label
            .font(.system(size: compact ? 11 : 13, weight: .medium))
            .padding(.horizontal, compact ? 0 : 14)
            .frame(width: compact ? 22 : nil, height: compact ? 22 : nil)
            .frame(minHeight: compact ? nil : 28)
            .foregroundStyle(foreground(configuration))
            .background(background(configuration), in: shape)
            .overlay { shape.fill(MonittoSettingsTheme.primaryText.opacity(overlayOpacity(configuration))) }
            .overlay {
                shape.strokeBorder(isFocused ? MonittoSettingsTheme.focus : .clear, lineWidth: 2)
            }
            .contentShape(shape)
            .pointerStyle(isEnabled ? .link : nil)
            .offset(y: configuration.isPressed && isEnabled && !reduceMotion ? 1 : 0)
            .onHover { hovering = $0 }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: hovering)
    }

    private func background(_ configuration: Configuration) -> Color {
        guard isEnabled else { return MonittoSettingsTheme.disabledSurface }
        guard prominent else { return MonittoSettingsTheme.controlFill }
        return configuration.isPressed ? MonittoSettingsTheme.actionPressed
            : hovering ? MonittoSettingsTheme.actionHover : MonittoSettingsTheme.accent
    }

    private func overlayOpacity(_ configuration: Configuration) -> Double {
        guard isEnabled, !prominent else { return 0 }
        if configuration.isPressed { return 0.12 }
        return hovering ? 0.06 : 0
    }

    private func foreground(_ configuration: Configuration) -> Color {
        if !isEnabled { return MonittoSettingsTheme.disabledText }
        if prominent { return MonittoSettingsTheme.actionText }
        return configuration.role == .destructive ? MonittoSettingsTheme.error : MonittoSettingsTheme.primaryText
    }
}

struct MonittoSettingsForm<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        VStack(alignment: .leading, spacing: MonittoSettingsSpace.xl) { content }
            .padding(.horizontal, MonittoSettingsSpace.xl)
            .padding(.vertical, MonittoSettingsSpace.lg)
            .toggleStyle(MonittoFormSwitchStyle())
            .controlSize(.regular)
            .monittoSettingsPageTop()
            .fixedSize(horizontal: false, vertical: true)
            .background(MonittoSettingsTheme.background)
    }
}

extension View {
    func monittoSettingsPageTop() -> some View {
        Group {
            if #available(macOS 26, *) {
                scrollEdgeEffectHidden(true, for: .top)
            } else {
                self
            }
        }
            .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
            .overlay(alignment: .top) { MonittoSeparator() }
    }
}
