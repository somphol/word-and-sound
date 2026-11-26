import SwiftUI

struct WordPanel: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if model.words.isEmpty {
                ContentUnavailableView(
                    "Choose a word list",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Select a sound or a mixed list to start practising.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                list
            }
        }
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(model.currentListTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                Text("\(model.words.count) words")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if !model.progressText.isEmpty {
                    Text(model.progressText)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search this list", text: $model.searchText)
                    .textFieldStyle(.plain)
                if !model.searchText.isEmpty {
                    Button {
                        model.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Theme.subtle)
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.filteredRows) { row in
                        wordRow(row)
                            .id(row.index)
                    }
                }
                .padding(.vertical, 4)
            }
            .onAppear {
                proxy.scrollTo(model.currentIndex, anchor: .center)
            }
            .onChange(of: model.currentIndex) { _, newValue in
                guard model.searchText.isEmpty else { return }
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private func wordRow(_ row: WordRow) -> some View {
        let isCurrent = row.index == model.currentIndex
        return Button {
            model.selectWord(at: row.index)
        } label: {
            HStack(spacing: 12) {
                Text("\(row.index + 1)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .frame(width: 42, alignment: .trailing)
                Text(row.word)
                    .font(.system(size: 15, weight: isCurrent ? .semibold : .regular))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(model.rowIPA(for: row.word))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Image(systemName: isCurrent ? "speaker.wave.2.fill" : "speaker.wave.2")
                    .font(.system(size: 11))
                    .foregroundStyle(isCurrent ? Theme.accent : Color.secondary.opacity(0.45))
                    .frame(width: 16)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(isCurrent ? Theme.accent.opacity(0.12) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
