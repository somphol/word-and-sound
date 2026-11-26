import Foundation
import SwiftUI
import WordAndSoundCore

@main
struct WordAndSoundApp: App {
    @StateObject private var model: AppModel

    init() {
        if CommandLine.arguments.contains("--selftest") {
            exit(SelfTest.run() ? 0 : 1)
        }
        if let index = CommandLine.arguments.firstIndex(of: "--snapshot-search"),
           index + 1 < CommandLine.arguments.count {
            let model = AppModel()
            let query: String
            if let queryIndex = CommandLine.arguments.firstIndex(of: "--query"),
               queryIndex + 1 < CommandLine.arguments.count {
                query = CommandLine.arguments[queryIndex + 1]
            } else {
                query = "ship"
            }
            let ok = Snapshot.write(
                GlobalSearchView(model: model, initialQuery: query),
                to: CommandLine.arguments[index + 1],
                size: CGSize(width: 760, height: 580)
            )
            exit(ok ? 0 : 1)
        }
        if let index = CommandLine.arguments.firstIndex(of: "--snapshot-practice"),
           index + 1 < CommandLine.arguments.count {
            let model = AppModel()
            let ok = Snapshot.write(
                PracticeView(model: model),
                to: CommandLine.arguments[index + 1],
                size: CGSize(width: 820, height: 620)
            )
            exit(ok ? 0 : 1)
        }
        if let index = CommandLine.arguments.firstIndex(of: "--snapshot-record"),
           index + 1 < CommandLine.arguments.count {
            let model = AppModel()
            let word = model.currentWord ?? "think"
            let ok = Snapshot.write(
                RecordView(model: model, word: word),
                to: CommandLine.arguments[index + 1],
                size: CGSize(width: 460, height: 520)
            )
            exit(ok ? 0 : 1)
        }
        if let index = CommandLine.arguments.firstIndex(of: "--snapshot"),
           index + 1 < CommandLine.arguments.count {
            let model = AppModel()
            if let categoryIndex = CommandLine.arguments.firstIndex(of: "--category"),
               categoryIndex + 1 < CommandLine.arguments.count {
                model.selectCategory(CommandLine.arguments[categoryIndex + 1])
            }
            if let tileIndex = CommandLine.arguments.firstIndex(of: "--tile"),
               tileIndex + 1 < CommandLine.arguments.count,
               let tile = model.categories.flatMap(\.tiles).first(where: { $0.id == CommandLine.arguments[tileIndex + 1] }) {
                model.selectTile(tile)
            }
            let ok = Snapshot.write(model: model, to: CommandLine.arguments[index + 1])
            exit(ok ? 0 : 1)
        }
        _model = StateObject(wrappedValue: AppModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
        }
        .defaultSize(width: 1180, height: 780)
        .defaultPosition(.center)
        .commands {
            PlaybackCommands(model: model)
        }

        Settings {
            SettingsView(model: model)
        }
    }
}
