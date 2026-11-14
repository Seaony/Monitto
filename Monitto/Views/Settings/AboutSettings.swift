import AppKit
import SwiftUI

struct AboutSettings: View {
    @EnvironmentObject private var monitor: SystemMonitor
    @EnvironmentObject private var updates: UpdateController
    @State private var exportError: String?
    @AppStorage(PreferenceKey.appLanguage) private var appLanguage = AppLanguage.english.rawValue

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    var body: some View {
        VStack(spacing: MonittoSettingsSpace.lg) {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 96 * 185 / 824, style: .continuous))
                .accessibilityHidden(true)
            VStack(spacing: MonittoSettingsSpace.xs) {
                Text("Monitto")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(MonittoSettingsTheme.primaryText)
                Text(MonittoLocalization.string("Your Mac, at a glance."))
                Text(MonittoLocalization.format("Version %@ · Build %@", version, build))
                    .monospacedDigit()
                Text(MonittoSystemInfo.description(language: language))
            }
            .font(.callout)
            .foregroundStyle(MonittoSettingsTheme.secondaryText)
            .multilineTextAlignment(.center)
            HStack(spacing: MonittoSettingsSpace.sm) {
                Button {
                    updates.checkForUpdates()
                } label: {
                    Label(MonittoLocalization.string("Check for updates"), systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(!updates.canCheckForUpdates)
                Button {
                    exportDiagnostics()
                } label: {
                    Label(MonittoLocalization.string("Export diagnostics…"), systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive) {
                    NSApp.terminate(nil)
                } label: {
                    Label(MonittoLocalization.string("Quit"), systemImage: "power")
                }
            }
            .fixedSize()
            if let exportError {
                Text(exportError).foregroundStyle(MonittoSettingsTheme.error)
            } else if let configurationError = updates.configurationError {
                Text(MonittoLocalization.string(configurationError)).foregroundStyle(MonittoSettingsTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, MonittoSettingsSpace.xl)
        .padding(.vertical, MonittoSettingsSpace.section)
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: appLanguage) ?? .english
    }

    private func exportDiagnostics() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = MonittoLocalization.string("Monitto Diagnostics.txt")
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let snapshot = monitor.snapshot
        let report = """
        Monitto \(version) (\(build))
        \(MonittoSystemInfo.description(language: language))
        \(MonittoLocalization.string("Host")): \(snapshot.host.name)
        CPU: \(Int(snapshot.cpu.total.rounded()))%
        \(MonittoLocalization.string("Memory")): \(Int(snapshot.memory.usedPercent.rounded()))%
        \(MonittoLocalization.string("Volumes")): \(snapshot.volumes.count)
        \(MonittoLocalization.string("Generated")): \(Date.now.formatted(.dateTime.year().month().day().hour().minute().second().locale(language.locale)))
        """
        do {
            try report.write(to: url, atomically: true, encoding: .utf8)
            exportError = nil
        } catch {
            exportError = error.localizedDescription
        }
    }
}
