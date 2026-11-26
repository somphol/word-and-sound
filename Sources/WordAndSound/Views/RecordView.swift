import SwiftUI

struct RecordView: View {
    @ObservedObject var model: AppModel
    let word: String
    @StateObject private var recorder = RecordController()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Record and compare")
                        .font(.title3.bold())
                    Text("Your recording stays on this Mac.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(word)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
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
            }

            HStack(spacing: 12) {
                Button {
                    if recorder.isRecording {
                        recorder.stop()
                    } else {
                        recorder.start()
                    }
                } label: {
                    Label(
                        recorder.isRecording ? "Stop" : "Record",
                        systemImage: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(recorder.isRecording ? .red : Theme.accent)

                if recorder.hasRecording {
                    Button {
                        recorder.play()
                    } label: {
                        Label("Play mine", systemImage: "play.circle")
                    }
                    Button(role: .destructive) {
                        recorder.delete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }

                Spacer()

                TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                    Text(String(format: "%.1f s", recorder.displayTime))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                Button {
                    model.playWord(word)
                } label: {
                    Label("Hear the model", systemImage: "speaker.wave.2.fill")
                }
                Button {
                    model.playWord(word, slow: true)
                } label: {
                    Label("Slow model", systemImage: "tortoise.fill")
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if let error = recorder.error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("No score is calculated. Listen for one feature at a time: the target sound, word stress, then the whole word.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .frame(width: 460)
        .onDisappear {
            recorder.cleanup()
        }
    }
}
