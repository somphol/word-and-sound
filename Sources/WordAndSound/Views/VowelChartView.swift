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

struct LipShapeView: View {
    let articulation: Articulation

    var body: some View {
        Canvas { context, size in
            func p(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: x * size.width, y: y * size.height)
            }

            let card = Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 10)
            context.fill(card, with: .color(Color(red: 0.09, green: 0.12, blue: 0.17)))
            context.stroke(card, with: .color(Color.white.opacity(0.08)), lineWidth: 1)

            let round = max(0, min(1, articulation.shape.lipRound))
            let jaw = max(0, min(1, articulation.shape.jaw))
            let width = 0.78 - 0.30 * round
            let height = 0.18 + 0.34 * round + jaw * 0.16
            let center = p(0.5, 0.52)

            let outer = CGRect(
                x: center.x - width * size.width / 2,
                y: center.y - height * size.height / 2,
                width: width * size.width,
                height: height * size.height
            )
            let lip = Path(ellipseIn: outer)
            context.fill(lip, with: .color(Color(red: 0.80, green: 0.32, blue: 0.39)))
            context.stroke(lip, with: .color(Color(red: 1, green: 0.70, blue: 0.70).opacity(0.5)), lineWidth: 1)

            let innerWidth = width * 0.52
            let innerHeight = 0.06 + 0.14 * round + jaw * 0.12
            let inner = CGRect(
                x: center.x - innerWidth * size.width / 2,
                y: center.y - innerHeight * size.height / 2,
                width: innerWidth * size.width,
                height: innerHeight * size.height
            )
            let opening = Path(ellipseIn: inner)
            context.fill(opening, with: .color(Color(red: 0.20, green: 0.05, blue: 0.09)))
            context.stroke(opening, with: .color(Color.white.opacity(0.18)), lineWidth: 1)

            let label = Color.white.opacity(0.45)
            context.draw(Text("front lips").font(.system(size: 8)).foregroundColor(label), at: p(0.5, 0.88))
            let lipLabel: String
            if round > 0.5 {
                lipLabel = "rounded"
            } else if round > 0.2 {
                lipLabel = "slightly rounded"
            } else if articulation.shape.lipRound < -0.05 {
                lipLabel = "spread"
            } else if articulation.isVowel, ["iː", "ɪ", "e", "ɛ", "æ", "ɛː"].contains(articulation.id) {
                lipLabel = "spread"
            } else {
                lipLabel = "neutral"
            }
            context.draw(
                Text(lipLabel)
                    .font(.system(size: 8))
                    .foregroundColor(label),
                at: p(0.5, 0.12)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Front lip view. \(articulation.anchorWord ?? articulation.symbol)."))
    }
}
