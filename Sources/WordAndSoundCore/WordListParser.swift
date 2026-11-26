import Foundation

public enum WordListParser {
    public static let maximumWords = 50_000

    /// Parses one word per line or `word,ipa` CSV. Never throws and never
    /// blocks on malformed input; the caller decides whether the result is usable.
    public static func parse(_ text: String) -> [String] {
        var seen = Set<String>()
        var words: [String] = []
        let lines = text.split(whereSeparator: \.isNewline)
        for (lineIndex, rawLine) in lines.enumerated() {
            var line = String(rawLine).trimmingCharacters(in: .whitespacesAndNewlines)
            if lineIndex == 0 {
                line = line.replacingOccurrences(of: "\u{FEFF}", with: "")
            }
            guard !line.isEmpty else { continue }
            let hadDelimiter = line.contains(",") || line.contains("\t")
            if line.contains(",") {
                line = line.split(separator: ",", maxSplits: 1).first.map(String.init) ?? line
            }
            if line.contains("\t") {
                line = line.split(separator: "\t", maxSplits: 1).first.map(String.init) ?? line
            }
            line = line.trimmingCharacters(in: CharacterSet(charactersIn: "\"' "))
            if lineIndex == 0, hadDelimiter,
               ["word", "lemma", "headword", "term"].contains(line.lowercased()) {
                continue
            }
            guard let cleaned = clean(line) else { continue }
            let key = cleaned.lowercased()
            if seen.insert(key).inserted {
                words.append(cleaned)
                if words.count >= maximumWords { break }
            }
        }
        return words
    }

    public static func clean(_ raw: String) -> String? {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 64 else { return nil }
        while let last = value.last, last.isNumber {
            value.removeLast()
        }
        guard !value.isEmpty else { return nil }
        guard value.range(of: #"^[A-Za-z][A-Za-z'\-]*$"#, options: .regularExpression) != nil else {
            return nil
        }
        if value.count == 1, value != "a", value != "I" { return nil }
        let banned: Set<String> = ["n't"]
        if banned.contains(value.lowercased()) { return nil }
        return value
    }
}
