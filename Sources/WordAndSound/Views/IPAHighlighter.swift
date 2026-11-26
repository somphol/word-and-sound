import SwiftUI

enum IPAHighlighter {
    static func text(_ ipa: String, targets: [String], kind: String = "onset") -> Text {
        let options: String.CompareOptions = kind.hasPrefix("coda") ? .backwards : []
        for target in targets where !target.isEmpty {
            if let range = ipa.range(of: target, options: options) {
                let prefix = String(ipa[..<range.lowerBound])
                let hit = String(ipa[range])
                let suffix = String(ipa[range.upperBound...])
                return Text(prefix)
                    + Text(hit).foregroundColor(Theme.accent).bold()
                    + Text(suffix)
            }
        }
        return Text(ipa)
    }
}
