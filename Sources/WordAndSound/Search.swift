import Foundation
import WordAndSoundCore

enum SearchFilter: String, CaseIterable, Identifiable {
    case all
    case favorites
    case trouble
    case due

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .favorites: return "Favorites"
        case .trouble: return "Trouble"
        case .due: return "Due"
        }
    }
}

struct WordHit: Identifiable, Hashable {
    let id: String
    let word: String
    let listID: String
    let tileID: String?
    let listTitle: String
    let index: Int
}

struct SearchResults {
    var tiles: [SoundTile] = []
    var lists: [MixedList] = []
    var words: [WordHit] = []

    var isEmpty: Bool { tiles.isEmpty && lists.isEmpty && words.isEmpty }
}
