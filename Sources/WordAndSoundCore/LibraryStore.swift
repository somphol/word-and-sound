import Foundation

public enum LibraryStore {
    public enum LoadError: LocalizedError {
        case missingResource(String)
        case decode(String, Error)

        public var errorDescription: String? {
            switch self {
            case .missingResource(let name):
                return "Missing bundled resource: \(name)"
            case .decode(let name, let error):
                return "Could not decode \(name): \(error.localizedDescription)"
            }
        }
    }

    public static func load() throws -> LibraryData {
        let library: Library = try decode("library", "json")
        let us: [String: String] = try decode("phonetics_us", "json")
        let uk: [String: String] = try decode("phonetics_uk", "json")
        let provenance: Provenance = try decode("provenance", "json")
        let patterns: PatternListBundle? = try decodeOptional("pattern_lists", "json")
        let pairs: MinimalPairBundle? = try decodeOptional("minimal_pairs", "json")
        return LibraryData(
            library: library,
            phoneticsUS: us,
            phoneticsUK: uk,
            provenance: provenance,
            patternLists: patterns,
            minimalPairs: pairs
        )
    }

    public static func rawData(named name: String, extension ext: String) throws -> Data {
        guard let url = resourceURL(name, ext) else {
            throw LoadError.missingResource("\(name).\(ext)")
        }
        return try Data(contentsOf: url)
    }

    public static func resourceURL(_ name: String, _ ext: String) -> URL? {
        let bundle = Bundle.module
        if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Resources") {
            return url
        }
        if let url = bundle.url(forResource: name, withExtension: ext) {
            return url
        }
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return url
        }
        return nil
    }

    private static func decode<T: Decodable>(_ name: String, _ ext: String) throws -> T {
        guard let url = resourceURL(name, ext) else {
            throw LoadError.missingResource("\(name).\(ext)")
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw LoadError.decode("\(name).\(ext)", error)
        }
    }

    private static func decodeOptional<T: Decodable>(_ name: String, _ ext: String) throws -> T? {
        guard let url = resourceURL(name, ext) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw LoadError.decode("\(name).\(ext)", error)
        }
    }
}
