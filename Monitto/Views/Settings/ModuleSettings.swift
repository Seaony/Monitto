import SwiftUI

struct ModuleSettings: View {
    @Environment(\.locale) private var locale
    @AppStorage(PreferenceKey.showHost) private var showHost = true
    @AppStorage(PreferenceKey.showCPU) private var showCPU = true
    @AppStorage(PreferenceKey.showMemory) private var showMemory = true
    @AppStorage(PreferenceKey.showGPU) private var showGPU = true
    @AppStorage(PreferenceKey.showNetwork) private var showNetwork = true
    @AppStorage(PreferenceKey.showStorage) private var showStorage = true
    @AppStorage(PreferenceKey.showProcesses) private var showProcesses = true
    @AppStorage(PreferenceKey.showPower) private var showPower = true
    @AppStorage(PreferenceKey.summaryGridDensity) private var gridDensityValue = SummaryGridDensity.comfortable.rawValue

    var body: some View {
        MonittoSettingsForm {
            MonittoFormSection(title: localized("Summary cards")) {
                Toggle(localized("Host"), isOn: $showHost)
                Toggle(localized("CPU"), isOn: $showCPU)
                Toggle(localized("Memory"), isOn: $showMemory)
                Toggle(localized("GPU"), isOn: $showGPU)
                Toggle(localized("Network"), isOn: $showNetwork)
                Toggle(localized("Storage"), isOn: $showStorage)
                Toggle(localized("Processes"), isOn: $showProcesses)
                Toggle(localized("Sensors"), isOn: $showPower)
            }

            MonittoFormSection(title: localized("Layout")) {
                MonittoSideRow(localized("Grid density")) {
                    MonittoMenuPicker(
                        title: localized("Grid density"),
                        selection: $gridDensityValue,
                        options: SummaryGridDensity.allCases.map { ($0.rawValue, $0.title) }
                    )
                }
            }
        }
    }

    private func localized(_ key: String) -> String {
        MonittoLocalization.string(key, language: AppLanguage(rawValue: locale.identifier))
    }
}
