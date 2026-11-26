import Foundation
import WordAndSoundCore

struct WordRow: Identifiable {
    let index: Int
    let word: String
    var id: Int { index }
}

final class AppModel: ObservableObject {
    @Published private(set) var libraryData: LibraryData?
    @Published private(set) var loadError: String?
    @Published var selectedCategoryID = "starting"
    @Published var selectedTileID: String?
    @Published var selectedMixedID: String?
    @Published private(set) var listKey: String?
    @Published private(set) var words: [String] = []
    @Published private(set) var currentIndex = 0
    @Published var searchText = ""
    @Published private(set) var isAutoplay = false
    @Published private(set) var isSpeaking = false
    @Published private(set) var importedLists: [ImportedList] = []
    @Published var importMessage: String?

    @Published var accent: Accent = .us {
        didSet {
            defaults.set(accent.rawValue, forKey: Keys.accent)
            if isAutoplay, isSpeaking {
                cancelPending()
                speakCurrent()
            }
        }
    }
    @Published var repeatCount = 1 {
        didSet {
            defaults.set(repeatCount, forKey: Keys.repeatCount)
            sequencer?.repeatCount = max(1, repeatCount)
        }
    }
    @Published var delay: Double = 2 {
        didSet { defaults.set(delay, forKey: Keys.delay) }
    }
    @Published var rateMultiplier: Double = 1 {
        didSet { defaults.set(rateMultiplier, forKey: Keys.rate) }
    }
    @Published var pitchMultiplier: Double = 1 {
        didSet { defaults.set(pitchMultiplier, forKey: Keys.pitch) }
    }
    @Published var ipaMode: IPAMode = .both {
        didSet { defaults.set(ipaMode.rawValue, forKey: Keys.ipaMode) }
    }
    @Published var listSource: ListSource = .curated {
        didSet {
            defaults.set(listSource.rawValue, forKey: Keys.listSource)
            reloadForSourceChange()
        }
    }

    private let defaults = UserDefaults.standard
    private let speech = SpeechEngine()
    private var sequencer: PlaybackSequencer?
    private var pendingWork: DispatchWorkItem?
    private let banned: Set<String> = ["rape", "sex", "sexual"]

    init() {
        loadSettings()
        do {
            libraryData = try LibraryStore.load()
        } catch {
            loadError = error.localizedDescription
        }
        loadImported()
        if libraryData?.patternLists != nil, defaults.string(forKey: Keys.listSource) == nil {
            listSource = .built
        }
        speech.onFinish = { [weak self] in
            self?.handleUtteranceFinished()
        }
        restoreSelection()
    }

    // MARK: - Library

    var appInfo: AppInfo? { libraryData?.library.app }
    var categories: [SoundCategory] { libraryData?.library.categories ?? [] }
    var provenance: Provenance? { libraryData?.provenance }

    var mixedLists: [MixedList] {
        var lists = libraryData?.library.mixed ?? []
        lists += importedLists.map {
            MixedList(
                id: $0.id,
                title: $0.title,
                source: "Imported",
                author: "You",
                license: "Your own content",
                url: ""
            )
        }
        return lists
    }

    var currentCategory: SoundCategory? {
        categories.first { $0.id == selectedCategoryID }
    }

    var currentTile: SoundTile? {
        categories.flatMap(\.tiles).first { $0.id == selectedTileID }
    }

    var currentMixed: MixedList? {
        mixedLists.first { $0.id == selectedMixedID }
    }

    var currentWord: String? {
        guard words.indices.contains(currentIndex) else { return nil }
        return words[currentIndex]
    }

    var currentListTitle: String {
        if let mixed = currentMixed { return mixed.title }
        if let tile = currentTile {
            return "\(currentCategory?.title ?? "Sound") · \(tile.label)"
        }
        return "Word list"
    }

    var currentExample: String? { currentTile?.exampleWord }

    var patternInfo: PatternListBundle? { libraryData?.patternLists }

