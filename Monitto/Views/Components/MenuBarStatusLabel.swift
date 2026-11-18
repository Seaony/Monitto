import AppKit
import SwiftUI

struct MenuBarStatusLabel: View {
    @ObservedObject var monitor: SystemMonitor
    @AppStorage(PreferenceKey.compactMenuBar) private var compactMenuBar = false
    @AppStorage(PreferenceKey.menuBarMetric) private var menuBarMetric = MenuBarMetric.cpu.rawValue
    @AppStorage(PreferenceKey.menuBarItems) private var menuBarItems = "cpu,memory"
    @AppStorage(PreferenceKey.menuBarItemStyles) private var menuBarItemStyles = ""
    @AppStorage(PreferenceKey.appLanguage) private var appLanguage = AppLanguage.english.rawValue

    @ObservedObject private var playback = MenuBarRunnerPlayback.shared
    @State private var overlays = MenuBarStatusOverlays()

    var body: some View {
        let language = AppLanguage(rawValue: appLanguage) ?? .english
        let selected = MenuBarMetric.selectedItems(menuBarItems, fallback: menuBarMetric)
        let visible = compactMenuBar ? Array(selected.prefix(1)) : selected
        let styles = MenuBarItemStyles(menuBarItemStyles)
        let items = visible.map { MenuBarStrip.Item($0, setting: styles[$0], monitor: monitor, language: language) }
        let renderer = MenuBarGraphRenderer(items: items)
        renderer.label(includesCharacters: false)
            .onAppear { overlays.update(renderer, isPaused: playback.isPaused) }
            .onChange(of: items) { overlays.update(renderer, isPaused: playback.isPaused) }
            .onChange(of: playback.isPaused) { overlays.update(renderer, isPaused: playback.isPaused) }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)) { _ in
                overlays.update(renderer, isPaused: playback.isPaused)
            }
            .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)) { _ in
                overlays.update(renderer, isPaused: playback.isPaused)
            }
            .onDisappear { overlays.removeAll() }
            .monittoAnimation(value: menuBarItems)
            .monittoAnimation(value: menuBarItemStyles)
    }
}

struct MenuBarStrip: View {
    struct Item: Identifiable, Equatable {
        let id: MenuBarMetric
        let name: String
        let tag: String
        let value: String
        let style: MenuBarDisplayStyle
        let graph: [Double]
        let runner: MenuBarRunner?
        let framesPerSecond: Double

        init(
            id: MenuBarMetric, name: String, tag: String, value: String,
            style: MenuBarDisplayStyle, graph: [Double] = [],
            runner: MenuBarRunner? = nil, framesPerSecond: Double = 2
        ) {
            self.id = id
            self.name = name
            self.tag = tag
            self.value = value
            self.style = style
            self.graph = graph
            self.runner = runner
            self.framesPerSecond = framesPerSecond
        }

        init(_ metric: MenuBarMetric, setting: MenuBarItemStyles.Item, monitor: SystemMonitor, language: AppLanguage) {
            let name = metric.title(language: language)
            let snapshot = monitor.snapshot
            self.init(
                id: metric,
                name: name,
                tag: String(name.prefix(3)).uppercased(),
                value: Self.value(for: metric, snapshot: snapshot, language: language),
                style: setting.style,
                graph: setting.style.showsGraph ? Self.history(for: metric, monitor: monitor) : [],
                runner: setting.style.showsRunner ? setting.runner : nil,
                framesPerSecond: setting.style.showsRunner ? MenuBarRunnerSpeed.framesPerSecond(for: metric, snapshot: snapshot) : 2
            )
        }

        private static func value(for metric: MenuBarMetric, snapshot: SystemSnapshot, language: AppLanguage) -> String {
            switch metric {
            case .cpu: "\(Int(snapshot.cpu.total.rounded()))%"
            case .memory: "\(Int(snapshot.memory.usedPercent.rounded()))%"
            case .network:
                "↓" + MonittoByteFormatting.string(
                    Int64(max(0, snapshot.network.downloadBytesPerSecond)),
                    style: .decimal, locale: language.locale
                ) + "/s"
            case .disk: "\(Int((snapshot.volumes.first { $0.mountPath == "/" }?.usedPercent ?? 0).rounded()))%"
            case .battery: snapshot.power.batteryPercent.map { "\(Int($0.rounded()))%" } ?? "—"
            case .temperature: snapshot.power.cpuTemperatureCelsius.map { "\(Int($0.rounded()))°" } ?? "—"
            }
        }

