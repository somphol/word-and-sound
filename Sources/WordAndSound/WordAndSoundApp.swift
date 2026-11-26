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