    var patternListCount: Int { libraryData?.patternLists?.lists.count ?? 0 }

    var progressText: String {
        guard !words.isEmpty else { return "" }
        return "\(currentIndex + 1) / \(words.count)"
    }

    var voiceWarning: String? {
        guard speech.hasVoice(for: accent) == false else { return nil }
        return "No \(accent.title) voice is installed"
    }

    var filteredRows: [WordRow] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return words.enumerated().map { WordRow(index: $0.offset, word: $0.element) }
        }
        return words.enumerated().compactMap { index, word in
            word.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) == nil
                ? nil
                : WordRow(index: index, word: word)
        }
    }

    func phoneticUS(for word: String) -> String? {
        libraryData?.phoneticUS(for: word)
    }

    func phoneticUK(for word: String) -> String? {
        libraryData?.phoneticUK(for: word)
    }

    func ipaLine(for word: String) -> String {
        var parts: [String] = []
        if ipaMode != .uk, let us = phoneticUS(for: word) {
            parts.append("US \(us)")
        }
        if ipaMode != .us, let uk = phoneticUK(for: word) {
            parts.append("UK \(uk)")
        }
        return parts.isEmpty ? "—" : parts.joined(separator: "   ")
    }

    func rowIPA(for word: String) -> String {
        switch ipaMode {
        case .us: return phoneticUS(for: word) ?? "—"
        case .uk: return phoneticUK(for: word) ?? "—"
        case .both:
            return phoneticUK(for: word) ?? phoneticUS(for: word) ?? "—"
        }
    }

    // MARK: - Selection

    private func restoreSelection() {
        guard let data = libraryData else { return }
        let categoryID = defaults.string(forKey: Keys.category) ?? data.library.categories.first?.id ?? "starting"
        if categoryID == "mixed" {
            selectedCategoryID = "mixed"
            if let saved = defaults.string(forKey: Keys.mixed),
               let list = mixedLists.first(where: { $0.id == saved }) {
                applyMixed(list, speak: false)
            } else if let first = mixedLists.first {
                applyMixed(first, speak: false)
            }
            return
        }
        guard let category = data.library.categories.first(where: { $0.id == categoryID })
                ?? data.library.categories.first,
              let tile = category.tiles.first(where: { $0.id == defaults.string(forKey: Keys.tile) })
                ?? category.tiles.first
        else { return }
        applyTile(tile, speak: false)
    }

    func selectCategory(_ id: String) {
        guard id != selectedCategoryID else { return }
        selectedCategoryID = id
        defaults.set(id, forKey: Keys.category)
        if id == "mixed" {
            selectedTileID = nil
            if let first = mixedLists.first {
                applyMixed(first, speak: false)
            } else {
                clearSelection()
            }
        } else if let category = categories.first(where: { $0.id == id }),
                  let tile = category.tiles.first {
            applyTile(tile, speak: false)
        }
    }

    func selectTile(_ tile: SoundTile) {
        guard tile.id != selectedTileID else { return }
        applyTile(tile, speak: false)
    }

    func selectMixed(_ list: MixedList) {
        applyMixed(list, speak: false)
    }

    private func applyTile(_ tile: SoundTile, speak: Bool) {
        let wasAutoplay = isAutoplay
        cancelPending()
        if let category = categories.first(where: { $0.tiles.contains(tile) }) {
            selectedCategoryID = category.id
            defaults.set(category.id, forKey: Keys.category)
        }
        selectedTileID = tile.id
        selectedMixedID = nil
        listKey = tile.listKey
        words = wordsForTile(tile)
        currentIndex = 0
        searchText = ""
        sequencer = PlaybackSequencer(index: 0, repeatCount: repeatCount, wordCount: words.count)
        defaults.set(tile.id, forKey: Keys.tile)
        if wasAutoplay || speak {
            speakCurrent()
        }
    }

    private func applyMixed(_ list: MixedList, speak: Bool) {
        let wasAutoplay = isAutoplay
        cancelPending()
        selectedCategoryID = "mixed"
        selectedMixedID = list.id
        selectedTileID = nil
        listKey = list.id
        words = wordsForList(list.id)
        currentIndex = 0
        searchText = ""
        sequencer = PlaybackSequencer(index: 0, repeatCount: repeatCount, wordCount: words.count)
        defaults.set("mixed", forKey: Keys.category)
        defaults.set(list.id, forKey: Keys.mixed)
        if wasAutoplay || speak {
            speakCurrent()
        }
    }

    private func wordsForList(_ id: String) -> [String] {
        if let imported = importedLists.first(where: { $0.id == id }) {
            return imported.words
        }
        return libraryData?.library.lists[id] ?? []
    }

    private func wordsForTile(_ tile: SoundTile) -> [String] {
        if listSource == .built,
           let built = libraryData?.patternLists?.lists[tile.id],
           !built.isEmpty {
            return built
        }
        return libraryData?.library.lists[tile.listKey] ?? []
    }

    private func reloadForSourceChange() {
        guard selectedCategoryID != "mixed", let tile = currentTile else { return }
        applyTile(tile, speak: false)
    }

    private func clearSelection() {
        cancelPending()
        selectedTileID = nil
        selectedMixedID = nil
        listKey = nil
        words = []
        currentIndex = 0
        sequencer = nil
    }

    // MARK: - Playback

    func selectWord(at index: Int) {
        guard words.indices.contains(index) else { return }
        cancelPending()
        currentIndex = index
        sequencer = PlaybackSequencer(index: index, repeatCount: repeatCount, wordCount: words.count)
        speakCurrent()
    }

    func toggleAutoplay() {
        if isAutoplay {
            stopAutoplay()
        } else {
            guard !words.isEmpty else { return }
            isAutoplay = true
            sequencer = PlaybackSequencer(index: currentIndex, repeatCount: repeatCount, wordCount: words.count)
            speakCurrent()
        }
    }

    func replay() {
        cancelPending()
        speakCurrent()
    }

    func nextWord() {
        guard !words.isEmpty else { return }
        cancelPending()
        var seq = sequencer ?? PlaybackSequencer(index: currentIndex, repeatCount: repeatCount, wordCount: words.count)
        seq.next()
        currentIndex = seq.index
        sequencer = seq
        skipBannedForward()
        speakCurrent()
    }

    func previousWord() {
        guard !words.isEmpty else { return }
        cancelPending()
        var seq = sequencer ?? PlaybackSequencer(index: currentIndex, repeatCount: repeatCount, wordCount: words.count)
        seq.previous()
        currentIndex = seq.index
        sequencer = seq
        skipBannedForward()
        speakCurrent()
    }

    func jump(to index: Int) {
        guard words.indices.contains(index) else { return }
        cancelPending()
        currentIndex = index
        sequencer = PlaybackSequencer(index: index, repeatCount: repeatCount, wordCount: words.count)
        speakCurrent()
    }

    var jumpTargets: [Int] {
        guard !words.isEmpty else { return [] }
        var targets = Array(stride(from: 0, to: words.count, by: 50))
        if targets.isEmpty { targets = [0] }
        return targets
    }

    private func speakCurrent() {
        guard let word = currentWord else {
            stopAutoplay()
            return
        }
        isSpeaking = true
        speech.speak(word, accent: accent, rate: rateMultiplier, pitch: pitchMultiplier)
    }

    private func handleUtteranceFinished() {
        isSpeaking = false
        guard isAutoplay, var seq = sequencer else { return }
        let action = seq.completeUtterance()
        sequencer = seq
        switch action {
        case .repeatWord:
            scheduleNext()
        case .advance:
            currentIndex = seq.index
            skipBannedForward()
            scheduleNext()
        case .finished:
            stopAutoplay()
        }
    }

    private func scheduleNext() {
        pendingWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.speakCurrent()
        }
        pendingWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + max(0.5, delay), execute: work)
    }

    private func skipBannedForward() {
        guard words.count > 1 else { return }
        var tries = 0
        while let word = currentWord,
              banned.contains(word.lowercased()),
              tries < words.count {
            currentIndex = (currentIndex + 1) % words.count
            tries += 1
        }
        if tries > 0 {
            sequencer?.reset(to: currentIndex)
        }
    }

    private func cancelPending() {
        pendingWork?.cancel()
        pendingWork = nil
        speech.stop()
        isSpeaking = false
    }

    func stopAutoplay() {
        isAutoplay = false
        cancelPending()
    }

    // MARK: - Import

    func importFile(_ url: URL) {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }
        let text = (try? String(contentsOf: url, encoding: .utf8))
            ?? (try? String(contentsOf: url, encoding: .isoLatin1))
            ?? ""
        let words = WordListParser.parse(text)
        guard !words.isEmpty else {
            importMessage = "No usable words were found in \(url.lastPathComponent)."
            return
        }
        let base = url.deletingPathExtension().lastPathComponent
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let list = ImportedList(
            id: "imported-\(UUID().uuidString.prefix(8))",
            title: base.isEmpty ? "Imported list" : base,
            words: words,
            source: url.lastPathComponent
        )
        importedLists.append(list)
        saveImported()
        importMessage = "Imported \(words.count) words from \(url.lastPathComponent)."
        if let mixed = mixedLists.first(where: { $0.id == list.id }) {
            applyMixed(mixed, speak: false)
        }
    }

    func removeImported(_ list: ImportedList) {
        if selectedMixedID == list.id {
            clearSelection()
        }
        importedLists.removeAll { $0.id == list.id }
        saveImported()
    }

    private var supportDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        let directory = base.appendingPathComponent("WordAndSound", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func loadImported() {
        let url = supportDirectory.appendingPathComponent("imported.json")
        guard let data = try? Data(contentsOf: url),
              let lists = try? JSONDecoder().decode([ImportedList].self, from: data)
        else { return }
        importedLists = lists
    }

    private func saveImported() {
        let url = supportDirectory.appendingPathComponent("imported.json")
        guard let data = try? JSONEncoder().encode(importedLists) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Settings

    private enum Keys {
        static let accent = "accent"
        static let repeatCount = "repeatCount"
        static let delay = "delay"
        static let rate = "rate"
        static let pitch = "pitch"
        static let ipaMode = "ipaMode"
        static let listSource = "listSource"
        static let category = "category"
        static let tile = "tile"
        static let mixed = "mixed"
    }

    private func loadSettings() {
        if let raw = defaults.string(forKey: Keys.accent), let value = Accent(rawValue: raw) {
            accent = value
        }
        let repeatValue = defaults.integer(forKey: Keys.repeatCount)
        if repeatValue > 0 { repeatCount = min(max(1, repeatValue), 8) }
        if defaults.object(forKey: Keys.delay) != nil {
            delay = min(max(1, defaults.double(forKey: Keys.delay)), 8)
        }
        if defaults.object(forKey: Keys.rate) != nil {
            rateMultiplier = min(max(0.2, defaults.double(forKey: Keys.rate)), 1.8)
        }
        if defaults.object(forKey: Keys.pitch) != nil {
            pitchMultiplier = min(max(0.5, defaults.double(forKey: Keys.pitch)), 1.8)
        }
        if let raw = defaults.string(forKey: Keys.ipaMode), let value = IPAMode(rawValue: raw) {
            ipaMode = value
        }
        if let raw = defaults.string(forKey: Keys.listSource), let value = ListSource(rawValue: raw) {
            listSource = value
        }
    }

    func resetSettings() {
        stopAutoplay()
        accent = .us
        repeatCount = 1
        delay = 2
        rateMultiplier = 1
        pitchMultiplier = 1
        ipaMode = .both
    }

    func voiceName(for accent: Accent) -> String {
        speech.voiceName(for: accent) ?? "Not installed"
    }
}
