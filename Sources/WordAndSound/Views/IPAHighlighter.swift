import SwiftUI

enum IPAHighlighter {
    static func text(_ ipa: String, targets: [String], kind: String = "onset") -> Text {
        let options: String.CompareOptions = kind.hasPrefix("coda") ? .backwards : []
        for target in targets where !target.isEmpty {
            for candidate in candidates(for: target) {
                if let range = ipa.range(of: candidate, options: options) {
                    let prefix = String(ipa[..<range.lowerBound])
                    let hit = String(ipa[range])
                    let suffix = String(ipa[range.upperBound...])
                    return Text(prefix)
                        + Text(hit).foregroundColor(Theme.accent).bold()
                        + Text(suffix)
                }
            }
        }
        return Text(ipa)
    }

    private static func candidates(for target: String) -> [String] {
        var values = [target]
        let alternatives = [
            target.replacingOccurrences(of: "r", with: "ɹ"),
            target.replacingOccurrences(of: "g", with: "ɡ"),
            target.replacingOccurrences(of: "l", with: "ɫ"),
        ]
        for value in alternatives where !values.contains(value) {
            values.append(value)
        }
        return values
    }
}
