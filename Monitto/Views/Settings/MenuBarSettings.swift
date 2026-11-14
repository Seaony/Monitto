import SwiftUI

struct MenuBarSettings: View {
    @EnvironmentObject private var monitor: SystemMonitor
    @Environment(\.locale) private var locale
    @AppStorage(PreferenceKey.compactMenuBar) private var compactMenuBar = false
    @AppStorage(PreferenceKey.menuBarMetric) private var metric = MenuBarMetric.cpu.rawValue
    @AppStorage(PreferenceKey.menuBarItems) private var itemValue = "cpu,memory"
    @AppStorage(PreferenceKey.menuBarDisplayStyle) private var styleValue = MenuBarDisplayStyle.valueOnly.rawValue

    var body: some View {
        MonittoSettingsForm {
            MonittoFormSection(title: localized("Preview")) {
                ScrollView(.horizontal) {
                    HStack(spacing: 14) {
                        ForEach(previewMetrics) { item in
                            HStack(spacing: 5) {
                                if displayStyle != .valueOnly {
                                    MenuBarMiniGraph(
                                        values: previewHistory(item),
                                        color: metricColor(item)
                                    )
                                }
                                if displayStyle != .graphOnly {
                                    if displayStyle == .valueOnly {
                                        Text(previewTag(item))
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(metricColor(item))
                                    }
                                    Text(previewValue(item))
                                        .font(.system(size: 12, weight: .semibold))
                                        .monospacedDigit()
                                }
                            }
                        }
                        Text(Date.now.formatted(.dateTime.weekday(.abbreviated).hour().minute().locale(locale)))
                            .font(.system(size: 12))
                            .foregroundStyle(MonittoSettingsTheme.secondaryText)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: 492, alignment: .trailing)
                    .padding(.vertical, 7)
                }
                .scrollBounceBehavior(.basedOnSize)
                MonittoSideRow(localized("Display style")) {
                    MonittoMenuPicker(
                        title: localized("Display style"),
                        selection: $styleValue,
                        options: MenuBarDisplayStyle.allCases.map { ($0.rawValue, $0.title) }
                    )
                }
            }

            MonittoFormSection(title: localized("Items in menu bar")) {
                ForEach(MenuBarMetric.allCases) { item in
                    Toggle(item.title, isOn: Binding(
                        get: { selectedMetrics.contains(item) },
                        set: { enabled in
                            guard enabled != selectedMetrics.contains(item) else { return }
                            toggle(item)
                        }
                    ))
                    .disabled(selectedMetrics.count == 1 && selectedMetrics.contains(item))
                }
            } footer: {
                Text(localized("Keep at least one menu bar item selected."))
            }
        }
    }

    private func localized(_ key: String) -> String {
        MonittoLocalization.string(key, language: AppLanguage(rawValue: locale.identifier))
    }

    private var selectedMetrics: [MenuBarMetric] {
        let selected = Set(itemValue.split(separator: ",").map(String.init))
        let values = MenuBarMetric.allCases.filter { selected.contains($0.rawValue) }
        return values.isEmpty ? [.cpu] : values
    }

    private var displayStyle: MenuBarDisplayStyle {
        MenuBarDisplayStyle(rawValue: styleValue) ?? .valueOnly
    }

    private var previewMetrics: [MenuBarMetric] {
        compactMenuBar ? Array(selectedMetrics.prefix(1)) : selectedMetrics
    }

    private func toggle(_ item: MenuBarMetric) {
        var values = selectedMetrics
        if let index = values.firstIndex(of: item) {
            guard values.count > 1 else { return }
            values.remove(at: index)
        } else {
            values.append(item)
        }
        itemValue = MenuBarMetric.allCases
            .filter(values.contains)
            .map(\.rawValue)
            .joined(separator: ",")
        metric = values.first?.rawValue ?? MenuBarMetric.cpu.rawValue
    }

    private func previewTag(_ item: MenuBarMetric) -> String {
        switch item {
        case .temperature: localized("Temp")
        default: String(item.title.prefix(3)).uppercased()
        }
    }

    private func previewValue(_ item: MenuBarMetric) -> String {
        switch item {
        case .cpu: "\(Int(monitor.snapshot.cpu.total.rounded()))%"
        case .memory: "\(Int(monitor.snapshot.memory.usedPercent.rounded()))%"
        case .network:
            MonittoByteFormatting.string(
                Int64(max(0, monitor.snapshot.network.downloadBytesPerSecond)), style: .decimal, locale: locale
            )
        case .disk: "\(Int((monitor.snapshot.volumes.first { $0.mountPath == "/" }?.usedPercent ?? 0).rounded()))%"
        case .battery: monitor.snapshot.power.batteryPercent.map { "\(Int($0.rounded()))%" } ?? "—"
        case .temperature:
            monitor.snapshot.power.cpuTemperatureCelsius.map { "\(Int($0.rounded()))°" } ?? "—"
        }
    }

    private func previewHistory(_ item: MenuBarMetric) -> [Double] {
        switch item {
        case .cpu: monitor.cpuHistory
        case .memory: monitor.memoryHistory
        case .network: monitor.downloadHistory
        case .disk: monitor.diskReadHistory
        case .battery: monitor.batteryHistory
        case .temperature: monitor.cpuTemperatureHistory
        }
    }

    private func metricColor(_ item: MenuBarMetric) -> Color {
        switch item {
        case .cpu: MonittoPalette.pink
        case .memory: MonittoPalette.blue
        case .network: MonittoPalette.cyan
        case .disk, .temperature: MonittoPalette.orange
        case .battery: MonittoPalette.green
        }
    }
}

