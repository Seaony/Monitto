//
//  MonittoApp.swift
//  Monitto
//
//  Created by seaony on 2026/8/26.
//

import AppKit
import SwiftUI

@main
struct MonittoApp: App {
    @NSApplicationDelegateAdaptor(MonittoAppDelegate.self) private var appDelegate
    @Environment(\.openSettings) private var openSettings
    @StateObject private var monitor = SystemMonitor()
    @StateObject private var updates = UpdateController()
    @AppStorage(PreferenceKey.appLanguage) private var appLanguage = AppLanguage.english.rawValue

    var body: some Scene {
        let _ = appDelegate.configure(monitor: monitor) { openSettings() }
        MenuBarExtra {
            ContentView(onOpenSettings: appDelegate.openSettings)
                .environmentObject(monitor)
                .environmentObject(updates)
                .background(
                    MenuBarWindowPositioner { isVisible in
                        monitor.setPanelVisible(isVisible)
                    }
                )
        } label: {
            MenuBarStatusLabel(monitor: monitor)
        }
        .menuBarExtraStyle(.window)
        Settings {
            SettingsView()
                .environmentObject(monitor)
                .environmentObject(updates)
                .background(SettingsWindowRegistration(appDelegate: appDelegate))
                .containerBackground(MonittoSettingsTheme.background, for: .window)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(MonittoLocalization.string("Settings…", language: selectedLanguage)) {
                    appDelegate.openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(after: .appInfo) {
                CheckForUpdatesCommand(updateController: updates)
            }
            CommandGroup(after: .newItem) {
                Button(MonittoLocalization.string("Refresh", language: selectedLanguage)) {
                    monitor.refresh(forceSlowMetrics: true)
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }

    private var selectedLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguage) ?? .english
    }
}

private struct MenuBarWindowPositioner: NSViewRepresentable {
    let onVisibilityChange: (Bool) -> Void

    func makeNSView(context: Context) -> MenuBarWindowPositioningView {
        MenuBarWindowPositioningView(onVisibilityChange: onVisibilityChange)
    }

    func updateNSView(_ nsView: MenuBarWindowPositioningView, context: Context) {
        nsView.onVisibilityChange = onVisibilityChange
    }
}

@MainActor
private final class MenuBarWindowAnchor {
    static let shared = MenuBarWindowAnchor()

    var centerX: CGFloat?
    var topY: CGFloat?
    var visibleFrame: NSRect?
}

private final class MenuBarWindowPositioningView: NSView {
    var onVisibilityChange: (Bool) -> Void

    private var observers: [NSObjectProtocol] = []
    private let anchor = MenuBarWindowAnchor.shared
    private var isApplyingOrigin = false

    init(onVisibilityChange: @escaping (Bool) -> Void) {
        self.onVisibilityChange = onVisibilityChange
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        removeObservers()
        guard let window else {
            onVisibilityChange(false)
            return
        }

        MonittoAppDelegate.shared?.panelWindow = window

        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                onVisibilityChange(true)
                updateAnchorFromMenuBarClick()
                captureAnchorIfNeeded()
                restoreAnchoredOrigin()
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.onVisibilityChange(false)
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResizeNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.restoreAnchoredOrigin()
            }
        )
        observers.append(
            NotificationCenter.default.addObserver(
                forName: NSWindow.didMoveNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                self?.restoreAnchoredOrigin()
            }
        )

        // The window can exist before it is ever shown; only an on-screen window
        // counts, and `didBecomeKey` covers the moment it is actually opened.
        onVisibilityChange(window.isVisible)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            updateAnchorFromMenuBarClick()
            captureAnchorIfNeeded()
            restoreAnchoredOrigin()
        }
    }

    deinit {
        removeObservers()
    }

    private func removeObservers() {
        observers.forEach(NotificationCenter.default.removeObserver)
        observers.removeAll()
    }

    private func updateAnchorFromMenuBarClick() {
        guard let window, window.isVisible else { return }

        let clickLocation = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { NSMouseInRect(clickLocation, $0.frame, false) }) else {
            return
        }
        guard clickLocation.y >= screen.frame.maxY - NSStatusBar.system.thickness - 8 else { return }

        anchor.centerX = clickLocation.x
        anchor.topY = window.frame.maxY
        anchor.visibleFrame = screen.visibleFrame
    }

    private func captureAnchorIfNeeded() {
        guard let window, window.isVisible else { return }
        if anchor.centerX == nil {
            anchor.centerX = window.frame.midX
        }
        if anchor.topY == nil {
            anchor.topY = window.frame.maxY
        }
        if anchor.visibleFrame == nil {
            anchor.visibleFrame = window.screen?.visibleFrame
        }
    }

    private func restoreAnchoredOrigin() {
        guard !isApplyingOrigin,
              let window,
              window.isVisible,
              let centerX = anchor.centerX,
              let topY = anchor.topY,
              let visibleFrame = anchor.visibleFrame
        else {
            return
        }

        let maximumX = max(visibleFrame.minX, visibleFrame.maxX - window.frame.width)
        let originX = min(
            max(centerX - window.frame.width / 2, visibleFrame.minX),
            maximumX
        )
        let maximumY = max(visibleFrame.minY, visibleFrame.maxY - window.frame.height)
        let originY = min(
            max(topY - window.frame.height, visibleFrame.minY),
            maximumY
        )
        guard abs(window.frame.minX - originX) > 0.5
                || abs(window.frame.minY - originY) > 0.5
        else {
            return
        }

        isApplyingOrigin = true
        window.setFrameOrigin(NSPoint(x: originX, y: originY))
        isApplyingOrigin = false
    }
}

private struct CheckForUpdatesCommand: View {
    @ObservedObject var updateController: UpdateController

    var body: some View {
        Button(MonittoLocalization.string("Check for Updates…")) {
            updateController.checkForUpdates()
        }
        .disabled(!updateController.canCheckForUpdates)
    }
}
