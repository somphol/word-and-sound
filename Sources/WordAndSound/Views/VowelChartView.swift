import SwiftUI
import WordAndSoundCore

struct VowelChartView: View {
    let current: Articulation

    private var vowels: [Articulation] {
        ArticulationLibrary.guides.filter(\.isVowel)
    }

    private var contrasts: Set<String> {
        Set(current.contrasts)
    }

    var body: some View {
        Canvas { context, size in
            func p(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: x * size.width, y: y * size.height)
            }

            let card = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 12)
            context.fill(card, with: .color(Color(red: 0.09, green: 0.12, blue: 0.17)))
            context.stroke(card, with: .color(Color.white.opacity(0.08)), lineWidth: 1)

            var space = Path()
            space.move(to: p(0.18, 0.20))
            space.addLine(to: p(0.82, 0.20))
            space.addLine(to: p(0.82, 0.78))
            space.addLine(to: p(0.18, 0.78))
            space.closeSubpath()
            context.stroke(space, with: .color(Color.white.opacity(0.16)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

            for vowel in vowels {
                let point = p(0.18 + vowel.shape.back * 0.64, 0.78 - vowel.shape.body * 0.56)
                let isTarget = vowel.id == current.id
                let isContrast = contrasts.contains(vowel.id)
                let radius: CGFloat = isTarget ? 6 : (isContrast ? 4 : 2.5)
                let color: Color = isTarget
                    ? Theme.accent
                    : (isContrast ? .orange : Color.white.opacity(0.35))
                let dot = Path(ellipseIn: CGRect(
                    x: point.x - radius, y: point.y - radius,
                    width: radius * 2, height: radius * 2
                ))
                context.fill(dot, with: .color(color))
                if isTarget || isContrast {
                    context.draw(
                        Text(vowel.symbol)
                            .font(.system(size: isTarget ? 11 : 9, weight: isTarget ? .bold : .regular))
                            .foregroundColor(color),
                        at: CGPoint(x: point.x + 18, y: point.y)
                    )
                }
            }

            let label = Color.white.opacity(0.45)
            context.draw(Text("front").font(.system(size: 8)).foregroundColor(label), at: p(0.18, 0.84))
            context.draw(Text("back").font(.system(size: 8)).foregroundColor(label), at: p(0.82, 0.84))
            context.draw(Text("high").font(.system(size: 8)).foregroundColor(label), at: p(0.08, 0.20))
            context.draw(Text("low").font(.system(size: 8)).foregroundColor(label), at: p(0.08, 0.78))
        }
        .frame(height: 170)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Vowel space. Target \(current.symbol). Contrasts \(current.contrasts.joined(separator: ", "))."))
    }
}

struct LipCueView: View {
    let articulation: Articulation

    private enum LipPosition: String {
        case spread
        case neutral
        case rounded

        var title: String {
            switch self {
            case .spread: return "spread / smile"
            case .neutral: return "neutral"
            case .rounded: return "rounded / kiss"
            }
        }
    }

    private var target: LipPosition {
        if articulation.shape.lipRound > 0.25 { return .rounded }
        if articulation.shape.lipRound < -0.05 { return .spread }
        if articulation.isVowel,
           ["iː", "ɪ", "e", "ɛ", "æ", "ɛː", "eɪ", "aɪ", "ɪə", "eə", "aɪə"].contains(articulation.id) {
            return .spread
        }
        return .neutral
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Lips from the front")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Target: \(target.title)")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.accent)
            }

            HStack(spacing: 10) {
                option(.spread)
                option(.neutral)
                option(.rounded)
                Spacer(minLength: 0)
                if articulation.shape.jaw > 0.3 {
                    Label("jaw open", systemImage: "arrow.up.and.down")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text("Spread = smile; rounded = kiss. The target is highlighted.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(11)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.panel))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.subtle, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Lips from the front. Target: \(target.title). Spread means smile; rounded means kiss."))
    }

    private func option(_ position: LipPosition) -> some View {
        let selected = position == target
        return VStack(spacing: 4) {
            lipIcon(position)
                .frame(width: 70, height: 52)
            Text(position.title)
                .font(.caption2)
                .foregroundStyle(selected ? Theme.accent : .secondary)
                .multilineTextAlignment(.center)
                .frame(width: 88)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 3)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(selected ? Theme.accent.opacity(0.12) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(selected ? Theme.accent.opacity(0.55) : Color.clear, lineWidth: 1)
        )
    }

    private func lipIcon(_ position: LipPosition) -> some View {
        Canvas { context, size in
            func p(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: x * size.width, y: y * size.height)
            }

            let width: Double
            let height: Double
            let innerWidth: Double
            let innerHeight: Double
            switch position {
            case .spread:
                width = 0.86; height = 0.22; innerWidth = 0.58; innerHeight = 0.055
            case .neutral:
                width = 0.66; height = 0.32; innerWidth = 0.46; innerHeight = 0.10
            case .rounded:
                width = 0.44; height = 0.48; innerWidth = 0.28; innerHeight = 0.22
            }

            let center = p(0.5, 0.52)
            let outer = CGRect(
                x: center.x - width * size.width / 2,
                y: center.y - height * size.height / 2,
                width: width * size.width,
                height: height * size.height
            )
            let lip = Path(ellipseIn: outer)
            context.fill(lip, with: .color(Color(red: 0.80, green: 0.32, blue: 0.39)))
            context.stroke(lip, with: .color(Color(red: 1, green: 0.72, blue: 0.72).opacity(0.55)), lineWidth: 1)

            let inner = CGRect(
                x: center.x - innerWidth * size.width / 2,
                y: center.y - innerHeight * size.height / 2,
                width: innerWidth * size.width,
                height: innerHeight * size.height
            )
            let opening = Path(ellipseIn: inner)
            context.fill(opening, with: .color(Color(red: 0.20, green: 0.05, blue: 0.09)))
            context.stroke(opening, with: .color(Color.white.opacity(0.18)), lineWidth: 1)
        }
    }
}
