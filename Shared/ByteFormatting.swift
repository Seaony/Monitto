import Foundation

enum MonittoByteFormatting {
    nonisolated static func string(_ value: Int64, style: ByteCountFormatStyle.Style, locale: Locale) -> String {
        value.formatted(
            .byteCount(style: style, allowedUnits: .all.subtracting(.bytes), spellsOutZero: false)
                .locale(locale)
        )
        // Foundation 用 kB，界面沿用原来的 KB。
        .replacingOccurrences(of: "kB", with: "KB")
    }
}
