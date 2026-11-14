import AppKit
import SwiftUI

@MainActor
final class MonittoAppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: MonittoAppDelegate?
    weak var panelWindow: NSWindow?
    private weak var settingsWindow: NSWindow?
    private weak var monitor: SystemMonitor?
    private var showSettings: (() -> Void)?
    private var defaultsObserver: NSObjectProtocol?
    private var isOpeningSettings = false

    override init() {
        super.init()
        Self.shared = self
    }

    func configure(monitor: SystemMonitor, opener: @escaping () -> Void) {
        self.monitor = monitor
        showSettings = opener
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyPreferences()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.applyPreferences() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let defaultsObserver { NotificationCenter.default.removeObserver(defaultsObserver) }
        NotificationCenter.default.removeObserver(self)
    }

    func registerSettingsWindow(_ window: NSWindow) {
        guard settingsWindow !== window else { return }
        if let settingsWindow {
            NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: settingsWindow)
        }
        settingsWindow = window
        focusSettingsIfReady()
        window.titlebarSeparatorStyle = .none
        window.initialFirstResponder = nil
        window.title = MonittoLocalization.string("Settings")
        NotificationCenter.default.addObserver(
            self, selector: #selector(settingsWillClose), name: NSWindow.willCloseNotification, object: window
        )
    }

    func openSettings() {
        panelWindow?.orderOut(nil)
        isOpeningSettings = true
        NSApp.setActivationPolicy(.regular)
        showSettings?()
        // 用户主动打开设置时，不依赖前台应用让出激活权。
        NSApp.activate(ignoringOtherApps: true)
        focusSettingsIfReady()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        focusSettingsIfReady()
    }

    private func focusSettingsIfReady() {
        guard isOpeningSettings, NSApp.isActive, let settingsWindow else { return }
        settingsWindow.makeKeyAndOrderFront(nil)
        settingsWindow.makeMain()
        isOpeningSettings = false
    }

    @objc private func settingsWillClose() {
        isOpeningSettings = false
        restoreActivationPolicy(settingsVisible: false)
    }

    private func restoreActivationPolicy(settingsVisible: Bool) {
        let showDock = UserDefaults.standard.bool(forKey: PreferenceKey.showDockIcon)
        NSApp.setActivationPolicy(showDock || settingsVisible || isOpeningSettings ? .regular : .accessory)
    }

    private func applyPreferences() {
        let defaults = UserDefaults.standard
        switch AppAppearance(rawValue: defaults.string(forKey: PreferenceKey.appearance) ?? "system") ?? .system {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
        let interval = defaults.object(forKey: PreferenceKey.samplingInterval) as? Double ?? 0.7
        monitor?.setSamplingInterval(interval)
        settingsWindow?.title = MonittoLocalization.string("Settings")
        restoreActivationPolicy(settingsVisible: settingsWindow?.isVisible == true)
    }
}

// 窗口由系统 Settings 场景创建，这里只登记激活和关闭行为。
struct SettingsWindowRegistration: NSViewRepresentable {
    let appDelegate: MonittoAppDelegate

    func makeNSView(context: Context) -> RegistrationView {
        RegistrationView(appDelegate: appDelegate)
    }

    func updateNSView(_ nsView: RegistrationView, context: Context) {
        nsView.window?.title = MonittoLocalization.string("Settings")
    }

    final class RegistrationView: NSView {
        let appDelegate: MonittoAppDelegate

        init(appDelegate: MonittoAppDelegate) {
            self.appDelegate = appDelegate
            super.init(frame: .zero)
        }

        required init?(coder: NSCoder) { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            appDelegate.registerSettingsWindow(window)
        }
    }
}