        private static func history(for metric: MenuBarMetric, monitor: SystemMonitor) -> [Double] {
            switch metric {
            case .cpu: monitor.cpuHistory
            case .memory: monitor.memoryHistory
            case .network: monitor.downloadHistory
            case .disk: monitor.diskReadHistory
            case .battery: monitor.batteryHistory
            case .temperature: monitor.cpuTemperatureHistory
            }
        }
    }

    let items: [Item]
    var playsCharacters = true

    @ObservedObject private var playback = MenuBarRunnerPlayback.shared

    var body: some View {
        let renderer = MenuBarGraphRenderer(items: items)
        renderer.label(includesCharacters: !playsCharacters)
            .overlay {
                if playsCharacters && !renderer.placements.isEmpty {
                    MenuBarRunnerOverlay(placements: renderer.placements, isPaused: playback.isPaused)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }
}

private struct MenuBarGraphRenderer {
    private struct Drawing {
        let x: CGFloat
        let graphicWidth: CGFloat
        let graph: [Double]?
        let runner: MenuBarRunner?
        let text: String?
        let textSize: NSSize
        let attributes: [NSAttributedString.Key: Any]
    }

    private static let graphSize = NSSize(width: 22, height: 12)
    private static let itemSpacing: CGFloat = 8
    private static let graphTextSpacing: CGFloat = 4
    private static let taggedAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular),
        .foregroundColor: NSColor.black,
    ]
    private static let valueAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
        .foregroundColor: NSColor.black,
    ]

    let size: NSSize
    let placements: [MenuBarRunnerPlacement]
    let accessibilityLabel: String
    private let drawings: [Drawing]

    init(items: [MenuBarStrip.Item]) {
        var x: CGFloat = 0
        var drawings: [Drawing] = []
        var placements: [MenuBarRunnerPlacement] = []
        for item in items {
            let graph = item.style.showsGraph ? item.graph : nil
            var graphicWidth = graph == nil ? 0 : Self.graphSize.width
            if let runner = item.runner {
                graphicWidth = MenuBarRunnerFrames.images[runner]![0].size.width
                placements.append(.init(metric: item.id, runner: runner, origin: x, framesPerSecond: item.framesPerSecond))
            }
            let showsTag = item.style == .value
            let text = item.style.showsValue ? (showsTag ? "\(item.tag) \(item.value)" : item.value) : nil
            let attributes = showsTag ? Self.taggedAttributes : Self.valueAttributes
            let textSize = text.map { ($0 as NSString).size(withAttributes: attributes) } ?? .zero
            drawings.append(.init(x: x, graphicWidth: graphicWidth, graph: graph, runner: item.runner,
                                  text: text, textSize: textSize, attributes: attributes))
            if graphicWidth > 0 && textSize.width > 0 { x += Self.graphTextSpacing }
            x += graphicWidth + textSize.width + Self.itemSpacing
        }
        self.drawings = drawings
        self.placements = placements
        accessibilityLabel = items.map { "\($0.name) \($0.value)" }.joined(separator: ", ")
        size = NSSize(width: max(1, ceil(x - Self.itemSpacing)), height: 16)
    }

    func label(includesCharacters: Bool) -> some View {
        let image = NSImage(size: size, flipped: false) { bounds in
            for drawing in drawings {
                if let values = drawing.graph {
                    Self.drawGraph(values, in: NSRect(
                        x: drawing.x, y: bounds.midY - Self.graphSize.height / 2,
                        width: Self.graphSize.width, height: Self.graphSize.height
                    ))
                } else if includesCharacters, let runner = drawing.runner {
                    let frame = MenuBarRunnerFrames.templates[runner]![0]
                    frame.draw(in: NSRect(x: drawing.x, y: bounds.midY - frame.size.height / 2,
                                          width: frame.size.width, height: frame.size.height))
                }
                if let text = drawing.text {
                    let textX = drawing.x + (drawing.graphicWidth > 0 ? drawing.graphicWidth + Self.graphTextSpacing : 0)
                    (text as NSString).draw(
                        at: NSPoint(x: textX, y: floor(bounds.midY - drawing.textSize.height / 2)),
                        withAttributes: drawing.attributes
                    )
                }
            }
            return true
        }
        image.isTemplate = true
        return Image(nsImage: image)
            .renderingMode(.template)
            .accessibilityLabel(accessibilityLabel)
    }

    private static func drawGraph(_ source: [Double], in bounds: NSRect) {
        let values = Array(source.suffix(18))
        guard !values.isEmpty else { return }
        let minimum = values.min() ?? 0
        let maximum = values.max() ?? minimum
        let horizontalInset: CGFloat = 1
        let verticalInset: CGFloat = 1
        let drawingWidth = max(0, bounds.width - horizontalInset * 2)
        let drawingHeight = max(0, bounds.height - verticalInset * 2)
        let path = NSBezierPath()
        path.lineWidth = 1.2
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        for (index, value) in values.enumerated() {
            let fraction = maximum > minimum ? (value - minimum) / (maximum - minimum) : 0.5
            let x = bounds.minX + horizontalInset
                + drawingWidth * CGFloat(index) / CGFloat(max(1, values.count - 1))
            let y = bounds.minY + verticalInset + drawingHeight * CGFloat(fraction)
            let point = NSPoint(x: x, y: y)
            if index == 0 {
                path.move(to: point)
            } else {
                path.line(to: point)
            }
        }

        if values.count == 1 {
            path.line(to: NSPoint(x: bounds.maxX - horizontalInset, y: path.currentPoint.y))
        }
        NSColor.black.setStroke()
        path.stroke()
    }
}

