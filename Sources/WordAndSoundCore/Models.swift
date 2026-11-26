import Foundation

public struct AppInfo: Codable, Hashable {
    public let name: String
    public let tagline: String
    public let dataLicense: String
    public let codeLicense: String

    public init(name: String, tagline: String, dataLicense: String, codeLicense: String) {
        self.name = name
        self.tagline = tagline
        self.dataLicense = dataLicense
        self.codeLicense = codeLicense
    }
}

public struct SoundTile: Codable, Identifiable, Hashable {
    public let id: String
    public let label: String
    public let exampleWord: String
    public let listKey: String
    public let group: String
    public let kind: String
    public let targets: [String]

    public init(
        id: String,
        label: String,
        exampleWord: String,
        listKey: String,
        group: String,
        kind: String,
        targets: [String]
    ) {
        self.id = id
        self.label = label
        self.exampleWord = exampleWord
        self.listKey = listKey
        self.group = group
        self.kind = kind
        self.targets = targets
    }
}

public struct SoundCategory: Codable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let tiles: [SoundTile]

    public init(id: String, title: String, tiles: [SoundTile]) {
        self.id = id
        self.title = title
        self.tiles = tiles
    }
}

public struct MixedList: Codable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let source: String
    public let author: String
    public let license: String
    public let url: String

    public init(id: String, title: String, source: String, author: String, license: String, url: String) {
        self.id = id
        self.title = title
        self.source = source
        self.author = author
        self.license = license
        self.url = url
    }
}

public struct Library: Codable {
    public let app: AppInfo
    public let categories: [SoundCategory]
    public let mixed: [MixedList]
    public let lists: [String: [String]]

    public init(app: AppInfo, categories: [SoundCategory], mixed: [MixedList], lists: [String: [String]]) {
        self.app = app
        self.categories = categories
        self.mixed = mixed
        self.lists = lists
    }
}

public struct ProvenanceSource: Codable, Hashable {
    public let name: String
    public let url: String?
    public let commit: String?
    public let file: String?
    public let sha256: String?
    public let license: String
    public let note: String?

    public init(name: String, url: String?, commit: String?, file: String?, sha256: String?, license: String, note: String?) {
        self.name = name
        self.url = url
        self.commit = commit
        self.file = file
        self.sha256 = sha256
        self.license = license
        self.note = note
    }
}

public struct Provenance: Codable {
    public let generated: String
    public let dataLicense: String
    public let codeLicense: String
    public let sources: [ProvenanceSource]
}

public struct MinimalPair: Codable, Identifiable, Hashable {
    public let id: String
    public let a: String
    public let b: String
    public let focus: String

    public init(id: String, a: String, b: String, focus: String) {
        self.id = id
        self.a = a
        self.b = b
        self.focus = focus
    }
}

public struct MinimalPairBundle: Codable {
    public let source: String
    public let license: String
    public let pairs: [MinimalPair]

    public init(source: String, license: String, pairs: [MinimalPair]) {
        self.source = source
        self.license = license
        self.pairs = pairs
    }
}

public struct PatternListBundle: Codable {
    public let source: String
    public let license: String
    public let limit: Int
    public let lists: [String: [String]]

    public init(source: String, license: String, limit: Int, lists: [String: [String]]) {
        self.source = source
        self.license = license
        self.limit = limit
        self.lists = lists
    }
}

public struct LibraryData {
    public let library: Library
    public let phoneticsUS: [String: String]
    public let phoneticsUK: [String: String]
    public let provenance: Provenance
    public let patternLists: PatternListBundle?
    public let minimalPairs: MinimalPairBundle?

    public init(
        library: Library,
        phoneticsUS: [String: String],
        phoneticsUK: [String: String],
        provenance: Provenance,
        patternLists: PatternListBundle?,
        minimalPairs: MinimalPairBundle?
    ) {
        self.library = library
        self.phoneticsUS = phoneticsUS
        self.phoneticsUK = phoneticsUK
        self.provenance = provenance
        self.patternLists = patternLists
        self.minimalPairs = minimalPairs
    }

    public func phoneticUS(for word: String) -> String? {
        phoneticsUS[word.lowercased()]
    }

    public func phoneticUK(for word: String) -> String? {
        phoneticsUK[word.lowercased()]
    }
}

public struct ImportedList: Codable, Identifiable, Hashable {
    public var id: String
    public var title: String
    public var words: [String]
    public var source: String

    public init(id: String, title: String, words: [String], source: String) {
        self.id = id
        self.title = title
        self.words = words
        self.source = source
    }
}
