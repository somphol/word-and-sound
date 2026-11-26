import SwiftUI
import WordAndSoundCore

struct MixedPanel: View {
    @ObservedObject var model: AppModel
    @Binding var showImporter: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Word lists")
                        .font(.title2.bold())
                    Text("\(model.mixedLists.count) lists")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showImporter = true
                    } label: {
                        Label("Import", systemImage: "plus")
                    }
                    .controlSize(.small)
                }

                ForEach(model.mixedLists) { list in
                    listCard(list)
                }

                Text("Imported lists and their words stay on this Mac. You are responsible for their content.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding(18)
        }
    }

    private func listCard(_ list: MixedList) -> some View {
        let selected = model.selectedMixedID == list.id
        let count = model.wordCount(for: list)
        return Button {
            model.selectMixed(list)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(list.title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    Text("\(count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(list.source)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(list.license)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.subtle))
                    if list.source == "Imported" {
                        Text("local")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selected ? Theme.accent.opacity(0.16) : Theme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(selected ? Theme.accent.opacity(0.7) : Theme.subtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if list.source == "Imported",
               let imported = model.importedLists.first(where: { $0.id == list.id }) {
                Button("Remove list", role: .destructive) {
                    model.removeImported(imported)
                }
            }
        }
    }
}
