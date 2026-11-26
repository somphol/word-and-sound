import SwiftUI
import WordAndSoundCore

struct SoundPanel: View {
    @ObservedObject var model: AppModel

    private let columns = [GridItem(.adaptive(minimum: 82), spacing: 10)]

    private var sections: [(String, [SoundTile])] {
        guard let category = model.currentCategory else { return [] }
        switch category.id {
        case "starting":
            return [
                ("Single sounds", category.tiles.filter { $0.group == "single" }),
                ("Starting blends", category.tiles.filter { $0.group == "blend" }),
            ].filter { !$0.1.isEmpty }
        case "ending":
            return [
                ("Single endings", category.tiles.filter { $0.group == "single" }),
                ("Ending blends", category.tiles.filter { $0.group == "blend" }),
            ].filter { !$0.1.isEmpty }
        default:
            return [("Vowel sounds", category.tiles.filter { $0.group == "vowel" })]
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
            HStack(spacing: 14) {
                ForEach(Array(model.ipaParts(for: tile.exampleWord).enumerated()), id: \.offset) { _, part in
                    HStack(spacing: 4) {
                        Text(part.label)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        IPAHighlighter.text(part.ipa, targets: tile.targets, kind: tile.kind)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                Text(model.targetDescription)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.subtle))
                    .foregroundStyle(.secondary)
                if model.ipaMode != .us, model.phoneticUK(for: tile.exampleWord) == nil {
                    Text("UK unavailable")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.subtle))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Text(SoundTips.tip(for: tile))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                model.showCoach(for: tile)
            } label: {
                Label("How to make this sound", systemImage: "mouth.fill")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
            .help("Animated side view and step-by-step tongue and lip position")

            let progress = model.currentListProgress
            if progress.total > 0 {
                HStack(spacing: 8) {
                    ProgressView(value: Double(progress.practised), total: Double(progress.total))
                        .frame(width: 120)
                    Text("\(progress.practised) / \(progress.total) practised")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
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
