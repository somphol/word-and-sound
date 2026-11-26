import SwiftUI
import WordAndSoundCore

struct PracticeView: View {
    @ObservedObject var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var pairID = ""
    @State private var mode: Mode = .listen
    @State private var questionSide: Side?
    @State private var feedback: Bool?
    @State private var correctCount = 0
    @State private var attempts = 0

    private enum Mode: String, CaseIterable, Identifiable {
        case listen = "Listen"
        case quiz = "Quiz"
        var id: String { rawValue }
    }

    private enum Side: String {
        case a = "A"
        case b = "B"
    }

    private var pair: MinimalPair? {
        model.minimalPairs.first { $0.id == pairID } ?? model.minimalPairs.first
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if let pair {
                ScrollView {
                    VStack(spacing: 18) {
                        Text(pair.focus)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.subtle))

                        HStack(spacing: 16) {
                            pairCard(pair, side: .a, word: pair.a)
                            pairCard(pair, side: .b, word: pair.b)
                        }

                        if mode == .listen {
                            listenPanel(pair)
                        } else {
                            quizPanel(pair)
                        }

                        Text("Tip: listen once, then say it before pressing play again. IPA is a reference, not a score.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(24)
                }
            } else {
                ContentUnavailableView(
                    "No minimal pairs",
                    systemImage: "rectangle.2.swap",
                    description: Text("The pair bundle could not be loaded.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 820, height: 620)
        .onAppear {
            if pairID.isEmpty { pairID = model.minimalPairs.first?.id ?? "" }
        }
        .onChange(of: pairID) { _, _ in resetQuestion() }
        .onChange(of: mode) { _, _ in resetQuestion() }
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Minimal pairs")
                    .font(.title2.bold())
                Text("Hear the difference, then choose")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("Pair", selection: $pairID) {
                ForEach(model.minimalPairs) { pair in
                    Text("\(pair.a) / \(pair.b)").tag(pair.id)
                }
            }
            .labelsHidden()
            .frame(width: 210)

            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 150)

            Button("Close") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(20)
    }

    private func pairCard(_ pair: MinimalPair, side: Side, word: String) -> some View {
        VStack(spacing: 8) {
            Text(side.rawValue)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(word)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            ForEach(model.ipaParts(for: word), id: \.label) { part in
                HStack(spacing: 4) {
                    Text(part.label)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text(part.ipa)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            Button {
                model.playWord(word)
            } label: {
                Label("Play \(side.rawValue)", systemImage: "speaker.wave.2.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity, minHeight: 190)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Theme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(cardBorder(side), lineWidth: 2)
        )
    }

    private func cardBorder(_ side: Side) -> Color {
        guard mode == .quiz, let feedback else { return Theme.subtle }
        if feedback && questionSide == side { return .green.opacity(0.7) }
        if !feedback && questionSide == side { return .red.opacity(0.7) }
        return Theme.subtle
    }

    private func listenPanel(_ pair: MinimalPair) -> some View {
        VStack(spacing: 8) {
            Text("Listen to both words, then repeat them aloud.")
                .font(.callout)
            HStack(spacing: 10) {
                Button("Play A") { model.playWord(pair.a) }
                Button("Play B") { model.playWord(pair.b) }
                Button("Play slow A") { model.playWord(pair.a, slow: true) }
                Button("Play slow B") { model.playWord(pair.b, slow: true) }
            }
            .buttonStyle(.borderless)
            .font(.callout)
        }
    }

    private func quizPanel(_ pair: MinimalPair) -> some View {
        VStack(spacing: 12) {
            Button {
                playRandom(pair)
            } label: {
                Label("Play one word", systemImage: "play.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)

            if questionSide != nil {
                Text("Which word did you hear?")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button("A · \(pair.a)") { answer(.a, pair: pair) }
                        .disabled(feedback != nil)
                    Button("B · \(pair.b)") { answer(.b, pair: pair) }
                        .disabled(feedback != nil)
                }
                .buttonStyle(.bordered)
            }

            if let feedback {
                Label(
                    feedback ? "Correct" : "Try again",
                    systemImage: feedback ? "checkmark.circle.fill" : "xmark.circle.fill"
                )
                .foregroundStyle(feedback ? .green : .orange)
                .font(.callout.bold())
            }

            HStack(spacing: 16) {
                Text("Score: \(correctCount) / \(attempts)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Button("Next pair") { nextPair() }
                    .buttonStyle(.borderless)
            }
        }
    }

    private func playRandom(_ pair: MinimalPair) {
        let side: Side = Bool.random() ? .a : .b
        questionSide = side
        feedback = nil
        model.playWord(side == .a ? pair.a : pair.b)
    }

    private func answer(_ side: Side, pair: MinimalPair) {
        guard let questionSide else { return }
        let correct = side == questionSide
        feedback = correct
        attempts += 1
        if correct { correctCount += 1 }
        let heard = questionSide == .a ? pair.a : pair.b
        model.recordQuiz(word: heard, correct: correct)
    }

    private func nextPair() {
        guard !model.minimalPairs.isEmpty else { return }
        let index = model.minimalPairs.firstIndex { $0.id == pairID } ?? 0
        pairID = model.minimalPairs[(index + 1) % model.minimalPairs.count].id
    }

    private func resetQuestion() {
        questionSide = nil
        feedback = nil
    }
}
