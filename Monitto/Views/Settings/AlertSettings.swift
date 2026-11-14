import SwiftUI
import UserNotifications

struct AlertSettings: View {
    @AppStorage(PreferenceKey.cpuAlertThreshold) private var cpuThreshold = 85.0
    @AppStorage(PreferenceKey.memoryAlertThreshold) private var memoryThreshold = 90.0
    @AppStorage(PreferenceKey.diskAlertThreshold) private var diskThreshold = 90.0
    @AppStorage(PreferenceKey.temperatureAlertThreshold) private var temperatureThreshold = 80.0
    @AppStorage(PreferenceKey.notificationAlerts) private var notificationAlerts = false
    @AppStorage(PreferenceKey.alertSounds) private var alertSounds = true
    @AppStorage(PreferenceKey.repeatAlerts) private var repeatAlerts = false
    @State private var notificationError: String?

    var body: some View {
        MonittoSettingsForm {
            MonittoFormSection(title: MonittoLocalization.string("Thresholds")) {
                thresholdRow("CPU load", hint: "sustained over 30s", color: MonittoPalette.pink, value: $cpuThreshold)
                thresholdRow("Memory used", color: MonittoPalette.blue, value: $memoryThreshold)
                thresholdRow("CPU temperature", unit: "°C", color: MonittoPalette.orange, value: $temperatureThreshold)
                thresholdRow("Disk space used", hint: "boot volume", color: MonittoPalette.yellow, value: $diskThreshold)
            } footer: {
                if !notificationAlerts {
                    Text(MonittoLocalization.string("Turn on the notification banner below for these limits to alert you."))
                }
            }

            MonittoFormSection(title: MonittoLocalization.string("Delivery")) {
                Toggle(
                    MonittoLocalization.string("Notification banner"),
                    isOn: Binding(get: { notificationAlerts }, set: updateNotifications)
                )
                Toggle(MonittoLocalization.string("Play sound"), isOn: $alertSounds)
                    .disabled(!notificationAlerts)
                Toggle(MonittoLocalization.string("Repeat every 5 min"), isOn: $repeatAlerts)
                    .disabled(!notificationAlerts)
            } footer: {
                if let notificationError {
                    Text(MonittoLocalization.string(notificationError))
                        .foregroundStyle(MonittoSettingsTheme.error)
                }
            }
        }
        .monittoAnimation(value: notificationError)
    }

    private func thresholdRow(
        _ title: String,
        hint: String? = nil,
        unit: String = "%",
        color: Color,
        value: Binding<Double>
    ) -> some View {
        VStack(spacing: 8) {
            MonittoSideRow {
                Text("\(Int(value.wrappedValue))\(unit)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(color)
                    .monospacedDigit()
                    .monittoNumericTransition(value.wrappedValue)
            } label: {
                if let hint {
                    MonittoSettingsRowLabel(
                        title: MonittoLocalization.string(title),
                        detail: MonittoLocalization.string(hint)
                    )
                } else {
                    Text(MonittoLocalization.string(title))
                }
            }

            HStack(alignment: .center, spacing: 10) {
                thresholdButton("−", accessibilityLabel: "Decrease threshold") {
                    value.wrappedValue = max(20, value.wrappedValue - 5)
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(MonittoPalette.track)
                        Capsule()
                            .fill(color)
                            .frame(width: proxy.size.width * value.wrappedValue / 100)
                    }
                    // 加大拖动范围，不挤压细进度条。
                    .overlay {
                        Color.clear
                            .frame(height: 22)
                            .contentShape(Rectangle())
                            .pointerStyle(.columnResize)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { drag in
                                        let fraction = min(max(drag.location.x / max(1, proxy.size.width), 0), 1)
                                        let steps = (fraction * 100 / 5).rounded()
                                        value.wrappedValue = min(100, max(20, steps * 5))
                                    }
                            )
                    }
                }
                .frame(height: 6)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(MonittoLocalization.string(title))
                .accessibilityValue("\(Int(value.wrappedValue))\(unit)")
                .accessibilityAdjustableAction { direction in
                    switch direction {
                    case .increment: value.wrappedValue = min(100, value.wrappedValue + 5)
                    case .decrement: value.wrappedValue = max(20, value.wrappedValue - 5)
                    @unknown default: break
                    }
                }
                thresholdButton("+", accessibilityLabel: "Increase threshold") {
                    value.wrappedValue = min(100, value.wrappedValue + 5)
                }
            }
        }
    }

    private func thresholdButton(
        _ label: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) { Text(label) }
            .buttonStyle(MonittoFlatButtonStyle(compact: true))
            .accessibilityLabel(MonittoLocalization.string(accessibilityLabel))
    }

    private func updateNotifications(_ isEnabled: Bool) {
        guard isEnabled else {
            notificationAlerts = false
            notificationError = nil
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            Task { @MainActor in
                notificationAlerts = granted
                notificationError = error?.localizedDescription
                    ?? (granted ? nil : "Notification permission was not granted.")
            }
        }
    }
}
