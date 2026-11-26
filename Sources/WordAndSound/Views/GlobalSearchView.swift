import SwiftUI
import WordAndSoundCore

struct GlobalSearchView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var query: String
    @State private var filter: SearchFilter = .all
    @FocusState private var focused: Bool

    init(model: AppModel, initialQuery: String = "") {
        self.model = model
        _query = State(initialValue: initialQuery)
    }

    private var results: SearchResults {
        model.search(query, filter: filter)
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            content
        }
        .frame(width: 760, height: 580)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            DispatchQueue.main.async { focused = true }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search words, sounds, lists or IPA", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .focused($focused)
                .onSubmit(openFirst)

            Picker("Filter", selection: $filter) {
                ForEach(SearchFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 310)

            Button("Close") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(18)
    }

    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if results.isEmpty {
                    ContentUnavailableView(
                        "No matches",
                        systemImage: "magnifyingglass",
                        description: Text("Try a word, a sound such as θ, a list name, or an IPA symbol.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 380)
                } else {
                    if !results.tiles.isEmpty {
                        sectionHeader("Sounds")
                        ForEach(results.tiles) { tile in
                            tileRow(tile)
                        }
                    }
                    if !results.lists.isEmpty {
                        sectionHeader("Lists")
                        ForEach(results.lists) { list in
                            listRow(list)
                        }
                    }
                    if !results.words.isEmpty {
                        sectionHeader("Words · \(results.words.count)")
                        ForEach(results.words) { hit in
                            wordRow(hit)
                        }
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 4)
    }

    private func tileRow(_ tile: SoundTile) -> some View {
        let category = model.categories.first { $0.tiles.contains(tile) }
        return Button {
            model.openTile(tile)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text(tile.label)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .frame(width: 54, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(tile.exampleWord)
                        .font(.system(size: 14, weight: .medium))
                    Text("\(category?.title ?? "Sound") · \(tile.group)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(model.listSource.title)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func listRow(_ list: MixedList) -> some View {
        Button {
            model.openMixed(list)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: list.id == "review" ? "clock.arrow.circlepath" : "list.bullet.rectangle")
                    .frame(width: 24)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(list.title)
                        .font(.system(size: 14, weight: .medium))
                    Text(list.source)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text("\(model.wordCount(for: list)) words")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func wordRow(_ hit: WordHit) -> some View {
        Button {
            model.openWord(hit)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text(hit.word)
                    .font(.system(size: 15, weight: .medium))
                    .frame(minWidth: 120, alignment: .leading)
                Text(model.rowIPA(for: hit.word))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                if model.isFavorite(hit.word) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)
                }
                if model.isTrouble(hit.word) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
                Text(hit.listTitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openFirst() {
        if let tile = results.tiles.first {
            model.openTile(tile)
        } else if let list = results.lists.first {
            model.openMixed(list)
        } else if let word = results.words.first {
            model.openWord(word)
        } else {
            return
        }
        dismiss()
    }
}
