import Foundation

public enum SelfTest {
    public static func run() -> Bool {
        var failures: [String] = []
        print("Word & Sound self-test")

        do {
            let data = try LibraryStore.load()
            let library = data.library

            check(library.categories.count == 3, "expected 3 sound categories, found \(library.categories.count)", &failures)
            let tiles = library.categories.flatMap(\.tiles)
            check(tiles.count >= 60, "expected at least 60 sound tiles, found \(tiles.count)", &failures)
            check(library.mixed.count == 4, "expected 4 mixed lists, found \(library.mixed.count)", &failures)

            var authoredTotal = 0
            var authoredUS = 0
            var authoredUK = 0
            for tile in tiles {
                guard let words = library.lists[tile.listKey], !words.isEmpty else {
                    failures.append("tile \(tile.id) has no list \(tile.listKey)")
                    continue
                }
                authoredTotal += words.count
                for word in words {
                    if data.phoneticUS(for: word) != nil { authoredUS += 1 }
                    if data.phoneticUK(for: word) != nil { authoredUK += 1 }
                }
            }
            for mixed in library.mixed {
                check((library.lists[mixed.id]?.count ?? 0) > 0, "mixed list \(mixed.id) is empty", &failures)
            }
            for tile in tiles {
                check(!tile.targets.isEmpty, "tile \(tile.id) has no IPA target", &failures)
                check(
                    !ArticulationLibrary.components(for: tile.label).isEmpty,
                    "tile \(tile.id) has no articulation guide",
                    &failures
                )
            }
            let guideCount = Set(tiles.flatMap { tile in
                ArticulationLibrary.components(for: tile.label).map(\.id)
            }).count
            print("  articulation guides \(guideCount)")
            if let pairs = data.minimalPairs {
                check(pairs.pairs.count >= 30, "expected at least 30 minimal pairs, found \(pairs.pairs.count)", &failures)
                print("  minimal pairs \(pairs.pairs.count)")
            } else {
                failures.append("minimal pairs bundle is missing")
            }

            let usPct = authoredTotal == 0 ? 0 : Double(authoredUS) / Double(authoredTotal)
            let ukPct = authoredTotal == 0 ? 0 : Double(authoredUK) / Double(authoredTotal)
            check(usPct >= 0.90, String(format: "US IPA coverage %.1f%% is below 90%%", usPct * 100), &failures)
            check(ukPct >= 0.75, String(format: "UK IPA coverage %.1f%% is below 75%%", ukPct * 100), &failures)

            if let patterns = data.patternLists {
                check(patterns.lists.count == tiles.count, "expected \(tiles.count) pattern lists, found \(patterns.lists.count)", &failures)
                for tile in tiles {
                    check((patterns.lists[tile.id]?.count ?? 0) > 0, "pattern list \(tile.id) is empty", &failures)
                }
                let patternWords = patterns.lists.values.reduce(0) { $0 + $1.count }
                print("  built lists \(patterns.lists.count), words \(patternWords)")
            }

            let raw = try LibraryStore.rawData(named: "library", extension: "json")
            let text = String(decoding: raw, as: UTF8.self).lowercased()
            for phrase in ["oxford 5000", "gre words", "toefl", "ef most common", "svl", "secondary school vocabulary", "wellpronounce"] {
                check(!text.contains(phrase), "restricted phrase still present: \(phrase)", &failures)
            }

            print(String(format: "  tiles %d, words %d, US %.1f%%, UK %.1f%%", tiles.count, authoredTotal, usPct * 100, ukPct * 100))
        } catch {
            failures.append(error.localizedDescription)
        }

        var sequencer = PlaybackSequencer(repeatCount: 2, wordCount: 3)
        check(sequencer.completeUtterance() == .repeatWord, "repeat 2 should repeat first", &failures)
        check(sequencer.completeUtterance() == .advance, "repeat 2 should then advance", &failures)
        check(sequencer.index == 1, "repeat 2 should advance to index 1", &failures)

        var wrapping = PlaybackSequencer(repeatCount: 1, wordCount: 2)
        _ = wrapping.completeUtterance()
        _ = wrapping.completeUtterance()
        check(wrapping.index == 0, "sequencer should wrap to the first word", &failures)

        var stopping = PlaybackSequencer(repeatCount: 1, wordCount: 2, wraps: false)
        _ = stopping.completeUtterance()
        check(stopping.completeUtterance() == .finished, "non-wrapping sequencer should finish", &failures)

        let parsed = WordListParser.parse("word\nbass1\n2\nn't\ncat,ipa\ncat")
        check(parsed == ["word", "bass", "cat"], "word list parser failed: \(parsed)", &failures)

        if failures.isEmpty {
            print("PASS")
            return true
        }
        for failure in failures {
            print("FAIL: \(failure)")
        }
        return false
    }

    private static func check(_ condition: Bool, _ message: String, _ failures: inout [String]) {
        if !condition { failures.append(message) }
    }
}
