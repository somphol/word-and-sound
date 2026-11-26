import SwiftUI
import WordAndSoundCore

struct ArticulationCoachView: View {
    @ObservedObject var model: AppModel
    let tile: SoundTile
    @Environment(\.dismiss) private var dismiss
    @State private var selectedComponent = 0
    @State private var showRecorder = false

    private var components: [Articulation] {
        ArticulationLibrary.components(for: tile.label)
    }

    private var current: Articulation? {
        guard !components.isEmpty else { return nil }
        return components[min(selectedComponent, components.count - 1)]
    }

    private var displayName: String {
        if components.count > 1 {
            return "Blend: " + components.map(\.symbol).joined(separator: " + ")
        }
        return current?.name.capitalized ?? "Sound guide"
    }

    private var targetDescription: String {
        switch tile.kind {
        case "onset", "blend":
            return "initial /\(tile.label)/"
        case "coda", "codaBlend":
            return "final /\(tile.label)/"
        default:
            return tile.label.contains("/") ? "vowel \(tile.label)" : "vowel /\(tile.label)/"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if let current {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        componentStrip
                        HStack(alignment: .top, spacing: 22) {
                            leftColumn(current)
                                .frame(minWidth: 470, maxWidth: 520)
                            rightColumn(current)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(22)
                }
            } else {
                ContentUnavailableView(
                    "No articulation guide",
                    systemImage: "mouth",
                    description: Text("This tile does not have a guide yet.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 1000, height: 720)
        .sheet(isPresented: $showRecorder) {
            RecordView(model: model, word: tile.exampleWord)
        }
        .onChange(of: tile.id) { _, _ in selectedComponent = 0 }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(tile.label)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                    Text(displayName)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    badge(targetDescription)
                    if components.count > 1 {
                        badge("Blend")
                    } else if let current {
                        if current.isVowel {
                            badge("Vowel")
                        } else {
                            badge(current.place.capitalized)
                            badge(current.manner.capitalized)
                        }
                        badge(current.voiced ? "Voice on" : "Voice off")
                        if let length = current.lengthLabel {
                            badge(length.capitalized)
                        }
                    }
                }
            }
            Spacer()
            Button("Close") { dismiss() }
                .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
    }

    private var componentStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            if components.count > 1 {
                Text("Blend: \(components.map(\.symbol).joined(separator: " + ")) — say each position without adding a vowel between.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                            Button {
                                selectedComponent = index
                            } label: {
                                VStack(spacing: 4) {
                                    MouthDiagramView(articulation: component, compact: true)
                                        .frame(width: 138, height: 92)
                                    HStack(spacing: 5) {
                                        Text(component.symbol)
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                        Text(component.place)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(index == selectedComponent ? Theme.accent.opacity(0.16) : Theme.panel)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(index == selectedComponent ? Theme.accent.opacity(0.7) : Theme.subtle, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            if index < components.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var sampleWords: [String] {
        guard model.currentTile?.id == tile.id else { return [] }
        return Array(model.words.prefix(6))
    }

    private var blendGuidance: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Say the whole blend")
                .font(.headline)
            ForEach(components) { component in
                HStack(alignment: .top, spacing: 8) {
                    Text(component.symbol)
                        .font(.callout.bold())
                        .frame(width: 28, alignment: .leading)
                    Text(component.steps.first ?? "Hold this position.")
                        .font(.callout)
                }
            }
            Text("Do not insert a vowel between the consonants.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 8) {
                Text("extra vowel")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                    .frame(width: 88, alignment: .leading)
                Text("Keep moving; do not relax between sounds.")
                    .font(.caption)
            }
            HStack(alignment: .top, spacing: 8) {
                Text("dropped sound")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                    .frame(width: 88, alignment: .leading)
                Text("Hold each position briefly, then blend faster.")
                    .font(.caption)
            }
        }
    }

    private func leftColumn(_ articulation: Articulation) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            MouthDiagramView(articulation: articulation)
                .frame(height: 300)

            LipCueView(articulation: articulation)

            HStack(spacing: 12) {
                legend(color: Color(red: 0.36, green: 0.95, blue: 0.56), text: "target zone")
                legend(color: Color(red: 0.35, green: 0.78, blue: 1.0), text: "airflow")
                legend(color: Color(red: 1.0, green: 0.68, blue: 0.25), text: "voice")
                legendDashed(text: "rest")
                Spacer()
                Text("Side view")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text("Solid tongue = target; dashed outline = rest.")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            HStack(spacing: 10) {
                Button {
                    model.playWord(tile.exampleWord)
                } label: {
                    Label("Hear example", systemImage: "speaker.wave.2.fill")
                }
                Button {
                    model.playWord(tile.exampleWord, slow: true)
                } label: {
                    Label("Slow", systemImage: "tortoise.fill")
                }
                Button {
                    showRecorder = true
                } label: {
                    Label("Record", systemImage: "mic.fill")
                }
                Spacer()
                IPAHighlighter.text(model.rowIPA(for: tile.exampleWord), targets: tile.targets, kind: tile.kind)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Try this")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(tile.exampleWord)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("Lead with the target position, then say the word. Repeat slowly, then at normal speed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.panel))

            if !sampleWords.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Hear it in words")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(Array(sampleWords.prefix(4)), id: \.self) { word in
                        HStack(spacing: 8) {
                            Text(word)
                                .font(.callout)
                            IPAHighlighter.text(model.rowIPA(for: word), targets: tile.targets, kind: tile.kind)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                model.playWord(word)
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                            }
                            .buttonStyle(.borderless)
                            .help("Hear \(word)")
                        }
                    }
                    Text("Each word comes from this tile’s current list.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.panel))
            }
        }
    }

    private func rightColumn(_ articulation: Articulation) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            if articulation.isVowel {
                VowelChartView(current: articulation)
                Divider()
            }

            if components.count > 1 {
                blendGuidance
                Divider()
            }

            if articulation.isVowel {
                vowelGuidance(articulation)
                Divider()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("How to make it")
                    .font(.headline)
                ForEach(Array(articulation.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.bold().monospacedDigit())
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Theme.accent.opacity(0.18)))
                            .foregroundStyle(Theme.accent)
                        Text(step)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if articulation.glide != nil {
                    Text("This is a glide: start at the first tongue position and move smoothly to the second.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !articulation.errors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("If it sounds like…")
                        .font(.headline)
                    ForEach(articulation.errors, id: \.self) { issue in
                        HStack(alignment: .top, spacing: 8) {
                            Text(issue.heardAs)
                                .font(.callout.bold())
                                .foregroundStyle(.orange)
                                .frame(width: 88, alignment: .leading)
                            Text(issue.fix)
                                .font(.callout)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            if !articulation.anchors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Physical anchors")
                        .font(.headline)
                    ForEach(articulation.anchors, id: \.self) { anchor in
                        Label(anchor, systemImage: "hand.point.right.fill")
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Practice ladder")
                    .font(.headline)
                Text("1. Hold the position.  2. Say the example.  3. Say it slowly.  4. Record and compare.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Button("Hear example") { model.playWord(tile.exampleWord) }
                    Button("Slow") { model.playWord(tile.exampleWord, slow: true) }
                    Button("Record myself") { showRecorder = true }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func legendDashed(text: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white.opacity(0.35))
                .frame(width: 12, height: 1.5)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func legend(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func vowelGuidance(_ articulation: Articulation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Anchor and contrasts")
                .font(.headline)
            Text("Front vowels are left, back vowels right; high vowels are at the top.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                if let anchor = articulation.anchorWord {
                    Button {
                        model.playWord(anchor)
                    } label: {
                        Text("\(articulation.symbol) · \(anchor)")
                    }
                    .buttonStyle(.borderedProminent)
                }
                ForEach(articulation.contrasts, id: \.self) { contrastID in
                    if let contrast = ArticulationLibrary.articulation(for: contrastID),
                       let anchor = contrast.anchorWord {
                        Button {
                            model.playWord(anchor)
                        } label: {
                            Text("\(contrast.symbol) · \(anchor)")
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .controlSize(.small)

            if let length = articulation.lengthLabel {
                HStack(spacing: 8) {
                    Text("Length")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.subtle)
                            .frame(width: 118, height: 6)
                        Capsule()
                            .fill(Theme.accent)
                            .frame(width: length == "short" ? 42 : 118, height: 6)
                    }
                    Text(length)
                        .font(.caption.bold())
                        .foregroundStyle(Theme.accent)
                }
                Text(length == "glide" ? "Move smoothly from the first position to the second." : "Short vowels are quick; long vowels are held.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(Theme.subtle))
            .foregroundStyle(.secondary)
    }
}
