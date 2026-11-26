import SwiftUI

struct HeaderView: View {
    @ObservedObject var model: AppModel
    @Binding var showCredits: Bool
    @Binding var showImporter: Bool
    @Binding var showPractice: Bool

    private var categoryBinding: Binding<String> {
        Binding(
            get: { model.selectedCategoryID },
            set: { model.selectCategory($0) }
        )
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.appInfo?.name ?? "Word & Sound")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                HStack(spacing: 5) {
                    Text(model.appInfo?.tagline ?? "English pronunciation drills")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("·").foregroundStyle(.tertiary)
                    Text(AppVersion.compact)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 12)

            Picker("Category", selection: categoryBinding) {
                Text("Starting").tag("starting")
                Text("Vowel").tag("vowel")
                Text("Ending").tag("ending")
                Text("Mixed").tag("mixed")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 430)

            Spacer(minLength: 12)

            Button {
                model.isSearchPresented = true
            } label: {
                Label("Search", systemImage: "magnifyingglass")
                    .labelStyle(.iconOnly)
            }
            .help("Search words, sounds and lists (⌘K)")

            Button {
                showPractice = true
            } label: {
                Label("Practice", systemImage: "target")
            }
            .help("Minimal-pair listening and quiz")

            Button {
                showImporter = true
            } label: {
                Label("Import", systemImage: "square.and.arrow.down")
                    .labelStyle(.iconOnly)
            }
            .help("Import a text or CSV word list")

            Button {
                showCredits = true
            } label: {
                Label("Credits", systemImage: "text.book.closed")
                    .labelStyle(.iconOnly)
            }
            .help("Data sources and licenses")

            SettingsLink {
                Label("Settings", systemImage: "gearshape")
                    .labelStyle(.iconOnly)
            }
            .help("Speech and playback settings")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}
