import Foundation

enum Accent: String, CaseIterable, Identifiable {
    case us = "en-US"
    case uk = "en-GB"
    case au = "en-AU"
    case india = "en-IN"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .us: return "American"
        case .uk: return "British"
        case .au: return "Australian"
        case .india: return "Indian"
        }
    }

    var short: String {
        switch self {
        case .us: return "US"
        case .uk: return "UK"
        case .au: return "AU"
        case .india: return "IN"
        }
    }
}

enum IPAMode: String, CaseIterable, Identifiable {
    case both
    case us
    case uk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .both: return "US and UK"
        case .us: return "US only"
        case .uk: return "UK only"
        }
    }
}

enum ListSource: String, CaseIterable, Identifiable {
    case curated
    case built

    var id: String { rawValue }

    var title: String {
        switch self {
        case .curated: return "Curated"
        case .built: return "Built"
        }
    }
}
