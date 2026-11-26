import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @ObservedObject var model: AppModel
    @State private var showCredits = false
    @State private var showImporter = false
    @State private var showPractice = false

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(
                model: model,
                showCredits: $showCredits,
                showImporter: $showImporter,
                showPractice: $showPractice
            )
            Divider()

            HSplitView {
                Group {
                    if model.selectedCategoryID == "mixed" {
                        MixedPanel(model: model, showImporter: $showImporter)
                    } else {
                        SoundPanel(model: model)
                    }
                }
                .frame(minWidth: 330, idealWidth: 380, maxWidth: 470)

                WordPanel(model: model)
                    .frame(minWidth: 520, idealWidth: 720, maxWidth: .infinity)
            }

            Divider()
            PlayerBar(model: model)
        }
        .frame(minWidth: 1000, minHeight: 660)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            DispatchQueue.main.async {
                centerWindowIfOffscreen()
            }
        }
        .sheet(isPresented: $showCredits) {
            CreditsView(model: model)
        }
        .sheet(isPresented: $showPractice) {
            PracticeView(model: model)
        }
        .sheet(isPresented: $model.isSearchPresented) {
            GlobalSearchView(model: model)
        }
        .sheet(isPresented: $model.isCoachPresented) {
            if let tile = model.coachTile {
                ArticulationCoachView(model: model, tile: tile)
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.plainText, .commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    model.importFile(url)
                }
            case .failure(let error):
                model.importMessage = error.localizedDescription
            }
        }
        .alert(
            "Word list import",
            isPresented: Binding(
                get: { model.importMessage != nil },
                set: { if !$0 { model.importMessage = nil } }
            )
        ) {
            Button("OK") { model.importMessage = nil }
        } message: {
            Text(model.importMessage ?? "")
        }
    }

    private func centerWindowIfOffscreen() {
        guard let window = NSApplication.shared.windows.first(where: { $0.isVisible && $0.canBecomeMain }) else {
            return
        }
        window.title = "Word & Sound \(AppVersion.short)"
        let frame = window.frame
        let visibleArea = NSScreen.screens.reduce(CGFloat.zero) { total, screen in
            let intersection = screen.visibleFrame.intersection(frame)
            return total + intersection.width * intersection.height
        }
        let ratio = frame.width * frame.height > 0 ? visibleArea / (frame.width * frame.height) : 0
        if ratio < 0.5 {
            window.center()
        }
    }
}
