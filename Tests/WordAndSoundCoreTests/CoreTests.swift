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

final class LibraryTests: XCTestCase {
    func testLibraryLoads() throws {
        let data = try LibraryStore.load()
        XCTAssertEqual(data.library.categories.count, 3)
        XCTAssertGreaterThanOrEqual(data.library.categories.flatMap(\.tiles).count, 60)
        XCTAssertEqual(data.library.mixed.count, 4)
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
