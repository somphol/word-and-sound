import SwiftUI
import WordAndSoundCore

struct SoundPanel: View {
    @ObservedObject var model: AppModel

    private let columns = [GridItem(.adaptive(minimum: 82), spacing: 10)]

    private let startingBlends: Set<String> = [
        "startingFEW", "startingNIOR", "startingTHROUGH",
        "startingTR", "startingBL", "startingSTR",
    ]
    private let endingBlends: Set<String> = ["endingKT", "endingST", "endingLM"]

    private var sections: [(String, [SoundTile])] {
        guard let category = model.currentCategory else { return [] }
        switch category.id {
        case "starting":
            return [
                ("Single sounds", category.tiles.filter { !startingBlends.contains($0.id) }),
                ("Starting blends", category.tiles.filter { startingBlends.contains($0.id) }),
            ].filter { !$0.1.isEmpty }
        case "ending":
            return [
                ("Single endings", category.tiles.filter { !endingBlends.contains($0.id) }),
                ("Ending blends", category.tiles.filter { endingBlends.contains($0.id) }),
            ].filter { !$0.1.isEmpty }
        default:
            return [("Vowel sounds", category.tiles)]
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let category = model.currentCategory {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(category.title)
                            .font(.title2.bold())
                        Text("\(category.tiles.count) sounds")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if model.patternListCount > 0 {
                            Picker("List source", selection: $model.listSource) {
                                Text("Curated").tag(ListSource.curated)
                                Text("Built").tag(ListSource.built)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .frame(width: 156)
                            .help("Curated: your original lists. Built: words selected from open IPA patterns.")
                        }
                    }

                    if model.listSource == .built, let info = model.patternInfo {
                        Text("Built from IPA patterns · \(info.limit) words per sound max · \(info.license)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    if let tile = model.currentTile,
                       category.tiles.contains(where: { $0.id == tile.id }) {
                        exampleCard(tile)
                    }

                    ForEach(sections, id: \.0) { title, tiles in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(title)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: columns, spacing: 10) {
                                ForEach(tiles) { tile in
                                    tileButton(tile)
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "No sound selected",
                        systemImage: "waveform",
                        description: Text("Pick a sound to load its word list.")
                    )
                }
            }
            .padding(18)
        }
    }

    private func count(for tile: SoundTile) -> Int {
        if model.listSource == .built,
           let built = model.patternInfo?.lists[tile.id],
           !built.isEmpty {
            return built.count
        }
        return model.libraryData?.library.lists[tile.listKey]?.count ?? 0
    }

    private func tileButton(_ tile: SoundTile) -> some View {
        let selected = model.selectedTileID == tile.id
        return Button {
            model.selectTile(tile)
        } label: {
            VStack(spacing: 2) {
                Text(tile.label)
                    .font(.system(size: tile.label.count > 2 ? 17 : 22, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(tile.exampleWord)
                    .font(.caption2)
                    .lineLimit(1)
                    .opacity(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(selected ? Theme.tileSelected : Theme.tile)
            )
            .foregroundStyle(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color.white.opacity(selected ? 0.8 : 0), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .help("\(tile.label) — \(tile.exampleWord) · \(count(for: tile)) words")
    }

    private func exampleCard(_ tile: SoundTile) -> some View {
        let wordCount = count(for: tile)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(tile.exampleWord)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                Text("/ \(tile.label) /")
                    .font(.system(size: 15, design: .monospaced))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(wordCount) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(model.ipaLine(for: tile.exampleWord))
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.subtle, lineWidth: 1)
        )
    }
}
