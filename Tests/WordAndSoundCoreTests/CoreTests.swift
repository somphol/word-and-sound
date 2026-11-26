import XCTest
@testable import WordAndSoundCore

final class PlaybackSequencerTests: XCTestCase {
    func testRepeatsBeforeAdvancing() {
        var sequencer = PlaybackSequencer(repeatCount: 3, wordCount: 2)
        XCTAssertEqual(sequencer.completeUtterance(), .repeatWord)
        XCTAssertEqual(sequencer.completeUtterance(), .repeatWord)
        XCTAssertEqual(sequencer.completeUtterance(), .advance)
        XCTAssertEqual(sequencer.index, 1)
        XCTAssertEqual(sequencer.repeatIndex, 0)
    }

    func testWrapsAtEnd() {
        var sequencer = PlaybackSequencer(repeatCount: 1, wordCount: 2)
        XCTAssertEqual(sequencer.completeUtterance(), .advance)
        XCTAssertEqual(sequencer.index, 1)
        XCTAssertEqual(sequencer.completeUtterance(), .advance)
        XCTAssertEqual(sequencer.index, 0)
    }

    func testCanStopAtEnd() {
        var sequencer = PlaybackSequencer(repeatCount: 1, wordCount: 2, wraps: false)
        XCTAssertEqual(sequencer.completeUtterance(), .advance)
        XCTAssertEqual(sequencer.completeUtterance(), .finished)
    }

    func testManualNavigationResetsRepeat() {
        var sequencer = PlaybackSequencer(repeatCount: 4, wordCount: 3)
        _ = sequencer.completeUtterance()
        sequencer.next()
        XCTAssertEqual(sequencer.index, 1)
        XCTAssertEqual(sequencer.repeatIndex, 0)
        sequencer.previous()
        XCTAssertEqual(sequencer.index, 0)
        sequencer.previous()
        XCTAssertEqual(sequencer.index, 2)
    }
}

final class WordListParserTests: XCTestCase {
    func testCleansLinesAndDeduplicates() {
        let words = WordListParser.parse("word\nbass1\n2\nn't\ncat,ipa\ncat\n\n  dog  ")
        XCTAssertEqual(words, ["word", "bass", "cat", "dog"])
    }

    func testRejectsPhrasesAndPunctuation() {
        let words = WordListParser.parse("ice cream\nhello!\nok\npier's")
        XCTAssertEqual(words, ["ok", "pier's"])
    }

    func testSkipsHeaderRow() {
        let words = WordListParser.parse("word,ipa\nthink,/θɪŋk/\n")
        XCTAssertEqual(words, ["think"])
    }
}

final class ReviewSchedulerTests: XCTestCase {
    func testCorrectAnswerAdvancesInterval() {
        XCTAssertEqual(ReviewScheduler.nextStep(current: 0, correct: true), 1)
        XCTAssertEqual(ReviewScheduler.nextStep(current: 4, correct: true), 4)
        XCTAssertEqual(ReviewScheduler.nextStep(current: 2, correct: false), 0)
    }

    func testDueDateUsesInterval() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let due = ReviewScheduler.nextDue(step: 2, from: start, calendar: Calendar(identifier: .gregorian))
        XCTAssertEqual(due.timeIntervalSince(start), 7 * 86_400, accuracy: 1)
    }

    func testDueCheck() {
        let now = Date()
        XCTAssertTrue(ReviewScheduler.isDue(now.addingTimeInterval(-1), now: now))
        XCTAssertFalse(ReviewScheduler.isDue(now.addingTimeInterval(60), now: now))
        XCTAssertFalse(ReviewScheduler.isDue(nil, now: now))
    }
}

final class ArticulationTests: XCTestCase {
    func testEveryTileHasAGuide() throws {
        let data = try LibraryStore.load()
        for tile in data.library.categories.flatMap(\.tiles) {
            XCTAssertFalse(
                ArticulationLibrary.components(for: tile.label).isEmpty,
                "no articulation guide for \(tile.id) / \(tile.label)"
            )
        }
    }

    func testRandSHaveErrorsAndSteps() throws {
        let r = try XCTUnwrap(ArticulationLibrary.articulation(for: "r"))
        let s = try XCTUnwrap(ArticulationLibrary.articulation(for: "s"))
        XCTAssertFalse(r.errors.isEmpty)
        XCTAssertFalse(s.errors.isEmpty)
        XCTAssertGreaterThanOrEqual(r.steps.count, 3)
        XCTAssertGreaterThanOrEqual(s.steps.count, 3)
    }

    func testEveryGuideHasStepsAndErrors() {
        XCTAssertGreaterThanOrEqual(ArticulationLibrary.guides.count, 47)
        for guide in ArticulationLibrary.guides {
            XCTAssertGreaterThanOrEqual(guide.steps.count, 3, guide.id)
            XCTAssertFalse(guide.errors.isEmpty, guide.id)
        }
    }

    func testBlendComponents() {
        XCTAssertEqual(
            ArticulationLibrary.components(for: "str").map(\.symbol),
            ["s", "t", "r"]
        )
        XCTAssertEqual(
            ArticulationLibrary.components(for: "ŋθ").map(\.symbol),
            ["ŋ", "θ"]
        )
    }
}

final class LibraryTests: XCTestCase {
    func testLibraryLoads() throws {
        let data = try LibraryStore.load()
        XCTAssertEqual(data.library.categories.count, 3)
        XCTAssertGreaterThanOrEqual(data.library.categories.flatMap(\.tiles).count, 60)
        XCTAssertEqual(data.library.mixed.count, 4)
        XCTAssertGreaterThanOrEqual(data.minimalPairs?.pairs.count ?? 0, 30)
        XCTAssertTrue(data.library.categories.flatMap(\.tiles).allSatisfy { !$0.targets.isEmpty })
    }

    func testPatternListsCoverEveryTile() throws {
        let data = try LibraryStore.load()
        guard let patterns = data.patternLists else {
            throw XCTSkip("pattern lists not generated")
        }
        let tiles = data.library.categories.flatMap(\.tiles)
        XCTAssertEqual(patterns.lists.count, tiles.count)
        for tile in tiles {
            XCTAssertFalse((patterns.lists[tile.id] ?? []).isEmpty, tile.id)
        }
    }
}
