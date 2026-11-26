import Foundation

struct WordProgress: Codable {
    var word: String
    var listens: Int = 0
    var correct: Int = 0
    var wrong: Int = 0
    var step: Int = 0
    var due: Date?
    var favorite: Bool = false
    var trouble: Bool = false
    var lastSeen: Date?

    init(word: String) {
        self.word = word
    }
}
