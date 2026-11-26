import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section("Speech") {
                Picker("Accent", selection: $model.accent) {
                    ForEach(Accent.allCases) { accent in
                        Text("\(accent.title) (\(accent.short))").tag(accent)
                    }
                }
                LabeledContent("Voice", value: model.voiceName(for: model.accent))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Speech rate")
                        Spacer()
                        Text(String(format: "%.1f×", model.rateMultiplier))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $model.rateMultiplier, in: 0.2...1.8, step: 0.1)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Pitch")
                        Spacer()
                        Text(String(format: "%.1f×", model.pitchMultiplier))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $model.pitchMultiplier, in: 0.5...1.8, step: 0.1)
                }

                Button("Replay current word") {
                    model.replay()
                }
                .disabled(model.currentWord == nil)

                if let warning = model.voiceWarning {
                    Label(warning, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.caption)
                }
            }

            Section("Playback") {
                Toggle(
                    "Auto Play",
                    isOn: Binding(
                        get: { model.isAutoplay },
                        set: { _ in model.toggleAutoplay() }
                    )
                )

                Stepper("Repeat each word: \(model.repeatCount)×", value: $model.repeatCount, in: 1...8)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Delay between words")
                        Spacer()
                        Text(String(format: "%.0f s", model.delay))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $model.delay, in: 1...8, step: 1)
                }

                Picker("IPA display", selection: $model.ipaMode) {
                    ForEach(IPAMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }

                if model.patternListCount > 0 {
                    Picker("Word lists", selection: $model.listSource) {
                        Text("Curated").tag(ListSource.curated)
                        Text("Built from IPA patterns").tag(ListSource.built)
                    }
                }
            }

            Section("Data") {
                Button("Reset speech and playback settings") {
                    model.resetSettings()
                }
                Text("Imported lists are stored in Application Support and are not uploaded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 480, height: 500)
    }
}
