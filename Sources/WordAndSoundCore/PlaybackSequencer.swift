import Foundation

public enum PlaybackAction: Equatable {
    case repeatWord
    case advance
    case finished
}

/// Pure repeat/advance logic, independent of speech and timers so it can be tested.
public struct PlaybackSequencer: Equatable {
    public private(set) var index: Int
    public private(set) var repeatIndex: Int
    public var repeatCount: Int
    public var wordCount: Int
    public var wraps: Bool

    public init(index: Int = 0, repeatCount: Int = 1, wordCount: Int, wraps: Bool = true) {
        self.wordCount = max(0, wordCount)
        self.repeatCount = max(1, repeatCount)
        self.wraps = wraps
        self.index = min(max(0, index), max(0, self.wordCount - 1))
        self.repeatIndex = 0
    }

    public mutating func reset(to newIndex: Int = 0) {
        index = min(max(0, newIndex), max(0, wordCount - 1))
        repeatIndex = 0
    }

    public mutating func setWordCount(_ count: Int) {
        wordCount = max(0, count)
        index = min(index, max(0, wordCount - 1))
        repeatIndex = 0
    }

    public mutating func completeUtterance() -> PlaybackAction {
        guard wordCount > 0 else { return .finished }
        if repeatIndex + 1 < max(1, repeatCount) {
            repeatIndex += 1
            return .repeatWord
        }
        repeatIndex = 0
        if index + 1 < wordCount {
            index += 1
            return .advance
        }
        if wraps {
            index = 0
            return .advance
        }
        return .finished
    }

    @discardableResult
    public mutating func next() -> Int {
        guard wordCount > 0 else { return 0 }
        index = (index + 1) % wordCount
        repeatIndex = 0
        return index
    }

    @discardableResult
    public mutating func previous() -> Int {
        guard wordCount > 0 else { return 0 }
        index = (index - 1 + wordCount) % wordCount
        repeatIndex = 0
        return index
    }
}
