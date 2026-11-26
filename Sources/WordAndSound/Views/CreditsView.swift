import SwiftUI
import WordAndSoundCore

struct CreditsView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Credits and licenses")
                        .font(.title2.bold())
                    Text("Code MIT · bundled data CC BY-SA 4.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("The app code is MIT licensed. The bundled word lists and pronunciations are CC BY-SA 4.0. Changes: lists were cleaned, deduplicated, filtered to single words, and IPA was subset to the bundled vocabulary.")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    ForEach(model.provenance?.sources ?? [], id: \.name) { source in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(source.name)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(source.license)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Theme.subtle))
                                Spacer()
                            }
                            if let url = source.url, let link = URL(string: url) {
                                Link(url, destination: link)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            if let note = source.note {
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let commit = source.commit {
                                Text("commit \(commit.prefix(12))")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.tertiary)
                            }
                            if let hash = source.sha256 {
                                Text("sha256 \(hash.prefix(16))…")
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Your authored lists")
                            .font(.system(size: 14, weight: .semibold))
                        Text("The 60 phoneme lists are supplied by the app author and licensed CC BY-SA 4.0. They were cleaned and deduplicated.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let patterns = model.patternInfo {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Pattern-built lists")
                                .font(.system(size: 14, weight: .semibold))
                            Text(patterns.source)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(patterns.lists.count) lists · up to \(patterns.limit) words per list · \(patterns.license)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Imported lists")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Content you import stays on this Mac and is your responsibility. It is not covered by the app's data license.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let generated = model.provenance?.generated {
                        Text("Data bundle generated \(generated).")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 640, height: 640)
    }
}