// 菜单栏场景会把 SwiftUI 标签转成静态图片，只把动画放在状态栏窗口的图层上。
private final class MenuBarStatusOverlays {
    private weak var button: NSStatusBarButton?
    private var views: [ObjectIdentifier: MenuBarRunnerOverlayView] = [:]
    private var pendingUpdate: DispatchWorkItem?

    func update(_ renderer: MenuBarGraphRenderer, isPaused: Bool) {
        pendingUpdate?.cancel()
        // 标签尺寸由 SwiftUI 写进按钮，下一轮主线程再对齐图层。
        let work = DispatchWorkItem { [weak self] in
            self?.attach(renderer, isPaused: isPaused)
        }
        pendingUpdate = work
        DispatchQueue.main.async(execute: work)
    }

    func removeAll() {
        pendingUpdate?.cancel()
        pendingUpdate = nil
        views.values.forEach { $0.removeFromSuperview() }
        views.removeAll()
    }

    private func attach(_ renderer: MenuBarGraphRenderer, isPaused: Bool) {
        let attachedButton = button.flatMap { $0.window == nil ? nil : $0 }
        let button = attachedButton ?? NSApp.windows.lazy.compactMap { window in
            window.contentView.flatMap { Self.statusButton(in: $0) }
        }.first
        guard let button, let primary = button.window else { return }
        self.button = button
        guard !renderer.placements.isEmpty else {
            removeAll()
            return
        }

        // AppKit 为其他屏幕建立同类状态栏窗口。只给当前有屏幕的窗口挂图层。
        let roots: [NSView] = [button] + NSApp.windows.compactMap { window in
            guard window !== primary, type(of: window) == type(of: primary),
                  window.isVisible, window.screen != nil else { return nil }
            return window.contentView
        }
        let active = Set(roots.map(ObjectIdentifier.init))
        for key in views.keys where !active.contains(key) {
            views.removeValue(forKey: key)?.removeFromSuperview()
        }

        for root in roots {
            let key = ObjectIdentifier(root)
            let overlay: MenuBarRunnerOverlayView
            if let existing = views[key] {
                overlay = existing
            } else {
                overlay = MenuBarRunnerOverlayView()
                overlay.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
                root.addSubview(overlay, positioned: .above, relativeTo: nil)
                views[key] = overlay
            }
            let scale = root.window?.backingScaleFactor ?? 1
            overlay.frame = CGRect(
                x: ((root.bounds.midX - renderer.size.width / 2) * scale).rounded() / scale,
                y: ((root.bounds.midY - renderer.size.height / 2) * scale).rounded() / scale,
                width: renderer.size.width,
                height: renderer.size.height
            )
            overlay.update(renderer.placements, isPaused: isPaused)
        }
    }

    private static func statusButton(in view: NSView) -> NSStatusBarButton? {
        if let button = view as? NSStatusBarButton { return button }
        return view.subviews.lazy.compactMap { statusButton(in: $0) }.first
    }
}
