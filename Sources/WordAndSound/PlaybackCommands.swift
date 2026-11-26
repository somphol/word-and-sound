import SwiftUI

struct PlaybackCommands: Commands {
    @ObservedObject var model: AppModel

    var body: some Commands {
        CommandMenu("Playback") {
            Button("Search…") {
                model.isSearchPresented = true
            }
            .keyboardShortcut("k", modifiers: .command)

            Divider()

            Button("Play / Pause") {
                model.toggleAutoplay()
            }
            .keyboardShortcut(.space, modifiers: [])

            Button("Replay Word") {
                model.replay()
            }
            .keyboardShortcut("r", modifiers: .command)

            Divider()

            Button("Next Word") {
                model.nextWord()
            }
            .keyboardShortcut(.rightArrow, modifiers: .command)

            Button("Previous Word") {
                model.previousWord()
            }
            .keyboardShortcut(.leftArrow, modifiers: .command)
        }
    }
}
