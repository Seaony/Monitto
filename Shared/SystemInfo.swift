import Darwin
import Foundation

enum MonittoSystemInfo {
    nonisolated static var versionNumber: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let base = "\(version.majorVersion).\(version.minorVersion)"
        return version.patchVersion == 0 ? base : "\(base).\(version.patchVersion)"
    }

    nonisolated static let buildNumber: String = {
        var size = 0
        guard sysctlbyname("kern.osversion", nil, &size, nil, 0) == 0 else { return "—" }
        var bytes = [CChar](repeating: 0, count: size)
        guard sysctlbyname("kern.osversion", &bytes, &size, nil, 0) == 0 else { return "—" }
        return String(cString: bytes)
    }()

    nonisolated static func versionDescription(language: AppLanguage = MonittoLocalization.currentLanguage) -> String {
        String(
            format: MonittoLocalization.string("macOS %@ (%@)", language: language),
            locale: language.locale,
            versionNumber, buildNumber
        )
    }

    nonisolated static func description(language: AppLanguage = MonittoLocalization.currentLanguage) -> String {
#if arch(arm64)
        let architecture = MonittoLocalization.string("Apple silicon", language: language)
#else
        let architecture = MonittoLocalization.string("Intel", language: language)
#endif
        return "\(architecture) · \(versionDescription(language: language))"
    }
}
