import Foundation

enum PreferenceKey {
    static let appLanguage = MonittoLocalization.preferenceKey
    static let appearance = "appearance"
    static let compactMenuBar = "compactMenuBar"
    static let menuBarItems = "menuBarItems"
    static let menuBarItemStyles = "menuBarItemStyles"
    static let showDockIcon = "showDockIcon"
    static let launchAtLogin = "launchAtLogin"
    static let menuBarMetric = "menuBarMetric"
    static let samplingInterval = "samplingInterval"
    static let windowZoom = "windowZoom"
    static let cpuAlertThreshold = "cpuAlertThreshold"
    static let memoryAlertThreshold = "memoryAlertThreshold"
    static let diskAlertThreshold = "diskAlertThreshold"
    static let temperatureAlertThreshold = "temperatureAlertThreshold"
    static let notificationAlerts = "notificationAlerts"
    static let alertSounds = "alertSounds"
    static let repeatAlerts = "repeatAlerts"
    static let summaryCardLayout = "summaryCardLayout"
    static let summaryGridDensity = "summaryGridDensity"

    static let showHost = "showHost"
    static let showCPU = "showCPU"
    static let showMemory = "showMemory"
    static let showGPU = "showGPU"
    static let showNetwork = "showNetwork"
    static let showStorage = "showStorage"
    static let showProcesses = "showProcesses"
    static let showPower = "showPower"
}

enum SummaryGridDensity: String, CaseIterable, Identifiable {
    case compact, comfortable, spacious

    var id: String { rawValue }
    var title: String { MonittoLocalization.string(rawValue.capitalized) }

    var rowHeight: CGFloat {
        switch self {
        case .compact: 185
        case .comfortable: 205
        case .spacious: 225
        }
    }

    var spacing: CGFloat {
        switch self {
        case .compact: 10
        case .comfortable: 12
        case .spacious: 14
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }
    var title: String { MonittoLocalization.string(rawValue.capitalized) }
}

enum MenuBarMetric: String, CaseIterable, Identifiable {
    case cpu, memory, network, disk, battery, temperature

    var id: String { rawValue }

    func title(language: AppLanguage) -> String {
        let key: String = switch self {
        case .cpu: "CPU"
        case .memory: "Memory"
        case .network: "Network"
        case .disk: "Disk"
        case .battery: "Battery"
        case .temperature: "Temp"
        }
        return MonittoLocalization.string(key, language: language)
    }

    var symbol: String {
        switch self {
        case .cpu: "cpu"
        case .memory: "memorychip"
        case .network: "arrow.down"
        case .disk: "internaldrive"
        case .battery: "battery.75percent"
        case .temperature: "thermometer.medium"
        }
    }

    static func selectedItems(_ storedItems: String, fallback: String) -> [Self] {
        let ids = Set(storedItems.split(separator: ",").map(String.init))
        let items = allCases.filter { ids.contains($0.rawValue) }
        return items.isEmpty ? [Self(rawValue: fallback) ?? .cpu] : items
    }

    var defaultRunner: MenuBarRunner? {
        switch self {
        case .cpu: .cat
        case .memory: .hamster
        case .network: .bunny
        case .disk, .battery, .temperature: nil
        }
    }
}

enum MenuBarDisplayStyle: String, CaseIterable {
    case value, graph, graphValue, runner, runnerValue

    var showsRunner: Bool { self == .runner || self == .runnerValue }
    var showsGraph: Bool { self == .graph || self == .graphValue }
    var showsValue: Bool { self != .graph && self != .runner }

    func title(language: AppLanguage) -> String {
        let key: String = switch self {
        case .value: "Value"
        case .graph: "Graph"
        case .graphValue: "Graph + value"
        case .runner: "Character"
        case .runnerValue: "Character + value"
        }
        return MonittoLocalization.string(key, language: language)
    }
}

enum MenuBarRunner: String, CaseIterable {
    case cat, hamster, penguin, bunny

    var frameCount: Int { self == .penguin ? 8 : 6 }

    func title(language: AppLanguage) -> String {
        MonittoLocalization.string(rawValue.capitalized, language: language)
    }
}

struct MenuBarItemStyles {
    struct Item {
        var style: MenuBarDisplayStyle
        var runner: MenuBarRunner?
    }

    private var items: [MenuBarMetric: Item] = [:]

    init(_ rawValue: String) {
        for entry in rawValue.split(separator: ",") {
            let pair = entry.split(separator: "=", maxSplits: 1)
            guard pair.count == 2, let metric = MenuBarMetric(rawValue: String(pair[0])) else { continue }
            let parts = pair[1].split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            let style = MenuBarDisplayStyle(rawValue: String(parts[0]))
            let runner = parts.count == 2 ? MenuBarRunner(rawValue: String(parts[1])) : nil
            let defaults = Self.defaults(for: metric)
            items[metric] = Item(
                style: style.flatMap { $0.showsRunner && defaults.runner == nil ? nil : $0 } ?? defaults.style,
                runner: defaults.runner.flatMap { runner ?? $0 }
            )
        }
    }

    subscript(metric: MenuBarMetric) -> Item {
        get { items[metric] ?? Self.defaults(for: metric) }
        set { items[metric] = newValue }
    }

    var rawValue: String {
        MenuBarMetric.allCases.compactMap { metric in
            guard let item = items[metric] else { return nil }
            let runner = item.runner.map { ":\($0.rawValue)" } ?? ""
            return "\(metric.rawValue)=\(item.style.rawValue)\(runner)"
        }.joined(separator: ",")
    }

    private static func defaults(for metric: MenuBarMetric) -> Item {
        Item(style: metric == .cpu ? .runnerValue : .value, runner: metric.defaultRunner)
    }
}
