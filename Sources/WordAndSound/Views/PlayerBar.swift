import SwiftUI

struct PlayerBar: View {
    @ObservedObject var model: AppModel
    @State private var showRecorder = false

    var body: some View {
        Group {
            if let word = model.currentWord {
                content(word)
            } else {
                Text("Select a word to hear it.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 116)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Theme.panel)
        .sheet(isPresented: $showRecorder) {
            RecordView(model: model, word: model.currentWord ?? "")
        }
    }

    private func content(_ word: String) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 18) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(word)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .textSelection(.enabled)
                    HStack(spacing: 14) {
                        ForEach(model.ipaParts(for: word), id: \.label) { part in
                            HStack(spacing: 4) {
                                Text(part.label)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                IPAHighlighter.text(part.ipa, targets: model.currentTargets, kind: model.currentTile?.kind ?? "onset")
                                    .font(.system(size: 13, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                        if !model.targetDescription.isEmpty {
                            Text(model.targetDescription)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Theme.subtle))
                                .foregroundStyle(.secondary)
                        }
                        if model.ipaMode != .us, model.phoneticUK(for: word) == nil {
                            Text("UK unavailable")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Theme.subtle))
                                .foregroundStyle(.secondary)
                        }
                        if model.currentTile != nil {
                            Button {
                                model.showCoachForCurrent()
                            } label: {
                                Image(systemName: "mouth.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                            .help("How to make this sound")
                        }
                        Button {
                            model.toggleFavorite(word)
                        } label: {
                            Image(systemName: model.isFavorite(word) ? "star.fill" : "star")
                                .foregroundStyle(model.isFavorite(word) ? .yellow : .secondary)
                        }
                        .buttonStyle(.borderless)
                        .help(model.isFavorite(word) ? "Remove favorite" : "Mark as favorite")

                        Button {
                            model.toggleTrouble(word)
                        } label: {
                            Image(systemName: model.isTrouble(word) ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                                .foregroundStyle(model.isTrouble(word) ? .orange : .secondary)
                        }
                        .buttonStyle(.borderless)
                        .help(model.isTrouble(word) ? "Remove difficult mark" : "Mark as difficult")
                    }
                    HStack(spacing: 8) {
                        Text(model.progressText)
                            .font(.caption.monospacedDigit())
                        Text("·").foregroundStyle(.tertiary)
                        Text(model.currentListTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if let example = model.currentExample,
                           example != word {
                            Text("·").foregroundStyle(.tertiary)
                            Text("example: \(example) \(model.rowIPA(for: example))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    Button {
                        model.previousWord()
                    } label: {
                        Image(systemName: "backward.fill")
                    }
                    .help("Previous word (⌘←)")

                    Button {
                        model.toggleAutoplay()
                    } label: {
                        Image(systemName: model.isAutoplay ? "pause.fill" : "play.fill")
                            .font(.system(size: 17, weight: .bold))
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(Theme.accent))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .help(model.isAutoplay ? "Pause autoplay (Space)" : "Start autoplay (Space)")

                    Button {
                        model.nextWord()
                    } label: {
                        Image(systemName: "forward.fill")
                    }
                    .help("Next word (⌘→)")

                    Button {
                        model.replay()
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                    }
                    .help("Replay this word (⌘R)")

                    Button {
                        model.replaySlow()
                    } label: {
                        Image(systemName: "tortoise.fill")
                    }
                    .help("Replay slowly")

                    Button {
                        showRecorder = true
                    } label: {
                        Image(systemName: "mic.fill")
                    }
                    .help("Record yourself and compare")
                }
                .buttonStyle(.borderless)
                .font(.system(size: 14))

                Toggle(
                    "Auto Play",
                    isOn: Binding(
                        get: { model.isAutoplay },
                        set: { _ in model.toggleAutoplay() }
                    )
                )
                .toggleStyle(.switch)
                .controlSize(.small)
            }

            HStack(spacing: 12) {
                picker("Accent", selection: $model.accent) {
                    ForEach(Accent.allCases) { accent in
                        Text(accent.title).tag(accent)
                    }
                }
                .frame(width: 132)

                Picker("Repeat", selection: $model.repeatCount) {
                    ForEach(1...8, id: \.self) { count in
                        Text("\(count)×").tag(count)
                    }
                }
                .frame(width: 82)

                Picker("Delay", selection: $model.delay) {
                    ForEach(1...8, id: \.self) { seconds in
                        Text("\(seconds) s").tag(Double(seconds))
                    }
                }
                .frame(width: 78)

                Picker("IPA", selection: $model.ipaMode) {
                    ForEach(IPAMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .frame(width: 132)

                Menu("Jump to") {
                    ForEach(model.jumpTargets, id: \.self) { index in
                        Button("Word \(index + 1)") {
                            model.jump(to: index)
                        }
                    }
                }
                .frame(width: 92)

                if model.selectedMixedID == "review" {
                    Button("Got it") { model.reviewCurrent(correct: true) }
                        .controlSize(.small)
                    Button("Again") { model.reviewCurrent(correct: false) }
                        .controlSize(.small)
                }

                Spacer(minLength: 4)

                if let warning = model.voiceWarning {
                    Label(warning, systemImage: "exclamationmark.triangle")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                } else {
                    Text("Voice: \(model.voiceName(for: model.accent))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .pickerStyle(.menu)
            .controlSize(.small)
        }
    }

    private func picker<Selection: Hashable, Content: View>(
        _ title: String,
        selection: Binding<Selection>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Picker(title, selection: selection, content: content)
            .labelsHidden()
            .help(title)
    }
}
